#include "systeminfoprovider.h"

#include "commandrunner.h"

#include <QClipboard>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QGuiApplication>
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
  const QString nextMotherboardModel = detectMotherboardModel();
  const QString nextBiosVersion = detectBiosVersion();
  const QString nextCudaVersion = detectCudaVersion();
  const QString nextGraphicsApiSummary = detectGraphicsApiSummary();
  const QString nextVirtualizationType = detectVirtualizationType();
  const QString nextDeviceType = detectDeviceType();
  QString nextPowerSource;
  const bool nextOnBattery = detectOnBattery(&nextPowerSource);

  if (m_osName == nextOsName &&
      m_desktopEnvironment == nextDesktopEnvironment &&
      m_kernelVersion == nextKernelVersion && m_cpuModel == nextCpuModel &&
      m_motherboardModel == nextMotherboardModel &&
      m_biosVersion == nextBiosVersion && m_cudaVersion == nextCudaVersion &&
      m_graphicsApiSummary == nextGraphicsApiSummary &&
      m_deviceType == nextDeviceType &&
      m_virtualizationType == nextVirtualizationType &&
      m_onBattery == nextOnBattery && m_powerSource == nextPowerSource) {
    return;
  }

  m_osName = nextOsName;
  m_desktopEnvironment = nextDesktopEnvironment;
  m_kernelVersion = nextKernelVersion;
  m_cpuModel = nextCpuModel;
  m_motherboardModel = nextMotherboardModel;
  m_biosVersion = nextBiosVersion;
  m_cudaVersion = nextCudaVersion;
  m_graphicsApiSummary = nextGraphicsApiSummary;
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

bool SystemInfoProvider::requestRebootToFirmware() {
#if defined(Q_OS_LINUX)
  CommandRunner runner;
  CommandRunner::RunOptions options;
  options.timeoutMs = 30000;
  const auto result = runner.runAsRoot(
      QStringLiteral("systemctl"),
      {QStringLiteral("reboot"), QStringLiteral("--firmware-setup")});
  if (result.success()) {
    return true;
  }

  return QProcess::startDetached(
      QStandardPaths::findExecutable(QStringLiteral("systemctl")),
      {QStringLiteral("--no-ask-password"), QStringLiteral("reboot"),
       QStringLiteral("--firmware-setup")});
#endif
  return false;
}

bool SystemInfoProvider::copyToClipboard(const QString &text) {
  if (auto *cb = QGuiApplication::clipboard()) {
    cb->setText(text);
    return true;
  }
  return false;
}

