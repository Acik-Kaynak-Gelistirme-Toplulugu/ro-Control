#include "systeminfoprovider.h"

#include "commandrunner.h"

#include <QFile>
#include <QList>
#include <QProcess>
#include <QRegularExpression>
#include <QStandardPaths>
#include <QStringList>
#include <QSysInfo>
#include <QTextStream>

#if defined(Q_OS_UNIX)
#include <sys/utsname.h>
#endif

namespace {

#if defined(Q_OS_LINUX)
QString virtualizationLabel(const QString &virtualization) {
  const QString normalized = virtualization.trimmed().toLower();
  if (normalized.isEmpty() || normalized == QStringLiteral("none")) {
    return {};
  }
  if (normalized == QStringLiteral("kvm")) {
    return QStringLiteral("KVM");
  }
  if (normalized == QStringLiteral("qemu")) {
    return QStringLiteral("QEMU");
  }
  if (normalized == QStringLiteral("vmware")) {
    return QStringLiteral("VMware");
  }
  if (normalized == QStringLiteral("oracle")) {
    return QStringLiteral("VirtualBox");
  }
  if (normalized == QStringLiteral("microsoft")) {
    return QStringLiteral("Hyper-V");
  }

  QString label = virtualization.trimmed();
  if (label.isEmpty()) {
    return {};
  }
  label[0] = label[0].toUpper();
  return label;
}
#endif

QString simplifiedDesktopName(const QString &desktop) {
  const QString trimmed = desktop.trimmed();
  if (trimmed.compare(QStringLiteral("KDE"), Qt::CaseInsensitive) == 0 ||
      trimmed.compare(QStringLiteral("KDE Plasma"), Qt::CaseInsensitive) == 0 ||
      trimmed.compare(QStringLiteral("Plasma"), Qt::CaseInsensitive) == 0) {
    return QStringLiteral("KDE Plasma");
  }

  if (trimmed.compare(QStringLiteral("GNOME"), Qt::CaseInsensitive) == 0) {
    return QStringLiteral("GNOME");
  }

  return trimmed;
}

QString valueFromOsRelease(const QString &key) {
  QFile file(QStringLiteral("/etc/os-release"));
  if (!file.open(QIODevice::ReadOnly | QIODevice::Text)) {
    return {};
  }

  QTextStream stream(&file);
  while (!stream.atEnd()) {
    const QString line = stream.readLine().trimmed();
    if (!line.startsWith(key + QLatin1Char('='))) {
      continue;
    }

    QString value = line.mid(key.size() + 1).trimmed();
    if (value.startsWith(QLatin1Char('"')) &&
        value.endsWith(QLatin1Char('"')) && value.size() >= 2) {
      value = value.mid(1, value.size() - 2);
    }
    return value;
  }

  return {};
}

[[maybe_unused]] QString valueFromFile(const QString &path) {
  QFile file(path);
  if (!file.open(QIODevice::ReadOnly | QIODevice::Text)) {
    return {};
  }

  return QString::fromUtf8(file.readAll()).trimmed();
}

} // namespace

SystemInfoProvider::SystemInfoProvider(QObject *parent) : QObject(parent) {
  refresh();
}

void SystemInfoProvider::refresh() {
  const QString nextOsName = detectOsName();
  const QString nextDesktopEnvironment = detectDesktopEnvironment();
  const QString nextKernelVersion = detectKernelVersion();
  const QString nextCpuModel = detectCpuModel();
  const QString nextVirtualizationType = detectVirtualizationType();
  const QString nextDeviceType = detectDeviceType();
  QString nextPowerSource;
  const bool nextOnBattery = detectOnBattery(&nextPowerSource);

  if (m_osName == nextOsName &&
      m_desktopEnvironment == nextDesktopEnvironment &&
      m_kernelVersion == nextKernelVersion && m_cpuModel == nextCpuModel &&
      m_deviceType == nextDeviceType &&
      m_virtualizationType == nextVirtualizationType &&
      m_onBattery == nextOnBattery && m_powerSource == nextPowerSource) {
    return;
  }

  m_osName = nextOsName;
  m_desktopEnvironment = nextDesktopEnvironment;
  m_kernelVersion = nextKernelVersion;
  m_cpuModel = nextCpuModel;
  m_deviceType = nextDeviceType;
  m_virtualizationType = nextVirtualizationType;
  m_onBattery = nextOnBattery;
  m_powerSource = nextPowerSource;
  emit infoChanged();
}

