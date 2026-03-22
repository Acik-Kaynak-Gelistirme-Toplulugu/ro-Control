#include "updater.h"
#include "detector.h"
#include "system/commandrunner.h"
#include "system/sessionutil.h"
#include "versionparser.h"

#include <QMetaObject>
#include <QPointer>
#include <QStandardPaths>
#include <QThread>
#include <QtGlobal>

namespace {

const QStringList kVersionLockedDriverPackages = {
    QStringLiteral("akmod-nvidia"),
    QStringLiteral("xorg-x11-drv-nvidia"),
    QStringLiteral("xorg-x11-drv-nvidia-libs"),
    QStringLiteral("xorg-x11-drv-nvidia-cuda"),
    QStringLiteral("xorg-x11-drv-nvidia-cuda-libs"),
};

const QStringList kFloatingDriverPackages = {
    QStringLiteral("nvidia-modprobe"),
    QStringLiteral("nvidia-persistenced"),
    QStringLiteral("nvidia-settings"),
};

QString commandError(const CommandRunner::Result &result,
                     const QString &fallback) {
  const QString stderrText = result.stderr.trimmed();
  const QString stdoutText = result.stdout.trimmed();

  if (!stderrText.isEmpty()) {
    return stderrText;
  }

  if (!stdoutText.isEmpty()) {
    return stdoutText;
  }

  return fallback;
}

struct UpdateStatusSnapshot {
  QString currentVersion;
  QString latestVersion;
  QStringList availableVersions;
  bool updateAvailable = false;
  QString message;
};



UpdateStatusSnapshot collectUpdateStatus() {
  UpdateStatusSnapshot snapshot;
  NvidiaDetector detector;
  snapshot.currentVersion = detector.installedDriverVersion();

  if (QStandardPaths::findExecutable(QStringLiteral("dnf")).isEmpty()) {
    snapshot.message = NvidiaUpdater::tr("dnf not found.");
    return snapshot;
  }

  CommandRunner runner;
  const auto listResult =
      runner.run(QStringLiteral("dnf"),
                 {QStringLiteral("list"), QStringLiteral("--showduplicates"),
                  QStringLiteral("akmod-nvidia")});

  if (listResult.success()) {
    snapshot.availableVersions =
        NvidiaVersionParser::parseAvailablePackageVersions(
            listResult.stdout, QStringLiteral("akmod-nvidia"));
  }

  if (snapshot.currentVersion.isEmpty()) {
    snapshot.message = NvidiaUpdater::tr("No installed NVIDIA driver found.");
    return snapshot;
  }

  const auto checkResult =
      runner.run(QStringLiteral("dnf"), {QStringLiteral("check-update"),
                                         QStringLiteral("akmod-nvidia")});

  if (checkResult.exitCode == 100) {
    snapshot.latestVersion = NvidiaVersionParser::parseCheckUpdateVersion(
        checkResult.stdout, QStringLiteral("akmod-nvidia"));
    snapshot.updateAvailable = true;
    snapshot.message =
        snapshot.latestVersion.isEmpty()
            ? NvidiaUpdater::tr("Update found (version details unavailable).")
            : NvidiaUpdater::tr("Update found: %1")
                  .arg(snapshot.latestVersion);
  } else if (checkResult.exitCode == 0) {
    snapshot.message = NvidiaUpdater::tr("Driver is up to date. No new version found.");
  } else {
    snapshot.message = NvidiaUpdater::tr("Update check failed: %1")
                           .arg(checkResult.stderr.trimmed().isEmpty()
                                    ? checkResult.stdout.trimmed()
                                    : checkResult.stderr.trimmed());
  }

  return snapshot;
}

} // namespace

NvidiaUpdater::NvidiaUpdater(QObject *parent) : QObject(parent) {}

void NvidiaUpdater::setBusy(bool busy) {
  if (m_busy == busy) {
    return;
  }

  m_busy = busy;
  emit busyChanged();
}

void NvidiaUpdater::runAsyncTask(const std::function<void()> &task) {
  if (m_busy) {
    emit progressMessage(
        tr("Another driver operation is already running."));
    return;
  }

  setBusy(true);

  QThread *thread = QThread::create(task);
  connect(thread, &QThread::finished, this, [this, thread]() {
    setBusy(false);
    thread->deleteLater();
  });
  thread->start();
}

