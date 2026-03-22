#include "installer.h"

#include "system/commandrunner.h"
#include "system/sessionutil.h"

#include <QMetaObject>
#include <QPointer>
#include <QThread>
#include <QtGlobal>

namespace {

void emitProgressAsync(const QPointer<NvidiaInstaller> &guard,
                       const QString &message) {
  QMetaObject::invokeMethod(
      guard,
      [guard, message]() {
        if (guard) {
          emit guard->progressMessage(message);
        }
      },
      Qt::QueuedConnection);
}

void attachRunnerLogging(CommandRunner &runner,
                         const QPointer<NvidiaInstaller> &guard) {
  QObject::connect(&runner, &CommandRunner::outputLine, guard,
                   [guard](const QString &message) {
                     emitProgressAsync(guard, message);
                   });

  QObject::connect(&runner, &CommandRunner::errorLine, guard,
                   [guard](const QString &message) {
                     emitProgressAsync(guard, message);
                   });

  QObject::connect(
      &runner, &CommandRunner::commandStarted, guard,
      [guard](const QString &program, const QStringList &args, int attempt) {
        QStringList visibleArgs = args;
        if (!visibleArgs.isEmpty() &&
            visibleArgs.constFirst().contains(QStringLiteral("ro-control-helper"))) {
          visibleArgs.removeFirst();
        }

        const QString commandLine =
            QStringLiteral("$ %1 %2")
                .arg(program, visibleArgs.join(QLatin1Char(' ')).trimmed());
        emitProgressAsync(
            guard, NvidiaInstaller::tr("Starting command (attempt %1): %2")
                       .arg(attempt)
                       .arg(commandLine.trimmed()));
      });

  QObject::connect(&runner, &CommandRunner::commandFinished, guard,
                   [guard](const QString &program, int exitCode, int attempt,
                           int elapsedMs) {
                     emitProgressAsync(
                         guard,
                         NvidiaInstaller::tr(
                             "Command finished (attempt %1, exit %2, %3 ms): %4")
                             .arg(attempt)
                             .arg(exitCode)
                             .arg(elapsedMs)
                             .arg(program));
                   });
}

} // namespace

NvidiaInstaller::NvidiaInstaller(QObject *parent) : QObject(parent) {
  refreshProprietaryAgreement();
}

void NvidiaInstaller::setBusy(bool busy) {
  if (m_busy == busy) {
    return;
  }

  m_busy = busy;
  emit busyChanged();
}

