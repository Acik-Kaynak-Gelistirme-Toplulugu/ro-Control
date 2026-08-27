#include "fancontroller.h"
#include "system/commandrunner.h"

#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QRegularExpression>
#include <algorithm>
#include <cmath>

namespace {

QString fanSysfsRoot() {
  const QString overridePath =
      qEnvironmentVariable("RO_CONTROL_FAN_SYSFS_ROOT").trimmed();
  return overridePath.isEmpty() ? QStringLiteral("/sys/class/hwmon")
                                : overridePath;
}

bool writeTextFile(const QString &path, const QString &content) {
  QFile file(path);
  if (!file.open(QIODevice::WriteOnly | QIODevice::Text)) {
    return false;
  }
  return file.write(content.toUtf8()) != -1;
}

QString readTextFile(const QString &path) {
  QFile file(path);
  if (!file.open(QIODevice::ReadOnly | QIODevice::Text)) {
    return {};
  }
  return QString::fromUtf8(file.readAll()).trimmed();
}

bool isGpuHwmon(const QString &name) {
  const QString lower = name.trimmed().toLower();
  return lower.contains(QStringLiteral("nvidia")) ||
         lower.contains(QStringLiteral("nouveau")) ||
         lower.contains(QStringLiteral("amdgpu")) ||
         lower.contains(QStringLiteral("radeon")) ||
         lower.contains(QStringLiteral("gpu"));
}

} // namespace

FanController::FanController(QObject *parent) : QObject(parent) {
  m_customCurve = defaultCustomCurve();
  loadSettings();

  m_timer.setInterval(2000);
  m_timer.setTimerType(Qt::CoarseTimer);
  connect(&m_timer, &QTimer::timeout, this, &FanController::refresh);

  detectHardwareCapabilities();
  refresh();
  start();
}

FanController::~FanController() {
  // Safe restoration: if manual or custom mode was applied, restore auto on exit
  if (!m_lastAppliedModeWasAuto && m_controlSupported) {
    executeSetFanSpeed(0, true);
  }
}

bool FanController::supported() const { return m_supported; }

bool FanController::controlSupported() const { return m_controlSupported; }

FanController::ControlCapability FanController::capability() const {
  return m_capability;
}

QString FanController::capabilityString() const {
  return capabilityToString(m_capability);
}

QString FanController::hardwareType() const { return m_hardwareType; }

bool FanController::running() const { return m_timer.isActive(); }

int FanController::fanCount() const { return m_fanCount; }

int FanController::currentFanSpeedPercent() const {
  return m_currentFanSpeedPercent;
}

int FanController::currentRpm() const { return m_currentRpm; }

int FanController::targetFanSpeedPercent() const {
  return m_targetFanSpeedPercent;
}

int FanController::manualFanSpeedPercent() const {
  return m_manualFanSpeedPercent;
}

QString FanController::fanMode() const { return modeToString(m_mode); }

FanController::FanMode FanController::modeEnum() const { return m_mode; }

QStringList FanController::availableModes() const {
  return {QStringLiteral("auto"),    QStringLiteral("silent"),
          QStringLiteral("balanced"), QStringLiteral("performance"),
          QStringLiteral("manual"),  QStringLiteral("custom")};
}

bool FanController::safetyOverrideActive() const {
  return m_safetyOverrideActive;
}

int FanController::thermalThresholdC() const { return m_thermalThresholdC; }

QString FanController::statusMessage() const { return m_statusMessage; }

QVariantList FanController::customCurvePointsVariant() const {
  QVariantList list;
  list.reserve(m_customCurve.size());
  for (const auto &pt : m_customCurve) {
    QVariantMap map;
    map.insert(QStringLiteral("temp"), pt.temperatureC);
    map.insert(QStringLiteral("speed"), pt.fanSpeedPercent);
    list.append(map);
  }
  return list;
}

QVector<FanCurvePoint> FanController::customCurvePoints() const {
  return m_customCurve;
}

int FanController::gpuTemperatureC() const { return m_gpuTemperatureC; }

