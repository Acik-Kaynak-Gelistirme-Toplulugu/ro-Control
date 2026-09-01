#include "powercontroller.h"

#include <QRegularExpression>
#include <QSettings>
#include <algorithm>

#include "nvidia/detector.h"
#include "system/capabilityprobe.h"
#include "system/commandrunner.h"
#include "system/polkit.h"

namespace {

constexpr auto kSettingsGroup = "Power";
constexpr auto kKeyPreset = "Preset";
constexpr auto kKeyLastTargetWatts = "LastTargetWatts";
constexpr auto kKeyPersistenceMode = "PersistenceMode";

bool parseDoubleValue(const QString &field, double *value) {
  if (!value) {
    return false;
  }
  QString normalized = field.trimmed();
  normalized.remove(QRegularExpression(
      QStringLiteral(R"(\s*w\b)"), QRegularExpression::CaseInsensitiveOption));
  if (normalized.isEmpty() ||
      normalized.compare(QStringLiteral("n/a"), Qt::CaseInsensitive) == 0 ||
      normalized.compare(QStringLiteral("not supported"),
                         Qt::CaseInsensitive) == 0 ||
      normalized.compare(QStringLiteral("unknown"), Qt::CaseInsensitive) == 0) {
    return false;
  }
  bool ok = false;
  const double v = normalized.toDouble(&ok);
  if (ok) {
    *value = v;
    return true;
  }
  return false;
}

} // namespace

PowerController::PowerController(QObject *parent)
    : QObject(parent), m_timer(this) {
  loadSettings();
  detectCapabilities();

  connect(&m_timer, &QTimer::timeout, this,
          &PowerController::queryPowerMetrics);
  m_timer.setInterval(3000);
  m_timer.start();
}

PowerController::~PowerController() {
  m_timer.stop();
  saveSettings();
}

bool PowerController::supported() const { return m_supported; }
bool PowerController::controlSupported() const { return m_controlSupported; }
double PowerController::currentPowerDrawW() const {
  return m_currentPowerDrawW;
}
double PowerController::powerLimitW() const { return m_powerLimitW; }
double PowerController::minPowerLimitW() const { return m_minPowerLimitW; }
double PowerController::maxPowerLimitW() const { return m_maxPowerLimitW; }
double PowerController::defaultPowerLimitW() const {
  return m_defaultPowerLimitW;
}
bool PowerController::persistenceModeEnabled() const {
  return m_persistenceModeEnabled;
}
int PowerController::coreClockOffsetMHz() const { return m_coreClockOffsetMHz; }
int PowerController::memoryClockOffsetMHz() const {
  return m_memoryClockOffsetMHz;
}
bool PowerController::clockOffsetSupported() const {
  return m_controlSupported;
}

QString PowerController::powerPreset() const { return m_powerPreset; }
QStringList PowerController::availablePresets() const {
  return {QStringLiteral("eco"), QStringLiteral("balanced"),
          QStringLiteral("performance"), QStringLiteral("custom")};
}
QString PowerController::statusMessage() const { return m_statusMessage; }

void PowerController::setStatusMessage(const QString &msg) {
  if (m_statusMessage != msg) {
    m_statusMessage = msg;
    emit statusMessageChanged();
  }
}

void PowerController::loadSettings() {
  QSettings settings;
  settings.beginGroup(QString::fromLatin1(kSettingsGroup));
  m_powerPreset =
      settings
          .value(QString::fromLatin1(kKeyPreset), QStringLiteral("balanced"))
          .toString();
  m_persistenceModeEnabled =
      settings.value(QString::fromLatin1(kKeyPersistenceMode), false).toBool();
  m_coreClockOffsetMHz =
      settings.value(QStringLiteral("CoreClockOffset"), 0).toInt();
  m_memoryClockOffsetMHz =
      settings.value(QStringLiteral("MemoryClockOffset"), 0).toInt();
  settings.endGroup();
}

void PowerController::saveSettings() {
  QSettings settings;
  settings.beginGroup(QString::fromLatin1(kSettingsGroup));
  settings.setValue(QString::fromLatin1(kKeyPreset), m_powerPreset);
  settings.setValue(QString::fromLatin1(kKeyPersistenceMode),
                    m_persistenceModeEnabled);
  settings.setValue(QString::fromLatin1(kKeyLastTargetWatts), m_powerLimitW);
  settings.setValue(QStringLiteral("CoreClockOffset"), m_coreClockOffsetMHz);
  settings.setValue(QStringLiteral("MemoryClockOffset"),
                    m_memoryClockOffsetMHz);
  settings.endGroup();
}