void NvidiaUpdater::setLatestVersion(const QString &version) {
  if (m_latestVersion == version) {
    return;
  }

  m_latestVersion = version;
  emit latestVersionChanged();
}

void NvidiaUpdater::setAvailableVersions(const QStringList &versions) {
  if (m_availableVersions == versions) {
    return;
  }

  m_availableVersions = versions;
  emit availableVersionsChanged();
}

QString NvidiaUpdater::detectSessionType() const {
  return SessionUtil::detectSessionType();
}

QStringList
NvidiaUpdater::buildDriverTargets(const QString &version,
                                  const QString &sessionType) const {
  Q_UNUSED(sessionType);
  QStringList targets;
  targets << NvidiaVersionParser::buildVersionedPackageSpecs(
      kVersionLockedDriverPackages, version);
  targets << kFloatingDriverPackages;

  return targets;
}

bool NvidiaUpdater::finalizeDriverChange(CommandRunner &runner,
                                         const QString &sessionType,
                                         QString *errorMessage) {
  auto result =
      runner.runAsRoot(QStringLiteral("akmods"), {QStringLiteral("--force")});
  if (!result.success()) {
    if (errorMessage != nullptr) {
      *errorMessage = tr("Kernel module build failed: ") +
                      commandError(result, tr("unknown error"));
    }
    return false;
  }

  if (sessionType == QStringLiteral("wayland")) {
    emit progressMessage(
        tr("Wayland detected: applying nvidia-drm.modeset=1..."));
    result = runner.runAsRoot(QStringLiteral("grubby"),
                              {QStringLiteral("--update-kernel=ALL"),
                               QStringLiteral("--args=nvidia-drm.modeset=1")});
    if (!result.success()) {
      if (errorMessage != nullptr) {
        *errorMessage =
            tr("Failed to update the Wayland kernel parameter: ") +
            commandError(result, tr("unknown error"));
      }
      return false;
    }
  }

  return true;
}

void NvidiaUpdater::refreshAvailableVersions() {
  QPointer<NvidiaUpdater> guard(this);
  runAsyncTask([guard]() {
    if (!guard) {
      return;
    }

    UpdateStatusSnapshot snapshot = collectUpdateStatus();
    QMetaObject::invokeMethod(
        guard,
        [guard, snapshot]() {
          if (!guard) {
            return;
          }

          guard->setAvailableVersions(snapshot.availableVersions);
          emit guard->progressMessage(
              snapshot.availableVersions.isEmpty()
                  ? guard->tr("No available versions found.")
                  : guard->tr("Available versions: %1")
                        .arg(snapshot.availableVersions.size()));
        },
        Qt::QueuedConnection);
  });
}

void NvidiaUpdater::checkForUpdate() {
  // TR: Her kontrol denemesinde UI'ye gorunur bir baslangic mesaji gonder.
  // EN: Always emit a visible start message for each check request.
  emit progressMessage(tr("Starting update check..."));

  QPointer<NvidiaUpdater> guard(this);
  runAsyncTask([guard]() {
    if (!guard) {
      return;
    }

    const UpdateStatusSnapshot snapshot = collectUpdateStatus();
    QMetaObject::invokeMethod(
        guard,
        [guard, snapshot]() {
          if (!guard) {
            return;
          }

          if (guard->m_currentVersion != snapshot.currentVersion) {
            guard->m_currentVersion = snapshot.currentVersion;
            emit guard->currentVersionChanged();
          }

          if (guard->m_updateAvailable != snapshot.updateAvailable) {
            guard->m_updateAvailable = snapshot.updateAvailable;
            emit guard->updateAvailableChanged();
          }

          guard->setLatestVersion(snapshot.latestVersion);
          guard->setAvailableVersions(snapshot.availableVersions);
          emit guard->progressMessage(snapshot.message);
        },
        Qt::QueuedConnection);
  });
}

void NvidiaUpdater::applyUpdate() { applyVersion(QString()); }