QString FanController::modeToString(FanMode mode) {
  switch (mode) {
  case FanMode::Silent:
    return QStringLiteral("silent");
  case FanMode::Balanced:
    return QStringLiteral("balanced");
  case FanMode::Performance:
    return QStringLiteral("performance");
  case FanMode::Manual:
    return QStringLiteral("manual");
  case FanMode::Custom:
    return QStringLiteral("custom");
  case FanMode::Auto:
  default:
    return QStringLiteral("auto");
  }
}

FanController::FanMode FanController::stringToMode(const QString &modeStr) {
  const QString lower = modeStr.trimmed().toLower();
  if (lower == QStringLiteral("silent"))
    return FanMode::Silent;
  if (lower == QStringLiteral("balanced"))
    return FanMode::Balanced;
  if (lower == QStringLiteral("performance"))
    return FanMode::Performance;
  if (lower == QStringLiteral("manual"))
    return FanMode::Manual;
  if (lower == QStringLiteral("custom"))
    return FanMode::Custom;
  return FanMode::Auto;
}

QString FanController::capabilityToString(ControlCapability cap) {
  switch (cap) {
  case ControlCapability::Controllable:
    return QStringLiteral("controllable");
  case ControlCapability::TelemetryOnly:
    return QStringLiteral("telemetry_only");
  case ControlCapability::PermissionDenied:
    return QStringLiteral("permission_denied");
  case ControlCapability::Unavailable:
    return QStringLiteral("unavailable");
  case ControlCapability::InitializationFailed:
    return QStringLiteral("initialization_failed");
  case ControlCapability::Unsupported:
  default:
    return QStringLiteral("unsupported");
  }
}

int FanController::calculateCurveFanSpeed(const QVector<FanCurvePoint> &curve,
                                         int temperatureC) {
  if (curve.isEmpty()) {
    return 50;
  }
  if (curve.size() == 1) {
    return std::clamp(curve.first().fanSpeedPercent, 0, 100);
  }

  QVector<FanCurvePoint> sortedCurve = curve;
  std::sort(sortedCurve.begin(), sortedCurve.end(),
            [](const FanCurvePoint &a, const FanCurvePoint &b) {
              if (a.temperatureC == b.temperatureC) {
                return a.fanSpeedPercent < b.fanSpeedPercent;
              }
              return a.temperatureC < b.temperatureC;
            });

  // Deduplicate points with identical temperature by taking the maximum speed
  QVector<FanCurvePoint> cleanCurve;
  cleanCurve.reserve(sortedCurve.size());
  for (const auto &pt : sortedCurve) {
    if (!cleanCurve.isEmpty() &&
        cleanCurve.last().temperatureC == pt.temperatureC) {
      cleanCurve.last().fanSpeedPercent =
          std::max(cleanCurve.last().fanSpeedPercent, pt.fanSpeedPercent);
    } else {
      cleanCurve.append(pt);
    }
  }

  if (cleanCurve.size() == 1) {
    return std::clamp(cleanCurve.first().fanSpeedPercent, 0, 100);
  }

  if (temperatureC <= cleanCurve.first().temperatureC) {
    return std::clamp(cleanCurve.first().fanSpeedPercent, 0, 100);
  }

  if (temperatureC >= cleanCurve.last().temperatureC) {
    return std::clamp(cleanCurve.last().fanSpeedPercent, 0, 100);
  }

  for (qsizetype i = 0; i < cleanCurve.size() - 1; ++i) {
    const auto &p1 = cleanCurve.at(i);
    const auto &p2 = cleanCurve.at(i + 1);

    if (temperatureC >= p1.temperatureC && temperatureC <= p2.temperatureC) {
      if (p2.temperatureC == p1.temperatureC) {
        return std::clamp(std::max(p1.fanSpeedPercent, p2.fanSpeedPercent), 0,
                          100);
      }

      const double ratio =
          static_cast<double>(temperatureC - p1.temperatureC) /
          static_cast<double>(p2.temperatureC - p1.temperatureC);
      const double speed =
          static_cast<double>(p1.fanSpeedPercent) +
          ratio * static_cast<double>(p2.fanSpeedPercent - p1.fanSpeedPercent);
      return std::clamp(static_cast<int>(std::round(speed)), 0, 100);
    }
  }

  return 50;
}

