#include "systeminfoprovider.h"

#include "commandrunner.h"

#include <QFile>
#include <QRegularExpression>
#include <QSysInfo>
#include <QTextStream>

#if defined(Q_OS_UNIX)
#include <sys/utsname.h>
#endif

namespace {

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
    if (value.startsWith(QLatin1Char('"')) && value.endsWith(QLatin1Char('"')) &&
        value.size() >= 2) {
      value = value.mid(1, value.size() - 2);
    }
    return value;
  }

  return {};
}

}  // namespace

SystemInfoProvider::SystemInfoProvider(QObject *parent) : QObject(parent) {
  refresh();
}

void SystemInfoProvider::refresh() {
  const QString nextOsName = detectOsName();
  const QString nextDesktopEnvironment = detectDesktopEnvironment();
  const QString nextKernelVersion = detectKernelVersion();
  const QString nextCpuModel = detectCpuModel();

  if (m_osName == nextOsName &&
      m_desktopEnvironment == nextDesktopEnvironment &&
      m_kernelVersion == nextKernelVersion && m_cpuModel == nextCpuModel) {
    return;
  }

  m_osName = nextOsName;
  m_desktopEnvironment = nextDesktopEnvironment;
  m_kernelVersion = nextKernelVersion;
  m_cpuModel = nextCpuModel;
  emit infoChanged();
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
  utsname name {};
  if (uname(&name) == 0) {
    return QString::fromLocal8Bit(name.release);
  }
#endif
  return QSysInfo::kernelVersion();
}

QString SystemInfoProvider::detectCpuModel() const {
#if defined(Q_OS_LINUX)
  QFile cpuInfo(QStringLiteral("/proc/cpuinfo"));
  if (cpuInfo.open(QIODevice::ReadOnly | QIODevice::Text)) {
    QTextStream stream(&cpuInfo);
    while (!stream.atEnd()) {
      const QString line = stream.readLine();
      if (line.startsWith(QStringLiteral("model name"))) {
        const int separatorIndex = line.indexOf(QLatin1Char(':'));
        if (separatorIndex >= 0) {
          return line.mid(separatorIndex + 1).trimmed();
        }
      }
    }
  }
#elif defined(Q_OS_MACOS)
  CommandRunner runner;
  const auto result =
      runner.run(QStringLiteral("sysctl"),
                 {QStringLiteral("-n"), QStringLiteral("machdep.cpu.brand_string")});
  if (result.success()) {
    const QString value = result.stdout.trimmed();
    if (!value.isEmpty()) {
      return value;
    }
  }
#endif

  const QString architecture = QSysInfo::currentCpuArchitecture();
  return architecture.isEmpty() ? QStringLiteral("Unknown CPU") : architecture;
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
    const QString trimmed = part.trimmed();
    if (trimmed.isEmpty()) {
      continue;
    }

    if (trimmed.compare(QStringLiteral("KDE"), Qt::CaseInsensitive) == 0) {
      normalizedParts << QStringLiteral("KDE Plasma");
    } else if (trimmed.compare(QStringLiteral("GNOME"), Qt::CaseInsensitive) == 0) {
      normalizedParts << QStringLiteral("GNOME");
    } else {
      normalizedParts << trimmed;
    }
  }

  return normalizedParts.join(QStringLiteral(" / "));
}