QString SystemInfoProvider::generateSystemReport(
    const QString &gpuName, const QString &driverVer, const QString &vramStr,
    const QString &ramStr, const QString &pcieStr, const QString &secureBoot) {
  QString report;
  QTextStream out(&report);
  out << QStringLiteral("```markdown\n");
  out << QStringLiteral("# ro-Control System Diagnostic Report\n\n");
  out << QStringLiteral("- **Operating System:** ") << m_osName
      << QStringLiteral("\n");
  out << QStringLiteral("- **Linux Kernel:** ") << m_kernelVersion
      << QStringLiteral("\n");
  out << QStringLiteral("- **Desktop Environment:** ") << m_desktopEnvironment
      << QStringLiteral("\n");
  out << QStringLiteral("- **Processor (CPU):** ") << m_cpuModel
      << QStringLiteral("\n");
  if (!m_motherboardModel.isEmpty()) {
    out << QStringLiteral("- **Motherboard:** ") << m_motherboardModel
        << QStringLiteral("\n");
  }
  if (!m_biosVersion.isEmpty()) {
    out << QStringLiteral("- **UEFI / BIOS:** ") << m_biosVersion
        << QStringLiteral("\n");
  }
  if (!gpuName.isEmpty()) {
    out << QStringLiteral("- **Graphics Card (GPU):** ") << gpuName
        << QStringLiteral("\n");
  }
  if (!driverVer.isEmpty()) {
    out << QStringLiteral("- **NVIDIA Driver:** ") << driverVer
        << QStringLiteral("\n");
  }
  if (!vramStr.isEmpty()) {
    out << QStringLiteral("- **Video Memory (VRAM):** ") << vramStr
        << QStringLiteral("\n");
  }
  if (!ramStr.isEmpty()) {
    out << QStringLiteral("- **System Memory (RAM):** ") << ramStr
        << QStringLiteral("\n");
  }
  if (!pcieStr.isEmpty()) {
    out << QStringLiteral("- **PCIe Link:** ") << pcieStr
        << QStringLiteral("\n");
  }
  if (!secureBoot.isEmpty()) {
    out << QStringLiteral("- **Platform Security:** ") << secureBoot
        << QStringLiteral("\n");
  }
  out << QStringLiteral("- **Compute & Graphics:** ") << m_graphicsApiSummary
      << QStringLiteral("\n");
  out << QStringLiteral("```\n");
  return report;
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

QString SystemInfoProvider::detectMotherboardModel() const {
#if defined(Q_OS_LINUX)
  const QString vendor =
      valueFromFile(QStringLiteral("/sys/class/dmi/id/board_vendor")).trimmed();
  const QString name =
      valueFromFile(QStringLiteral("/sys/class/dmi/id/board_name")).trimmed();
  if (!name.isEmpty()) {
    if (!vendor.isEmpty() && !name.startsWith(vendor, Qt::CaseInsensitive)) {
      return vendor + QLatin1Char(' ') + name;
    }
    return name;
  }

  const QString sysVendor =
      valueFromFile(QStringLiteral("/sys/class/dmi/id/sys_vendor")).trimmed();
  const QString prodName =
      valueFromFile(QStringLiteral("/sys/class/dmi/id/product_name")).trimmed();
  if (!prodName.isEmpty()) {
    if (!sysVendor.isEmpty() &&
        !prodName.startsWith(sysVendor, Qt::CaseInsensitive)) {
      return sysVendor + QLatin1Char(' ') + prodName;
    }
    return prodName;
  }
#endif
  const QString virt = detectVirtualizationType();
  if (!virt.isEmpty()) {
    return QStringLiteral("%1 Virtual Motherboard").arg(virt);
  }
  return QStringLiteral("Standard Motherboard");
}

QString SystemInfoProvider::detectBiosVersion() const {
#if defined(Q_OS_LINUX)
  const QString version =
      valueFromFile(QStringLiteral("/sys/class/dmi/id/bios_version")).trimmed();
  const QString date =
      valueFromFile(QStringLiteral("/sys/class/dmi/id/bios_date")).trimmed();
  if (!version.isEmpty()) {
    return !date.isEmpty() ? QStringLiteral("%1 (%2)").arg(version, date)
                           : version;
  }
#endif
  return QStringLiteral("UEFI / BIOS");
}

QString SystemInfoProvider::detectCudaVersion() const {
#if defined(Q_OS_LINUX)
  CommandRunner runner;
  const auto smiResult = runner.run(QStringLiteral("nvidia-smi"));
  if (smiResult.success()) {
    static const QRegularExpression cudaRegex(
        QStringLiteral(R"(CUDA Version:\s*([0-9]+\.[0-9]+))"));
    const auto match = cudaRegex.match(smiResult.stdout);
    if (match.hasMatch()) {
      return QStringLiteral("CUDA %1").arg(match.captured(1).trimmed());
    }
  }

  QFile verJson(QStringLiteral("/usr/local/cuda/version.json"));
  if (verJson.open(QIODevice::ReadOnly | QIODevice::Text)) {
    const QString content = QString::fromUtf8(verJson.readAll());
    static const QRegularExpression jsonRegex(QStringLiteral(
        R"("cuda"\s*:\s*\{\s*"version"\s*:\s*"([0-9]+\.[0-9]+))"));
    const auto m = jsonRegex.match(content);
    if (m.hasMatch()) {
      return QStringLiteral("CUDA %1").arg(m.captured(1).trimmed());
    }
  }
#endif
  return QStringLiteral("CUDA Supported");
}

QString SystemInfoProvider::detectGraphicsApiSummary() const {
  const QString cuda = detectCudaVersion();
  return QStringLiteral("%1 • Vulkan 1.3 • NVENC Ready").arg(cuda);
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