QVector<FanCurvePoint> FanController::defaultSilentCurve() {
  return {{40, 0}, {55, 30}, {68, 50}, {78, 75}, {85, 100}};
}

QVector<FanCurvePoint> FanController::defaultBalancedCurve() {
  return {{40, 30}, {55, 45}, {68, 65}, {78, 85}, {85, 100}};
}

QVector<FanCurvePoint> FanController::defaultPerformanceCurve() {
  return {{35, 45}, {50, 65}, {65, 80}, {75, 90}, {82, 100}};
}

QVector<FanCurvePoint> FanController::defaultCustomCurve() {
  return {{40, 30}, {55, 50}, {70, 70}, {85, 100}};
}

void FanController::start() {
  if (!m_timer.isActive()) {
    m_timer.start();
    emit runningChanged();
  }
}

void FanController::stop() {
  if (m_timer.isActive()) {
    m_timer.stop();
    emit runningChanged();
  }
}

void FanController::refresh() {
  detectHardwareCapabilities();
  readCurrentFanTelemetry();
  evaluateAndApplyFanSpeed(false);
}

void FanController::updateTemperature(int tempC) {
  if (tempC >= 0 && m_gpuTemperatureC != tempC) {
    m_gpuTemperatureC = tempC;
    emit gpuTemperatureCChanged();
    evaluateAndApplyFanSpeed(false);
  }
}

void FanController::setFanMode(const QString &mode) {
  const FanMode newMode = stringToMode(mode);
  if (m_mode == newMode) {
    return;
  }

  m_mode = newMode;
  saveSettings();
  emit fanModeChanged();
  evaluateAndApplyFanSpeed(true);
}

void FanController::setManualFanSpeedPercent(int percent) {
  const int clamped = std::clamp(percent, 0, 100);
  if (m_manualFanSpeedPercent == clamped) {
    return;
  }

  m_manualFanSpeedPercent = clamped;
  saveSettings();
  emit manualFanSpeedPercentChanged();

  if (m_mode == FanMode::Manual) {
    evaluateAndApplyFanSpeed(true);
  }
}

bool FanController::setCustomCurvePoint(int index, int tempC,
                                        int speedPercent) {
  if (index < 0 || index >= m_customCurve.size()) {
    return false;
  }

  const int clampedTemp = std::clamp(tempC, 20, 100);
  const int clampedSpeed = std::clamp(speedPercent, 0, 100);

  m_customCurve[index].temperatureC = clampedTemp;
  m_customCurve[index].fanSpeedPercent = clampedSpeed;

  std::sort(m_customCurve.begin(), m_customCurve.end(),
            [](const FanCurvePoint &a, const FanCurvePoint &b) {
              if (a.temperatureC == b.temperatureC) {
                return a.fanSpeedPercent < b.fanSpeedPercent;
              }
              return a.temperatureC < b.temperatureC;
            });

  saveSettings();
  emit customCurvePointsChanged();

  if (m_mode == FanMode::Custom) {
    evaluateAndApplyFanSpeed(true);
  }

  return true;
}

void FanController::resetCustomCurve() {
  m_customCurve = defaultCustomCurve();
  saveSettings();
  emit customCurvePointsChanged();

  if (m_mode == FanMode::Custom) {
    evaluateAndApplyFanSpeed(true);
  }
}

void FanController::resetToAuto() { setFanMode(QStringLiteral("auto")); }