bool SystemInfoProvider::requestRestart() {
#if defined(Q_OS_LINUX)
  CommandRunner runner;
  CommandRunner::RunOptions options;
  options.timeoutMs = 30000;
  const auto result =
      runner.runAsRoot(QStringLiteral("systemctl"), {QStringLiteral("reboot")});
  if (result.success()) {
    return true;
  }

  const auto rebootResult = runner.runAsRoot(QStringLiteral("reboot"), {});
  if (rebootResult.success()) {
    return true;
  }

  return QProcess::startDetached(
      QStandardPaths::findExecutable(QStringLiteral("systemctl")),
      {QStringLiteral("--no-ask-password"), QStringLiteral("reboot")});
#endif
  return false;
}

QString SystemInfoProvider::detectOsName() const {
  const QString prettyName = valueFromOsRelease(QStringLiteral("PRETTY_NAME"));
  if (!prettyName.isEmpty()) {
    return prettyName;
  }

  const QString productName = QSysInfo::prettyProductName();
  if (!productName.isEmpty()) {
    return productName;
  }

  return QSysInfo::productType();
}

QString SystemInfoProvider::detectKernelVersion() const {
#if defined(Q_OS_UNIX)
  utsname name{};
  if (uname(&name) == 0) {
    return QString::fromLocal8Bit(name.release);
  }
#endif
  return QSysInfo::kernelVersion();
}

QString SystemInfoProvider::detectCpuModel() const {
#if defined(Q_OS_LINUX)
  CommandRunner runner;
  const auto lscpuResult = runner.run(QStringLiteral("lscpu"));
  if (lscpuResult.success()) {
    const QStringList lines =
        lscpuResult.stdout.split(QLatin1Char('\n'), Qt::SkipEmptyParts);
    for (const QString &line : lines) {
      if (line.startsWith(QStringLiteral("Model name:")) ||
          line.startsWith(QStringLiteral("Hardware:")) ||
          line.startsWith(QStringLiteral("Processor:"))) {
        const int separatorIndex = line.indexOf(QLatin1Char(':'));
        if (separatorIndex >= 0) {
          const QString value = line.mid(separatorIndex + 1).trimmed();
          if (!value.isEmpty() &&
              value.compare(QSysInfo::currentCpuArchitecture(),
                            Qt::CaseInsensitive) != 0) {
            return value;
          }
        }
      }
    }
  }

  QFile cpuInfo(QStringLiteral("/proc/cpuinfo"));
  if (cpuInfo.open(QIODevice::ReadOnly | QIODevice::Text)) {
    QTextStream stream(&cpuInfo);
    while (!stream.atEnd()) {
      const QString line = stream.readLine();
      if (line.startsWith(QStringLiteral("model name")) ||
          line.startsWith(QStringLiteral("Hardware")) ||
          line.startsWith(QStringLiteral("Processor"))) {
        const int separatorIndex = line.indexOf(QLatin1Char(':'));
        if (separatorIndex >= 0) {
          const QString value = line.mid(separatorIndex + 1).trimmed();
          if (!value.isEmpty() &&
              value.compare(QSysInfo::currentCpuArchitecture(),
                            Qt::CaseInsensitive) != 0) {
            return value;
          }
        }
      }
    }
  }

#elif defined(Q_OS_MACOS)
  CommandRunner runner;
  const auto result = runner.run(
      QStringLiteral("sysctl"),
      {QStringLiteral("-n"), QStringLiteral("machdep.cpu.brand_string")});
  if (result.success()) {
    const QString value = result.stdout.trimmed();
    if (!value.isEmpty()) {
      return value;
    }
  }
#endif

  const QString architecture = QSysInfo::currentCpuArchitecture();
  const QString virtualizationType = detectVirtualizationType();
  if (!virtualizationType.isEmpty()) {
    return architecture.isEmpty()
               ? QStringLiteral("%1 Virtual CPU").arg(virtualizationType)
               : QStringLiteral("%1 Virtual CPU (%2)")
                     .arg(virtualizationType, architecture);
  }
  return architecture.isEmpty() ? QStringLiteral("Unknown CPU")
                                : QStringLiteral("CPU (%1)").arg(architecture);
}

QString SystemInfoProvider::detectVirtualizationType() const {
#if defined(Q_OS_LINUX)
  CommandRunner runner;
  const auto virtResult = runner.run(QStringLiteral("systemd-detect-virt"));
  if (virtResult.success()) {
    const QString output = virtResult.stdout.trimmed();
    if (!output.isEmpty() && output != QStringLiteral("none")) {
      return virtualizationLabel(output);
    }
  }

  return virtualizationLabel(
      valueFromOsRelease(QStringLiteral("VIRTUALIZATION")));
#else
  return {};
#endif
}