void NvidiaInstaller::runAsyncTask(const std::function<void()> &task) {
  if (m_busy) {
    emit progressMessage(tr("Another driver operation is already running."));
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

void NvidiaInstaller::setProprietaryAgreement(bool required,
                                              const QString &text) {
  if (m_proprietaryAgreementRequired == required &&
      m_proprietaryAgreementText == text) {
    return;
  }

  m_proprietaryAgreementRequired = required;
  m_proprietaryAgreementText = text;
  emit proprietaryAgreementChanged();
}

void NvidiaInstaller::refreshProprietaryAgreement() {
  CommandRunner runner;
  const auto info =
      runner.run(QStringLiteral("dnf"),
                 {QStringLiteral("info"), QStringLiteral("akmod-nvidia")});

  if (!info.success()) {
    setProprietaryAgreement(false, QString());
    return;
  }

  QString licenseLine;
  const QStringList lines = info.stdout.split(QLatin1Char('\n'));
  for (const QString &line : lines) {
    if (line.startsWith(QStringLiteral("License"), Qt::CaseInsensitive)) {
      licenseLine = line;
      break;
    }
  }

  const QString lowered = licenseLine.toLower();
  const bool requiresAgreement =
      lowered.contains(QStringLiteral("eula")) ||
      lowered.contains(QStringLiteral("proprietary")) ||
      lowered.contains(QStringLiteral("nvidia"));

  if (requiresAgreement) {
    setProprietaryAgreement(
        true, tr("You must accept the NVIDIA proprietary driver license terms "
                 "before installation. Detected license: %1")
                  .arg(licenseLine.isEmpty() ? tr("Unknown") : licenseLine));
    return;
  }

  setProprietaryAgreement(false, QString());
}

void NvidiaInstaller::install() { installProprietary(false); }

void NvidiaInstaller::installProprietary(bool agreementAccepted) {
  refreshProprietaryAgreement();

  if (m_proprietaryAgreementRequired && !agreementAccepted) {
    emit installFinished(false,
                         tr("License agreement acceptance is required before "
                            "installation."));
    return;
  }

  QPointer<NvidiaInstaller> guard(this);
  runAsyncTask([guard]() {
    if (!guard) {
      return;
    }

    CommandRunner runner;
    attachRunnerLogging(runner, guard);

    emitProgressAsync(guard,
                      NvidiaInstaller::tr("Checking RPM Fusion repositories..."));

    CommandRunner rpmRunner;
    const auto fedoraResult =
        rpmRunner.run(QStringLiteral("rpm"),
                      {QStringLiteral("-E"), QStringLiteral("%fedora")});

    const QString fedoraVersion = fedoraResult.stdout.trimmed();
    if (fedoraVersion.isEmpty()) {
      QMetaObject::invokeMethod(
          guard,
          [guard]() {
            if (guard) {
              emit guard->installFinished(
                  false, NvidiaInstaller::tr("Platform version could not be detected."));
            }
          },
          Qt::QueuedConnection);
      return;
    }

    auto result = runner.runAsRoot(
        QStringLiteral("dnf"),
        {QStringLiteral("install"), QStringLiteral("-y"),
         QStringLiteral("https://mirrors.rpmfusion.org/free/fedora/"
                        "rpmfusion-free-release-%1.noarch.rpm")
             .arg(fedoraVersion),
         QStringLiteral("https://mirrors.rpmfusion.org/nonfree/fedora/"
                        "rpmfusion-nonfree-release-%1.noarch.rpm")
             .arg(fedoraVersion)});

    if (!result.success()) {
      const QString error =
          NvidiaInstaller::tr("Failed to enable RPM Fusion repositories: ") +
          result.stderr.trimmed();
      QMetaObject::invokeMethod(
          guard,
          [guard, error]() {
            if (guard) {
              emit guard->installFinished(false, error);
            }
          },
          Qt::QueuedConnection);
      return;
    }

    emitProgressAsync(
        guard, NvidiaInstaller::tr(
                   "Installing the proprietary NVIDIA driver (akmod-nvidia)..."));

    result = runner.runAsRoot(QStringLiteral("dnf"),
                              {QStringLiteral("install"), QStringLiteral("-y"),
                               QStringLiteral("akmod-nvidia")});

    if (!result.success()) {
      const QString error =
          NvidiaInstaller::tr("Installation failed: ") + result.stderr.trimmed();
      QMetaObject::invokeMethod(
          guard,
          [guard, error]() {
            if (guard) {
              emit guard->installFinished(false, error);
            }
          },
          Qt::QueuedConnection);
      return;
    }

    emitProgressAsync(
        guard,
        NvidiaInstaller::tr("Building the kernel module (akmods --force)..."));
    runner.runAsRoot(QStringLiteral("akmods"), {QStringLiteral("--force")});

    const QString sessionType = SessionUtil::detectSessionType();
    QString sessionError;
    if (!guard->applySessionSpecificSetup(runner, sessionType, &sessionError)) {
      QMetaObject::invokeMethod(
          guard,
          [guard, sessionError]() {
            if (guard) {
              emit guard->installFinished(false, sessionError);
            }
          },
          Qt::QueuedConnection);
      return;
    }

    QMetaObject::invokeMethod(
        guard,
        [guard]() {
          if (guard) {
            emit guard->installFinished(
                true,
                NvidiaInstaller::tr("The proprietary NVIDIA driver was installed "
                          "successfully. Please restart the system."));
          }
        },
        Qt::QueuedConnection);
  });
}

void NvidiaInstaller::installOpenSource() {
  QPointer<NvidiaInstaller> guard(this);
  runAsyncTask([guard]() {
    if (!guard) {
      return;
    }

    CommandRunner runner;
    attachRunnerLogging(runner, guard);

    emitProgressAsync(guard,
                      NvidiaInstaller::tr("Switching to the open-source driver..."));

    auto result = runner.runAsRoot(
        QStringLiteral("dnf"),
        {QStringLiteral("remove"), QStringLiteral("-y"),
         QStringLiteral("akmod-nvidia"),
         QStringLiteral("xorg-x11-drv-nvidia*")});

    if (!result.success()) {
      const QString error =
          NvidiaInstaller::tr("Failed to remove proprietary packages: ") +
          result.stderr.trimmed();
      QMetaObject::invokeMethod(
          guard,
          [guard, error]() {
            if (guard) {
              emit guard->installFinished(false, error);
            }
          },
          Qt::QueuedConnection);
      return;
    }

    result = runner.runAsRoot(QStringLiteral("dnf"),
                              {QStringLiteral("install"), QStringLiteral("-y"),
                               QStringLiteral("xorg-x11-drv-nouveau"),
                               QStringLiteral("mesa-dri-drivers")});

    if (!result.success()) {
      const QString error =
          NvidiaInstaller::tr("Open-source driver installation failed: ") +
          result.stderr.trimmed();
      QMetaObject::invokeMethod(
          guard,
          [guard, error]() {
            if (guard) {
              emit guard->installFinished(false, error);
            }
          },
          Qt::QueuedConnection);
      return;
    }

    runner.runAsRoot(QStringLiteral("dracut"), {QStringLiteral("--force")});

    QMetaObject::invokeMethod(
        guard,
        [guard]() {
          if (guard) {
            emit guard->installFinished(
                true,
                NvidiaInstaller::tr("The open-source driver (Nouveau) was installed. "
                          "Please restart the system."));
          }
        },
        Qt::QueuedConnection);
  });
}

void NvidiaInstaller::remove() {
  QPointer<NvidiaInstaller> guard(this);
  runAsyncTask([guard]() {
    if (!guard) {
      return;
    }

    CommandRunner runner;
    attachRunnerLogging(runner, guard);

    emitProgressAsync(guard,
                      NvidiaInstaller::tr("Removing the NVIDIA driver..."));

    const auto result = runner.runAsRoot(
        QStringLiteral("dnf"),
        {QStringLiteral("remove"), QStringLiteral("-y"),
         QStringLiteral("akmod-nvidia"),
         QStringLiteral("xorg-x11-drv-nvidia*")});

    const bool success = result.success();
    const QString message =
        success ? NvidiaInstaller::tr("Driver removed successfully.")
                : NvidiaInstaller::tr("Removal failed: ") + result.stderr.trimmed();
    QMetaObject::invokeMethod(
        guard,
        [guard, success, message]() {
          if (guard) {
            emit guard->removeFinished(success, message);
          }
        },
        Qt::QueuedConnection);
  });
}

void NvidiaInstaller::deepClean() {
  QPointer<NvidiaInstaller> guard(this);
  runAsyncTask([guard]() {
    if (!guard) {
      return;
    }

    CommandRunner runner;
    attachRunnerLogging(runner, guard);

    emitProgressAsync(guard,
                      NvidiaInstaller::tr("Cleaning legacy driver leftovers..."));

    const auto removeResult = runner.runAsRoot(
        QStringLiteral("dnf"),
        {QStringLiteral("remove"), QStringLiteral("-y"),
         QStringLiteral("*nvidia*"), QStringLiteral("*akmod*")});

    if (!removeResult.success()) {
      const QString error =
          NvidiaInstaller::tr("Deep clean failed: ") + removeResult.stderr.trimmed();
      QMetaObject::invokeMethod(
          guard,
          [guard, error]() {
            if (guard) {
              emit guard->removeFinished(false, error);
            }
          },
          Qt::QueuedConnection);
      return;
    }

    const auto cleanResult =
        runner.runAsRoot(QStringLiteral("dnf"),
                         {QStringLiteral("clean"), QStringLiteral("all")});
    if (!cleanResult.success()) {
      const QString error = NvidiaInstaller::tr("DNF cache cleanup failed: ") +
                            cleanResult.stderr.trimmed();
      QMetaObject::invokeMethod(
          guard,
          [guard, error]() {
            if (guard) {
              emit guard->removeFinished(false, error);
            }
          },
          Qt::QueuedConnection);
      return;
    }

    QMetaObject::invokeMethod(
        guard,
        [guard]() {
          if (guard) {
            emit guard->progressMessage(NvidiaInstaller::tr("Deep clean completed."));
            emit guard->removeFinished(
                true, NvidiaInstaller::tr("Legacy NVIDIA cleanup completed."));
          }
        },
        Qt::QueuedConnection);
  });
}



bool NvidiaInstaller::applySessionSpecificSetup(CommandRunner &runner,
                                                const QString &sessionType,
                                                QString *errorMessage) {
  if (sessionType == QStringLiteral("wayland")) {
    emit progressMessage(
        QStringLiteral("Wayland detected: applying nvidia-drm.modeset=1..."));

    const auto result =
        runner.runAsRoot(QStringLiteral("grubby"),
                         {QStringLiteral("--update-kernel=ALL"),
                          QStringLiteral("--args=nvidia-drm.modeset=1")});

    if (!result.success()) {
      if (errorMessage) {
        *errorMessage = tr("Failed to apply the Wayland kernel parameter: ") +
                        result.stderr;
      }
      return false;
    }
    return true;
  }

  if (sessionType == QStringLiteral("x11")) {
    emit progressMessage(
        tr("X11 detected: checking NVIDIA userspace packages..."));

    const auto result = runner.runAsRoot(
        QStringLiteral("dnf"), {QStringLiteral("install"), QStringLiteral("-y"),
                                QStringLiteral("xorg-x11-drv-nvidia")});

    if (!result.success()) {
      if (errorMessage) {
        *errorMessage =
            tr("Failed to install the X11 NVIDIA package: ") + result.stderr;
      }
      return false;
    }
  }

  return true;
}