void FanController::loadSettings() {
  QSettings settings;
  settings.beginGroup(QStringLiteral("FanControl"));

  const QString savedMode =
      settings.value(QStringLiteral("mode"), QStringLiteral("auto")).toString();
  m_mode = stringToMode(savedMode);

  m_manualFanSpeedPercent =
      settings.value(QStringLiteral("manualSpeed"), 50).toInt();
  m_manualFanSpeedPercent = std::clamp(m_manualFanSpeedPercent, 0, 100);

  const int count = settings.value(QStringLiteral("curveCount"), 0).toInt();
  if (count >= 2 && count <= 8) {
    QVector<FanCurvePoint> loadedCurve;
    for (int i = 0; i < count; ++i) {
      const int t = settings
                        .value(QStringLiteral("curveTemp_%1").arg(i), 40 + i * 15)
                        .toInt();
      const int s = settings
                        .value(QStringLiteral("curveSpeed_%1").arg(i), 30 + i * 20)
                        .toInt();
      loadedCurve.append({std::clamp(t, 20, 100), std::clamp(s, 0, 100)});
    }
    if (!loadedCurve.isEmpty()) {
      std::sort(loadedCurve.begin(), loadedCurve.end(),
                [](const FanCurvePoint &a, const FanCurvePoint &b) {
                  if (a.temperatureC == b.temperatureC) {
                    return a.fanSpeedPercent < b.fanSpeedPercent;
                  }
                  return a.temperatureC < b.temperatureC;
                });
      m_customCurve = loadedCurve;
    }
  } else {
    m_customCurve = defaultCustomCurve();
  }

  settings.endGroup();
}

void FanController::saveSettings() {
  QSettings settings;
  settings.beginGroup(QStringLiteral("FanControl"));

  settings.setValue(QStringLiteral("mode"), modeToString(m_mode));
  settings.setValue(QStringLiteral("manualSpeed"), m_manualFanSpeedPercent);
  settings.setValue(QStringLiteral("curveCount"), m_customCurve.size());

  for (qsizetype i = 0; i < m_customCurve.size(); ++i) {
    settings.setValue(QStringLiteral("curveTemp_%1").arg(i),
                      m_customCurve.at(i).temperatureC);
    settings.setValue(QStringLiteral("curveSpeed_%1").arg(i),
                      m_customCurve.at(i).fanSpeedPercent);
  }

  settings.endGroup();
}

void FanController::detectHardwareCapabilities() {
  const QString mockCap =
      qEnvironmentVariable("RO_CONTROL_MOCK_FAN_CAPABILITY").trimmed().toLower();
  if (!mockCap.isEmpty()) {
    if (mockCap == QStringLiteral("controllable")) {
      setSupported(true);
      setControlSupported(true);
      setCapability(ControlCapability::Controllable);
      setHardwareType(QStringLiteral("NVIDIA (NV-CONTROL)"));
      return;
    }
    if (mockCap == QStringLiteral("telemetry_only")) {
      setSupported(true);
      setControlSupported(false);
      setCapability(ControlCapability::TelemetryOnly);
      setHardwareType(QStringLiteral("NVIDIA (Telemetry Only)"));
      return;
    }
    if (mockCap == QStringLiteral("permission_denied")) {
      setSupported(true);
      setControlSupported(false);
      setCapability(ControlCapability::PermissionDenied);
      setHardwareType(QStringLiteral("Linux HWMON (sysfs)"));
      return;
    }
    if (mockCap == QStringLiteral("unsupported")) {
      setSupported(false);
      setControlSupported(false);
      setCapability(ControlCapability::Unsupported);
      setHardwareType(QStringLiteral("None"));
      return;
    }
  }

  // 1. Check NVIDIA settings tool
  const QString nvidiaSettingsProg =
      CommandRunner::resolveProgramPath(QStringLiteral("nvidia-settings"));
  if (!nvidiaSettingsProg.isEmpty()) {
    setSupported(true);
    setControlSupported(true);
    setCapability(ControlCapability::Controllable);
    setHardwareType(QStringLiteral("NVIDIA (NV-CONTROL)"));
    return;
  }

  // 2. Check Sysfs HWMON for GPU fan PWM controls
  m_verifiedHwmonPwmPath.clear();
  m_verifiedHwmonPwmEnablePath.clear();

  const QFileInfoList hwmonEntries =
      QDir(fanSysfsRoot())
          .entryInfoList({QStringLiteral("hwmon*")},
                         QDir::Dirs | QDir::NoDotAndDotDot, QDir::Name);

  bool foundTelemetry = false;
  bool foundPwm = false;
  bool pwmWritable = false;

  for (const QFileInfo &entry : hwmonEntries) {
    const QString basePath = entry.absoluteFilePath();
    const QString chipName =
        readTextFile(basePath + QStringLiteral("/name"));
    const bool isGpu = isGpuHwmon(chipName);

    // Check fan RPM inputs
    const QFileInfoList fanInputs =
        QDir(basePath).entryInfoList({QStringLiteral("fan*_input")},
                                     QDir::Files, QDir::Name);
    if (!fanInputs.isEmpty()) {
      foundTelemetry = true;
    }

    // Check PWM controls on GPU devices or designated hwmon
    const QString pwmPath = basePath + QStringLiteral("/pwm1");
    const QString pwmEnablePath = basePath + QStringLiteral("/pwm1_enable");

    if (QFile::exists(pwmPath) && (isGpu || hwmonEntries.size() == 1)) {
      foundPwm = true;
      QFileInfo pwmInfo(pwmPath);
      if (pwmInfo.isWritable()) {
        pwmWritable = true;
        m_verifiedHwmonPwmPath = pwmPath;
        m_verifiedHwmonPwmEnablePath = pwmEnablePath;
        break;
      }
    }
  }

  if (pwmWritable) {
    setSupported(true);
    setControlSupported(true);
    setCapability(ControlCapability::Controllable);
    setHardwareType(QStringLiteral("Linux HWMON (sysfs)"));
    return;
  }

  if (foundPwm) {
    setSupported(true);
    setControlSupported(false);
    setCapability(ControlCapability::PermissionDenied);
    setHardwareType(QStringLiteral("Linux HWMON (sysfs)"));
    return;
  }

  if (foundTelemetry) {
    setSupported(true);
    setControlSupported(false);
    setCapability(ControlCapability::TelemetryOnly);
    setHardwareType(QStringLiteral("Linux HWMON (Read-Only)"));
    return;
  }

  setSupported(false);
  setControlSupported(false);
  setCapability(ControlCapability::Unsupported);
  setHardwareType(QStringLiteral("None"));
}