void PowerController::detectCapabilities() {
  NvidiaDetector detector;
  detector.refresh();

  const bool hasNvidiaGpu = detector.gpuFound();
  const bool hasNvidiaSmi =
      CapabilityProbe::isToolAvailable(QStringLiteral("nvidia-smi"));

  const bool nextSupported = hasNvidiaGpu && hasNvidiaSmi;
  if (m_supported != nextSupported) {
    m_supported = nextSupported;
    emit supportedChanged();
  }

  // Probe whether nvidia-smi power limit queries succeed
  queryPowerMetrics();

  const bool nextControl =
      m_supported && (m_minPowerLimitW > 0.0 || m_powerLimitW > 0.0);
  if (m_controlSupported != nextControl) {
    m_controlSupported = nextControl;
    emit controlSupportedChanged();
  }
}

void PowerController::queryPowerMetrics() {
  if (!m_supported) {
    return;
  }

  CommandRunner runner;
  CommandRunner::RunOptions options;
  options.timeoutMs = 2000;
  const auto result = runner.run(
      QStringLiteral("nvidia-smi"),
      {QStringLiteral("-i"), QStringLiteral("0"),
       QStringLiteral(
           "--query-gpu=power.draw,power.limit,power.min_limit,power."
           "max_limit,power.default_limit,persistence_mode"),
       QStringLiteral("--format=csv,noheader,nounits")},
      options);

  if (!result.success() || result.stdout.trimmed().isEmpty()) {
    return;
  }

  const QStringList parts = result.stdout.trimmed().split(QLatin1Char(','));
  if (parts.size() >= 5) {
    double draw = 0.0;
    double limit = 0.0;
    double minLim = 0.0;
    double maxLim = 0.0;
    double defLim = 0.0;

    if (parseDoubleValue(parts.value(0), &draw)) {
      updatePowerDraw(draw);
    }
    if (parseDoubleValue(parts.value(1), &limit)) {
      if (!qFuzzyCompare(m_powerLimitW, limit)) {
        m_powerLimitW = limit;
        emit powerLimitWChanged();
      }
    }
    bool constraintsChanged = false;
    if (parseDoubleValue(parts.value(2), &minLim)) {
      if (!qFuzzyCompare(m_minPowerLimitW, minLim)) {
        m_minPowerLimitW = minLim;
        constraintsChanged = true;
      }
    }
    if (parseDoubleValue(parts.value(3), &maxLim)) {
      if (!qFuzzyCompare(m_maxPowerLimitW, maxLim)) {
        m_maxPowerLimitW = maxLim;
        constraintsChanged = true;
      }
    }
    if (parseDoubleValue(parts.value(4), &defLim)) {
      if (!qFuzzyCompare(m_defaultPowerLimitW, defLim)) {
        m_defaultPowerLimitW = defLim;
        constraintsChanged = true;
      }
    }
    if (constraintsChanged) {
      emit powerLimitConstraintsChanged();
    }

    if (parts.size() >= 6) {
      const QString pmStr = parts.value(5).trimmed().toLower();
      const bool pmEnabled =
          (pmStr == QStringLiteral("enabled") || pmStr == QStringLiteral("1"));
      if (m_persistenceModeEnabled != pmEnabled) {
        m_persistenceModeEnabled = pmEnabled;
        emit persistenceModeChanged();
      }
    }

    if (!m_controlSupported &&
        (m_minPowerLimitW > 0.0 || m_powerLimitW > 0.0)) {
      m_controlSupported = true;
      emit controlSupportedChanged();
    }
  }
}

void PowerController::updatePowerDraw(double watts) {
  if (!qFuzzyCompare(m_currentPowerDrawW, watts)) {
    m_currentPowerDrawW = watts;
    emit currentPowerDrawWChanged();
  }
}

void PowerController::refresh() {
  detectCapabilities();
  queryPowerMetrics();
}

bool PowerController::setPowerLimit(double watts) {
  if (watts <= 0.0) {
    setStatusMessage(QStringLiteral("Invalid power limit value."));
    emit powerLimitApplied(watts, false);
    return false;
  }

  // Constrain to known boundaries if available
  if (m_minPowerLimitW > 0.0 && watts < m_minPowerLimitW) {
    watts = m_minPowerLimitW;
  }
  if (m_maxPowerLimitW > 0.0 && watts > m_maxPowerLimitW) {
    watts = m_maxPowerLimitW;
  }

  PolkitHelper polkit;
  const QString wattsStr = QString::number(static_cast<int>(watts));
  const auto result = polkit.runPrivileged(
      QStringLiteral("nvidia-smi"), {QStringLiteral("-i"), QStringLiteral("0"),
                                     QStringLiteral("-pl"), wattsStr});

  if (result.success()) {
    m_powerLimitW = watts;
    emit powerLimitWChanged();
    setStatusMessage(QStringLiteral("Power limit set to %1 W.").arg(wattsStr));
    emit powerLimitApplied(watts, true);
    saveSettings();
    return true;
  }

  setStatusMessage(QStringLiteral("Failed to set power limit: %1")
                       .arg(result.stderr.trimmed()));
  emit powerLimitApplied(watts, false);
  return false;
}

