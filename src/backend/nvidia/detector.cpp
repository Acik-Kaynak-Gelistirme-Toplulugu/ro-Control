#include "detector.h"

#include "system/capabilityprobe.h"
#include "system/commandrunner.h"
#include "system/sessionutil.h"

#include <QDir>
#include <QFile>
#include <QRegularExpression>
#include <QTextStream>
#include <QtGlobal>

namespace {

QString normalizedRpmDriverVersion(const QString &packageVersion) {
  QString version = packageVersion.trimmed();
  const int epochIndex = version.indexOf(QLatin1Char(':'));
  if (epochIndex >= 0) {
    version = version.mid(epochIndex + 1);
  }

  const int releaseIndex = version.indexOf(QLatin1Char('-'));
  if (releaseIndex > 0) {
    version = version.left(releaseIndex);
  }

  return version.trimmed();
}

} // namespace

NvidiaDetector::NvidiaDetector(QObject *parent) : QObject(parent) {}

NvidiaDetector::GpuInfo NvidiaDetector::detect() const {
  GpuInfo info;

  info.displayAdapterName = detectDisplayAdapterName();
  info.name = detectGpuName();
  info.found = !info.name.isEmpty();
  info.driverVersion = detectDriverVersion();
  if (info.driverVersion.isEmpty()) {
    info.driverVersion = detectDriverPackageVersion();
  }
  info.driverPackageInstalled = detectDriverPackageInstalled();
  info.driverLoaded = isModuleLoaded(QStringLiteral("nvidia"));
  info.nouveauActive = isModuleLoaded(QStringLiteral("nouveau"));
  info.openKernelModulesInstalled =
      isPackageInstalled(QStringLiteral("akmod-nvidia-open"));
  info.secureBootEnabled = detectSecureBoot(&info.secureBootKnown);
  info.sessionType = SessionUtil::detectSessionType();

  return info;
}

bool NvidiaDetector::hasNvidiaGpu() const { return !detectGpuName().isEmpty(); }

bool NvidiaDetector::isDriverInstalled() const {
  return !installedDriverVersion().isEmpty() || detectDriverPackageInstalled();
}

QString NvidiaDetector::installedDriverVersion() const {
  const QString activeVersion = detectDriverVersion();
  if (!activeVersion.isEmpty()) {
    return activeVersion;
  }
  return detectDriverPackageVersion();
}

QString NvidiaDetector::activeDriver() const {
  if (m_info.driverLoaded) {
    if (m_info.openKernelModulesInstalled) {
      return tr("NVIDIA Open Kernel Modules");
    }
    return tr("NVIDIA Driver");
  }
  if (m_info.driverPackageInstalled)
    return tr("Installed, Restart Required");
  if (m_info.nouveauActive)
    return tr("Fallback Open Driver");
  return tr("Not Installed");
}

QString NvidiaDetector::verificationReport() const {
  const QString gpuText = m_info.found ? m_info.name
                                       : (m_info.displayAdapterName.isEmpty()
                                              ? tr("Unavailable")
                                              : m_info.displayAdapterName);
  const QString versionText =
      m_info.driverVersion.isEmpty() ? tr("Unavailable") : m_info.driverVersion;

  return tr("GPU: %1\nDriver Version: %2\nSecure Boot: %3\nSession: %4\n"
            "Active Stack: %5\nFallback Open Driver: %6")
      .arg(gpuText, versionText,
           m_info.secureBootKnown
               ? (m_info.secureBootEnabled ? tr("Enabled") : tr("Disabled"))
               : tr("Unknown"),
           m_info.sessionType.isEmpty() ? tr("Unknown") : m_info.sessionType,
           activeDriver(),
           m_info.nouveauActive ? tr("Active") : tr("Inactive"));
}

void NvidiaDetector::refresh() {
  m_info = detect();
  emit infoChanged();
}

QString NvidiaDetector::detectDisplayAdapterName() const {
  if (!CapabilityProbe::isToolAvailable(QStringLiteral("lspci"))) {
    return {};
  }

  CommandRunner runner;

  const auto result =
      runner.run(QStringLiteral("lspci"), {QStringLiteral("-mm")});

  if (!result.success())
    return {};

  const QStringList lines = result.stdout.split(QLatin1Char('\n'));
  for (const QString &line : lines) {
    if (line.contains(QStringLiteral("VGA"), Qt::CaseInsensitive) ||
        line.contains(QStringLiteral("3D controller"), Qt::CaseInsensitive) ||
        line.contains(QStringLiteral("Display controller"),
                      Qt::CaseInsensitive)) {
      static const QRegularExpression re(QStringLiteral("\"([^\"]+)\""));
      auto it = re.globalMatch(line);
      QStringList parts;
      while (it.hasNext())
        parts << it.next().captured(1);

      if (parts.size() >= 3)
        return parts[2];
    }
  }

  return {};
}

QString NvidiaDetector::detectGpuName() const {
  if (!CapabilityProbe::isToolAvailable(QStringLiteral("lspci"))) {
    return {};
  }

  CommandRunner runner;

  const auto result =
      runner.run(QStringLiteral("lspci"), {QStringLiteral("-mm")});

  if (!result.success())
    return {};

  const QStringList lines = result.stdout.split(QLatin1Char('\n'));
  for (const QString &line : lines) {
    if (line.contains(QStringLiteral("NVIDIA"), Qt::CaseInsensitive) &&
        (line.contains(QStringLiteral("VGA"), Qt::CaseInsensitive) ||
         line.contains(QStringLiteral("3D controller"), Qt::CaseInsensitive) ||
         line.contains(QStringLiteral("Display controller"),
                       Qt::CaseInsensitive))) {
      static const QRegularExpression re(QStringLiteral("\"([^\"]+)\""));
      auto it = re.globalMatch(line);
      QStringList parts;
      while (it.hasNext())
        parts << it.next().captured(1);

      if (parts.size() >= 3)
        return parts[2];
    }
  }

  return {};
}