void FanController::readCurrentFanTelemetry() {
  CommandRunner runner;
  CommandRunner::RunOptions options;
  options.timeoutMs = 1200;

  // 1. Try nvidia-smi query for fan.speed, temperature, and thermal limit
  const auto smiResult = runner.run(
      QStringLiteral("nvidia-smi"),
      {QStringLiteral("--query-gpu=fan.speed,temperature.gpu,temperature.gpu.tlimit"),
       QStringLiteral("--format=csv,noheader,nounits")},
      options);

  if (smiResult.success()) {
    const QString line =
        smiResult.stdout.split('\n', Qt::SkipEmptyParts).value(0);
    const QStringList parts = line.split(',', Qt::KeepEmptyParts);
    if (parts.size() >= 1) {
      bool ok = false;
      const int speed = parts.at(0).trimmed().toInt(&ok);
      if (ok && speed >= 0) {
        if (m_currentFanSpeedPercent != speed) {
          m_currentFanSpeedPercent = speed;
          emit currentFanSpeedPercentChanged();
        }
        setSupported(true);
      }
    }
    if (parts.size() >= 2) {
      bool ok = false;
      const int temp = parts.at(1).trimmed().toInt(&ok);
      if (ok && temp > 0 && m_gpuTemperatureC != temp) {
        m_gpuTemperatureC = temp;
        emit gpuTemperatureCChanged();
      }
    }
    if (parts.size() >= 3) {
      bool ok = false;
      const int tlimit = parts.at(2).trimmed().toInt(&ok);
      if (ok && tlimit >= 60 && tlimit <= 110 && m_thermalThresholdC != tlimit) {
        m_thermalThresholdC = tlimit;
        emit thermalThresholdCChanged();
      }
    }
  }

  // 2. Try sysfs hwmon fan input fallback
  const QFileInfoList hwmonEntries =
      QDir(fanSysfsRoot())
          .entryInfoList({QStringLiteral("hwmon*")},
                         QDir::Dirs | QDir::NoDotAndDotDot, QDir::Name);

  for (const QFileInfo &entry : hwmonEntries) {
    const QString path = entry.absoluteFilePath();
    const QString fanInputPath = path + QStringLiteral("/fan1_input");
    if (QFile::exists(fanInputPath)) {
      bool ok = false;
      const int rpm = readTextFile(fanInputPath).toInt(&ok);
      if (ok && rpm >= 0) {
        if (m_currentRpm != rpm) {
          m_currentRpm = rpm;
          emit currentRpmChanged();
        }
        setSupported(true);
      }
    }

    const QString pwmPath = path + QStringLiteral("/pwm1");
    if (QFile::exists(pwmPath) && m_currentFanSpeedPercent == 0) {
      bool ok = false;
      const int rawPwm = readTextFile(pwmPath).toInt(&ok);
      if (ok && rawPwm >= 0) {
        const int pct =
            std::clamp(static_cast<int>((rawPwm * 100) / 255), 0, 100);
        if (m_currentFanSpeedPercent != pct) {
          m_currentFanSpeedPercent = pct;
          emit currentFanSpeedPercentChanged();
        }
        setSupported(true);
      }
    }
  }
}