bool PowerController::setPersistenceMode(bool enabled) {
  PolkitHelper polkit;
  const QString flag = enabled ? QStringLiteral("1") : QStringLiteral("0");
  const auto result = polkit.runPrivileged(
      QStringLiteral("nvidia-smi"),
      {QStringLiteral("-i"), QStringLiteral("0"), QStringLiteral("-pm"), flag});

  if (result.success()) {
    m_persistenceModeEnabled = enabled;
    emit persistenceModeChanged();
    setStatusMessage(QStringLiteral("Persistence mode %1.")
                         .arg(enabled ? QStringLiteral("enabled")
                                      : QStringLiteral("disabled")));
    saveSettings();
    return true;
  }

  setStatusMessage(QStringLiteral("Failed to change persistence mode: %1")
                       .arg(result.stderr.trimmed()));
  return false;
}

bool PowerController::applyPowerPreset(const QString &preset) {
  const QString lower = preset.trimmed().toLower();
  double targetWatts = 0.0;

  const double baseDefault = (m_defaultPowerLimitW > 0.0) ? m_defaultPowerLimitW
                             : (m_powerLimitW > 0.0)      ? m_powerLimitW
                                                          : 150.0;
  const double minW =
      (m_minPowerLimitW > 0.0) ? m_minPowerLimitW : (baseDefault * 0.70);
  const double maxW =
      (m_maxPowerLimitW > 0.0) ? m_maxPowerLimitW : (baseDefault * 1.15);

  if (lower == QStringLiteral("eco")) {
    targetWatts = minW;
  } else if (lower == QStringLiteral("balanced")) {
    targetWatts = baseDefault;
  } else if (lower == QStringLiteral("performance")) {
    targetWatts = maxW;
  } else if (lower == QStringLiteral("custom")) {
    m_powerPreset = lower;
    emit powerPresetChanged();
    saveSettings();
    return true;
  } else {
    setStatusMessage(QStringLiteral("Unknown power preset: %1").arg(preset));
    return false;
  }

  if (setPowerLimit(targetWatts)) {
    m_powerPreset = lower;
    emit powerPresetChanged();
    saveSettings();
    return true;
  }
  return false;
}

bool PowerController::resetToDefault() {
  if (m_defaultPowerLimitW > 0.0) {
    return setPowerLimit(m_defaultPowerLimitW);
  }
  return applyPowerPreset(QStringLiteral("balanced"));
}

bool PowerController::setClockOffsets(int coreOffsetMHz, int memoryOffsetMHz) {
  const int clampedCore =
      std::clamp(coreOffsetMHz, minCoreOffsetMHz(), maxCoreOffsetMHz());
  const int clampedMem =
      std::clamp(memoryOffsetMHz, minMemoryOffsetMHz(), maxMemoryOffsetMHz());

  PolkitHelper polkit;
  CommandRunner runner;
  CommandRunner::RunOptions options;
  options.timeoutMs = 2000;

  const QString nvidiaSettingsProg =
      CommandRunner::resolveProgramPath(QStringLiteral("nvidia-settings"));

  bool success = false;
  if (!nvidiaSettingsProg.isEmpty()) {
    const auto result =
        runner.run(QStringLiteral("nvidia-settings"),
                   {QStringLiteral("-a"),
                    QStringLiteral("[gpu:0]/GPUGraphicsClockOffset[3]=%1")
                        .arg(clampedCore),
                    QStringLiteral("-a"),
                    QStringLiteral("[gpu:0]/GPUMemoryTransferRateOffset[3]=%1")
                        .arg(clampedMem)},
                   options);
    success = result.success();
  }

  if (!success) {
    const auto privRes = polkit.runPrivileged(
        QStringLiteral("nvidia-settings"),
        {QStringLiteral("-a"),
         QStringLiteral("[gpu:0]/GPUGraphicsClockOffset[3]=%1")
             .arg(clampedCore),
         QStringLiteral("-a"),
         QStringLiteral("[gpu:0]/GPUMemoryTransferRateOffset[3]=%1")
             .arg(clampedMem)});
    success = privRes.success();
  }

  if (qEnvironmentVariableIsSet("RO_CONTROL_MOCK_POWER_CONTROL") ||
      qEnvironmentVariableIsSet("RO_CONTROL_MOCK_FAN_CAPABILITY")) {
    success = true;
  }

  if (success) {
    m_coreClockOffsetMHz = clampedCore;
    m_memoryClockOffsetMHz = clampedMem;
    emit clockOffsetsChanged();
    setStatusMessage(
        QStringLiteral("Clock offsets set to Core: %+1 MHz, Memory: %+2 MHz.")
            .arg(clampedCore)
            .arg(clampedMem));
    saveSettings();
    emit clockOffsetsApplied(clampedCore, clampedMem, true);
    return true;
  }

  setStatusMessage(QStringLiteral(
      "Failed to set clock offsets. Ensure Coolbits 8/28 is active."));
  emit clockOffsetsApplied(clampedCore, clampedMem, false);
  return false;
}

bool PowerController::resetClockOffsets() { return setClockOffsets(0, 0); }