QString NvidiaDetector::detectDriverVersion() const {
  CommandRunner runner;

  if (CapabilityProbe::isToolAvailable(QStringLiteral("nvidia-smi"))) {
    const auto result =
        runner.run(QStringLiteral("nvidia-smi"),
                   {QStringLiteral("--query-gpu=driver_version"),
                    QStringLiteral("--format=csv,noheader")});

    if (result.success())
      return result.stdout.trimmed();
  }

  if (!CapabilityProbe::isToolAvailable(QStringLiteral("modinfo"))) {
    return {};
  }

  const auto modinfo =
      runner.run(QStringLiteral("modinfo"), {QStringLiteral("nvidia")});

  if (modinfo.success()) {
    static const QRegularExpression re(QStringLiteral("^version:\\s+(.+)$"),
                                       QRegularExpression::MultilineOption);
    const auto match = re.match(modinfo.stdout);
    if (match.hasMatch())
      return match.captured(1).trimmed();
  }

  return {};
}

QString NvidiaDetector::detectDriverPackageVersion() const {
  if (!CapabilityProbe::isToolAvailable(QStringLiteral("rpm"))) {
    return {};
  }

  const QStringList packageNames = {QStringLiteral("akmod-nvidia"),
                                    QStringLiteral("akmod-nvidia-open")};
  CommandRunner runner;
  for (const QString &packageName : packageNames) {
    const auto result = runner.run(
        QStringLiteral("rpm"),
        {QStringLiteral("-q"), QStringLiteral("--qf"),
         QStringLiteral("%{EPOCH}:%{VERSION}-%{RELEASE}"), packageName});
    if (result.success()) {
      const QString version = normalizedRpmDriverVersion(result.stdout);
      if (!version.isEmpty()) {
        return version;
      }
    }
  }

  return {};
}

bool NvidiaDetector::detectDriverPackageInstalled() const {
  return isPackageInstalled(QStringLiteral("akmod-nvidia")) ||
         isPackageInstalled(QStringLiteral("akmod-nvidia-open"));
}

bool NvidiaDetector::isPackageInstalled(const QString &packageName) const {
  if (!CapabilityProbe::isToolAvailable(QStringLiteral("rpm"))) {
    return false;
  }

  CommandRunner runner;
  const auto result =
      runner.run(QStringLiteral("rpm"), {QStringLiteral("-q"), packageName});
  return result.success();
}

bool NvidiaDetector::isModuleLoaded(const QString &moduleName) const {
  QFile modules(QStringLiteral("/proc/modules"));
  if (!modules.open(QIODevice::ReadOnly | QIODevice::Text))
    return false;

  QTextStream stream(&modules);
  while (!stream.atEnd()) {
    const QString line = stream.readLine();
    if (line.startsWith(moduleName + QLatin1Char(' ')))
      return true;
  }

  return false;
}

bool NvidiaDetector::detectSecureBoot(bool *known) const {
  bool enabled = false;
  bool efivarsKnown = false;
  if (detectSecureBootFromEfivars(&enabled, &efivarsKnown)) {
    if (known != nullptr) {
      *known = efivarsKnown;
    }
    return enabled;
  }

  if (!CapabilityProbe::isToolAvailable(QStringLiteral("mokutil"))) {
    if (known != nullptr) {
      *known = false;
    }
    return false;
  }

  CommandRunner runner;
  const auto result =
      runner.run(QStringLiteral("mokutil"), {QStringLiteral("--sb-state")});

  if (result.success() || result.exitCode == 1) {
    if (known != nullptr) {
      *known = true;
    }
    return result.stdout.contains(QStringLiteral("enabled"),
                                  Qt::CaseInsensitive);
  }

  if (known != nullptr) {
    *known = false;
  }

  return false;
}

bool NvidiaDetector::detectSecureBootFromEfivars(bool *enabled,
                                                 bool *known) const {
  if (enabled == nullptr || known == nullptr) {
    return false;
  }

  const QString overridePath =
      qEnvironmentVariable("RO_CONTROL_SECURE_BOOT_EFIVAR_PATH").trimmed();
  QString secureBootPath = overridePath;
  if (secureBootPath.isEmpty()) {
    QDir efivarsDir(QStringLiteral("/sys/firmware/efi/efivars"));
    const QStringList entries = efivarsDir.entryList(
        {QStringLiteral("SecureBoot-*")}, QDir::Files, QDir::Name);
    if (!entries.isEmpty()) {
      secureBootPath = efivarsDir.filePath(entries.constFirst());
    }
  }

  if (secureBootPath.isEmpty()) {
    return false;
  }

  QFile file(secureBootPath);
  if (!file.open(QIODevice::ReadOnly)) {
    return false;
  }

  const QByteArray raw = file.readAll();
  if (raw.size() < 5) {
    return false;
  }

  *enabled = raw.at(4) != 0;
  *known = true;
  return true;
}