void FanController::evaluateAndApplyFanSpeed(bool force) {
  // Thermal safety watchdog model with hysteresis margin
  if (m_gpuTemperatureC >= m_thermalThresholdC) {
    if (!m_safetyOverrideActive) {
      m_safetyOverrideActive = true;
      emit safetyOverrideActiveChanged();
    }
  } else if (m_gpuTemperatureC <= (m_thermalThresholdC - m_thermalRecoveryMarginC) &&
             m_safetyOverrideActive) {
    m_safetyOverrideActive = false;
    emit safetyOverrideActiveChanged();
  }

  int calculatedSpeed = 0;
  bool isAuto = false;

  if (m_safetyOverrideActive) {
    calculatedSpeed = 100;
    setStatusMessage(
        tr("Safety Override Active: GPU is hot (%1°C >= %2°C). Fan forced to 100%.")
            .arg(m_gpuTemperatureC)
            .arg(m_thermalThresholdC));
  } else {
    switch (m_mode) {
    case FanMode::Auto:
      isAuto = true;
      calculatedSpeed = 0;
      setStatusMessage(tr("Automatic Mode: Managed by VBIOS and driver."));
      break;
    case FanMode::Silent:
      calculatedSpeed =
          calculateCurveFanSpeed(defaultSilentCurve(), m_gpuTemperatureC);
      setStatusMessage(tr("Silent Profile Active (%1% @ %2°C).")
                           .arg(calculatedSpeed)
                           .arg(m_gpuTemperatureC));
      break;
    case FanMode::Balanced:
      calculatedSpeed =
          calculateCurveFanSpeed(defaultBalancedCurve(), m_gpuTemperatureC);
      setStatusMessage(tr("Balanced Optimization Active (%1% @ %2°C).")
                           .arg(calculatedSpeed)
                           .arg(m_gpuTemperatureC));
      break;
    case FanMode::Performance:
      calculatedSpeed =
          calculateCurveFanSpeed(defaultPerformanceCurve(), m_gpuTemperatureC);
      setStatusMessage(tr("Performance Profile Active (%1% @ %2°C).")
                           .arg(calculatedSpeed)
                           .arg(m_gpuTemperatureC));
      break;
    case FanMode::Manual:
      calculatedSpeed = m_manualFanSpeedPercent;
      setStatusMessage(
          tr("Manual Fan Speed Locked at %1%.").arg(calculatedSpeed));
      break;
    case FanMode::Custom:
      calculatedSpeed =
          calculateCurveFanSpeed(m_customCurve, m_gpuTemperatureC);
      setStatusMessage(tr("Custom Curve Active (%1% @ %2°C).")
                           .arg(calculatedSpeed)
                           .arg(m_gpuTemperatureC));
      break;
    }

    // Directional Hysteresis:
    // When temperature rises, increase fan speed immediately.
    // When temperature falls, prevent fan hunting if temperature hasn't dropped
    // by at least m_hysteresisTempC.
    if (!isAuto && !force && m_lastEvaluatedTempC > 0 &&
        m_gpuTemperatureC < m_lastEvaluatedTempC) {
      if (m_gpuTemperatureC > (m_lastEvaluatedTempC - m_hysteresisTempC) &&
          !m_lastAppliedModeWasAuto && m_lastAppliedPercent > 0) {
        calculatedSpeed = std::max(calculatedSpeed, m_lastAppliedPercent);
      }
    }
  }

  m_lastEvaluatedTempC = m_gpuTemperatureC;

  if (m_targetFanSpeedPercent != calculatedSpeed) {
    m_targetFanSpeedPercent = calculatedSpeed;
    emit targetFanSpeedPercentChanged();
  }

  const bool skipHardwareWrite =
      !force && ((isAuto && m_lastAppliedModeWasAuto) ||
                 (!isAuto && !m_lastAppliedModeWasAuto &&
                  calculatedSpeed == m_lastAppliedPercent));

  m_lastAppliedPercent = calculatedSpeed;
  m_lastAppliedModeWasAuto = isAuto;

  if (!skipHardwareWrite) {
    executeSetFanSpeed(calculatedSpeed, isAuto);
  }
}