void NvidiaUpdater::applyVersion(const QString &version) {
  const QString trimmedVersion = version.trimmed();
  const QStringList knownVersions = m_availableVersions;
  QPointer<NvidiaUpdater> guard(this);

  runAsyncTask([guard, trimmedVersion, knownVersions]() {
    if (!guard) {
      return;
    }

    CommandRunner runner;
    QObject::connect(&runner, &CommandRunner::outputLine, guard,
                     [guard](const QString &message) {
                       if (!guard) {
                         return;
                       }
                       QMetaObject::invokeMethod(
                           guard,
                           [guard, message]() {
                             if (guard) {
                               emit guard->progressMessage(message);
                             }
                           },
                           Qt::QueuedConnection);
                     });

    if (QStandardPaths::findExecutable(QStringLiteral("dnf")).isEmpty()) {
      QMetaObject::invokeMethod(
          guard,
          [guard]() {
            if (guard) {
              emit guard->updateFinished(false,
                                         guard->tr("dnf not found."));
            }
          },
          Qt::QueuedConnection);
      return;
    }

    NvidiaDetector detector;
    const QString installedVersion = detector.installedDriverVersion();
    const QString sessionType = SessionUtil::detectSessionType();

    if (!trimmedVersion.isEmpty() && !knownVersions.contains(trimmedVersion)) {
      QMetaObject::invokeMethod(
          guard,
          [guard]() {
            if (guard) {
              emit guard->updateFinished(
                  false,
                  guard->tr("Selected version not found in the repository."));
            }
          },
          Qt::QueuedConnection);
      return;
    }

    QMetaObject::invokeMethod(
        guard,
        [guard, trimmedVersion]() {
          if (!guard) {
            return;
          }

          emit guard->progressMessage(
              trimmedVersion.isEmpty()
                  ? guard->tr(
                        "Updating NVIDIA driver to the latest version...")
                  : guard->tr(
                        "Switching NVIDIA driver to selected version: %1")
                        .arg(trimmedVersion));
        },
        Qt::QueuedConnection);

    const QStringList packageTargets =
        guard->buildDriverTargets(trimmedVersion, sessionType);
    auto args = QStringList{
        trimmedVersion.isEmpty()
            ? (installedVersion.isEmpty() ? QStringLiteral("install")
                                          : QStringLiteral("update"))
            : (installedVersion.isEmpty() ? QStringLiteral("install")
                                          : QStringLiteral("distro-sync")),
        QStringLiteral("-y"), QStringLiteral("--allowerasing")};
    args << packageTargets;

    auto result = runner.runAsRoot(QStringLiteral("dnf"), args);
    if (!result.success()) {
      const QString error =
          guard->tr("Update failed: ") +
          commandError(result, guard->tr("unknown error"));
      QMetaObject::invokeMethod(
          guard,
          [guard, error]() {
            if (guard) {
              emit guard->updateFinished(false, error);
            }
          },
          Qt::QueuedConnection);
      return;
    }

    QMetaObject::invokeMethod(
        guard,
        [guard]() {
          if (guard) {
            emit guard->progressMessage(
                guard->tr("Rebuilding kernel module..."));
          }
        },
        Qt::QueuedConnection);

    QString finalizeError;
    if (!guard->finalizeDriverChange(runner, sessionType, &finalizeError)) {
      QMetaObject::invokeMethod(
          guard,
          [guard, finalizeError]() {
            if (guard) {
              emit guard->updateFinished(false, finalizeError);
            }
          },
          Qt::QueuedConnection);
      return;
    }

    const UpdateStatusSnapshot snapshot = collectUpdateStatus();
    const QString successMessage =
        trimmedVersion.isEmpty()
            ? (installedVersion.isEmpty()
                   ? guard->tr("Latest version installed successfully. "
                               "Please restart the system.")
                   : guard->tr("Driver updated successfully. "
                               "Please restart the system."))
            : guard->tr(
                  "Selected version applied successfully. "
                  "Please restart the system.");

    QMetaObject::invokeMethod(
        guard,
        [guard, snapshot, successMessage]() {
          if (!guard) {
            return;
          }

          if (guard->m_currentVersion != snapshot.currentVersion) {
            guard->m_currentVersion = snapshot.currentVersion;
            emit guard->currentVersionChanged();
          }
          if (guard->m_updateAvailable != snapshot.updateAvailable) {
            guard->m_updateAvailable = snapshot.updateAvailable;
            emit guard->updateAvailableChanged();
          }
          guard->setLatestVersion(snapshot.latestVersion);
          guard->setAvailableVersions(snapshot.availableVersions);
          emit guard->progressMessage(snapshot.message);
          emit guard->updateFinished(true, successMessage);
        },
        Qt::QueuedConnection);
  });
}