QString SystemInfoProvider::detectDeviceType() const {
  const QString virtualizationType = detectVirtualizationType();
  if (!virtualizationType.isEmpty()) {
    if (virtualizationType.compare(QStringLiteral("QEMU"),
                                   Qt::CaseInsensitive) == 0 ||
        virtualizationType.compare(QStringLiteral("KVM"),
                                   Qt::CaseInsensitive) == 0) {
      return QStringLiteral("QEMU");
    }
    return virtualizationType;
  }

#if defined(Q_OS_LINUX)
  const QString chassisType =
      valueFromFile(QStringLiteral("/sys/class/dmi/id/chassis_type"));
  bool ok = false;
  const int chassis = chassisType.toInt(&ok);
  if (ok) {
    static const QList<int> laptopChassisTypes = {8, 9, 10, 14, 30, 31, 32};
    if (laptopChassisTypes.contains(chassis)) {
      return QStringLiteral("Laptop");
    }

    static const QList<int> desktopChassisTypes = {
        3, 4, 5, 6, 7, 15, 16, 35, 36,
    };
    if (desktopChassisTypes.contains(chassis)) {
      return QStringLiteral("Desktop");
    }
  }

  const QString chassisName =
      valueFromFile(QStringLiteral("/sys/class/dmi/id/chassis_vendor")) +
      QLatin1Char(' ') +
      valueFromFile(QStringLiteral("/sys/class/dmi/id/product_name"));
  if (chassisName.contains(QStringLiteral("laptop"), Qt::CaseInsensitive) ||
      chassisName.contains(QStringLiteral("notebook"), Qt::CaseInsensitive)) {
    return QStringLiteral("Laptop");
  }
#endif

  return QStringLiteral("Desktop");
}

QString SystemInfoProvider::detectDesktopEnvironment() const {
  QString desktop = qEnvironmentVariable("XDG_CURRENT_DESKTOP").trimmed();
  if (desktop.isEmpty()) {
    desktop = qEnvironmentVariable("DESKTOP_SESSION").trimmed();
  }

  if (desktop.isEmpty()) {
    return {};
  }

  desktop.replace(QLatin1Char(':'), QLatin1String(" / "));
  const QStringList parts = desktop.split(QLatin1Char('/'), Qt::SkipEmptyParts);
  QStringList normalizedParts;
  for (const QString &part : parts) {
    const QString trimmed = simplifiedDesktopName(part);
    if (trimmed.isEmpty()) {
      continue;
    }

    if (!normalizedParts.contains(trimmed, Qt::CaseInsensitive)) {
      normalizedParts << trimmed;
    }
  }

  return normalizedParts.join(QStringLiteral(" / "));
}

bool SystemInfoProvider::detectOnBattery(QString *sourceLabel) const {
  const QString overrideOnline =
      qEnvironmentVariable("RO_CONTROL_POWER_SUPPLY_ONLINE").trimmed();
  if (!overrideOnline.isEmpty()) {
    const bool onBat = (overrideOnline == QStringLiteral("0"));
    if (sourceLabel) {
      *sourceLabel =
          onBat ? QStringLiteral("Battery") : QStringLiteral("AC Power");
    }
    return onBat;
  }

#if defined(Q_OS_LINUX)
  QDir powerDir(QStringLiteral("/sys/class/power_supply"));
  if (!powerDir.exists()) {
    if (sourceLabel) {
      *sourceLabel = QStringLiteral("AC / Desktop");
    }
    return false;
  }

  const QFileInfoList entries =
      powerDir.entryInfoList(QDir::Dirs | QDir::NoDotAndDotDot);
  bool hasBattery = false;
  bool isDischarging = false;
  bool isAcOnline = false;

  for (const QFileInfo &entry : entries) {
    const QString type =
        valueFromFile(entry.absoluteFilePath() + QStringLiteral("/type"))
            .trimmed();
    if (type.compare(QStringLiteral("Battery"), Qt::CaseInsensitive) == 0) {
      hasBattery = true;
      const QString status =
          valueFromFile(entry.absoluteFilePath() + QStringLiteral("/status"))
              .trimmed();
      if (status.compare(QStringLiteral("Discharging"), Qt::CaseInsensitive) ==
          0) {
        isDischarging = true;
      }
    } else if (type.compare(QStringLiteral("Mains"), Qt::CaseInsensitive) ==
               0) {
      const QString online =
          valueFromFile(entry.absoluteFilePath() + QStringLiteral("/online"))
              .trimmed();
      if (online == QStringLiteral("1")) {
        isAcOnline = true;
      }
    }
  }

  if (!hasBattery) {
    if (sourceLabel) {
      *sourceLabel = QStringLiteral("AC / Desktop");
    }
    return false;
  }

  const bool onBat = isDischarging || (!isAcOnline && hasBattery);
  if (sourceLabel) {
    *sourceLabel =
        onBat ? QStringLiteral("Battery") : QStringLiteral("AC Power");
  }
  return onBat;
#else
  if (sourceLabel) {
    *sourceLabel = QStringLiteral("AC Power");
  }
  return false;
#endif
}