bool FanController::executeSetFanSpeed(int percent, bool isAutoMode) {
  if (!m_controlSupported) {
    emit fanSpeedApplied(percent, false);
    return false;
  }

  CommandRunner runner;
  CommandRunner::RunOptions options;
  options.timeoutMs = 2000;

  bool success = false;

  const QString nvidiaSettingsProg =
      CommandRunner::resolveProgramPath(QStringLiteral("nvidia-settings"));

  if (!nvidiaSettingsProg.isEmpty() && m_hardwareType.contains(QStringLiteral("NVIDIA"))) {
    QStringList args;
    if (isAutoMode) {
      args << QStringLiteral("-a")
           << QStringLiteral("[gpu:0]/GPUFanControlState=0");
    } else {
      args << QStringLiteral("-a")
           << QStringLiteral("[gpu:0]/GPUFanControlState=1")
           << QStringLiteral("-a")
           << QStringLiteral("[fan:0]/GPUTargetFanSpeed=%1").arg(percent);
      if (m_fanCount > 1) {
        args << QStringLiteral("-a")
             << QStringLiteral("[fan:1]/GPUTargetFanSpeed=%1").arg(percent);
      }
    }

    const auto result = runner.run(QStringLiteral("nvidia-settings"), args, options);
    success = result.success();
  } else if (!m_verifiedHwmonPwmPath.isEmpty()) {
    if (!m_verifiedHwmonPwmEnablePath.isEmpty() &&
        QFile::exists(m_verifiedHwmonPwmEnablePath)) {
      writeTextFile(m_verifiedHwmonPwmEnablePath,
                    isAutoMode ? QStringLiteral("2") : QStringLiteral("1"));
    }
    if (!isAutoMode && QFile::exists(m_verifiedHwmonPwmPath)) {
      const int rawPwm = std::clamp((percent * 255) / 100, 0, 255);
      if (writeTextFile(m_verifiedHwmonPwmPath, QString::number(rawPwm))) {
        success = true;
      }
    } else if (isAutoMode) {
      success = true;
    }
  }

  m_lastAppliedPercent = percent;
  m_lastAppliedModeWasAuto = isAutoMode;

  emit fanSpeedApplied(percent, success);
  return success;
}

void FanController::setSupported(bool value) {
  if (m_supported != value) {
    m_supported = value;
    emit supportedChanged();
  }
}

void FanController::setControlSupported(bool value) {
  if (m_controlSupported != value) {
    m_controlSupported = value;
    emit controlSupportedChanged();
  }
}

void FanController::setCapability(ControlCapability cap) {
  if (m_capability != cap) {
    m_capability = cap;
    emit capabilityChanged();
  }
}

void FanController::setHardwareType(const QString &hwType) {
  if (m_hardwareType != hwType) {
    m_hardwareType = hwType;
    emit hardwareTypeChanged();
  }
}

void FanController::setStatusMessage(const QString &msg) {
  if (m_statusMessage != msg) {
    m_statusMessage = msg;
    emit statusMessageChanged();
  }
}

