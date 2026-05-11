#include "installer.h"

#include "detector.h"
#include "system/capabilityprobe.h"
#include "system/commandrunner.h"
#include "system/sessionutil.h"

#include <QMetaObject>
#include <QPointer>
#include <QThread>
#include <QtGlobal>

namespace {

const QStringList kCommonNvidiaUserspacePackages = {
    QStringLiteral("nvidia-modprobe"),
    QStringLiteral("nvidia-persistenced"),
    QStringLiteral("nvidia-settings"),
};

const QStringList kOpenSourceNvidiaUserspacePackages = {
    QStringLiteral("mesa-dri-drivers"),
    QStringLiteral("mesa-vulkan-drivers"),
};

const QStringList kKernelPackageCleanupTargets = {
    QStringLiteral("akmod-nvidia"),
    QStringLiteral("akmod-nvidia-open"),
};

const QStringList kNvidiaKernelModules = {
    QStringLiteral("nvidia"),
    QStringLiteral("nvidia_modeset"),
    QStringLiteral("nvidia_uvm"),
    QStringLiteral("nvidia_drm"),
};

QString commandError(const CommandRunner::Result &result,
                     const QString &fallback = QString()) {
  const QString stderrText = result.stderr.trimmed();
  if (!stderrText.isEmpty()) {
    return stderrText;
  }

  const QString stdoutText = result.stdout.trimmed();
  if (!stdoutText.isEmpty()) {
    return stdoutText;
  }

  return fallback;
}

bool commandCanceled(const CommandRunner::Result &result) {
  return result.exitCode == -3;
}

QString missingNvidiaHardwareMessage() {
  NvidiaDetector detector;
  if (detector.hasNvidiaGpu() || detector.isDriverInstalled()) {
    return {};
  }

  return NvidiaInstaller::tr(
      "No NVIDIA GPU or installed NVIDIA driver was detected. In a virtual "
      "machine, attach or passthrough an NVIDIA GPU before starting driver "
      "installation.");
}

QString blockedDriverSwitchMessage(const QString &targetSource) {
  NvidiaDetector detector;
  const auto info = detector.detect();

  if (targetSource == QStringLiteral("closed-source") &&
      info.openSourceDriverInstalled) {
    return NvidiaInstaller::tr(
        "Open-source driver stack detected. Run Deep Clean before installing "
        "the closed-source driver.");
  }
  if (targetSource == QStringLiteral("open-source") &&
      info.closedSourceDriverInstalled) {
    return NvidiaInstaller::tr(
        "Closed-source driver stack detected. Run Deep Clean before installing "
        "the open-source driver.");
  }

  return {};
}

QStringList buildDriverInstallTargets(const QString &kernelPackageName,
                                      const QString &) {
  QStringList packages{kernelPackageName};
  packages << kCommonNvidiaUserspacePackages;
  return packages;
}

QStringList buildOpenSourceDriverInstallTargets(const QString &) {
  QStringList packages{QStringLiteral("akmod-nvidia-open")};
  packages << kCommonNvidiaUserspacePackages;
  packages << kOpenSourceNvidiaUserspacePackages;
  return packages;
}

QString quotedList(const QStringList &values) {
  QStringList quoted;
  quoted.reserve(values.size());
  for (const QString &value : values) {
    quoted << QStringLiteral("`%1`").arg(value);
  }
  return quoted.join(QStringLiteral(", "));
}

QList<CommandRunner::RootCommand>
buildSessionSpecificRootCommands(const QString &sessionType) {
  Q_UNUSED(sessionType);
  QList<CommandRunner::RootCommand> commands;
  commands.append({QStringLiteral("dracut"),
                   {QStringLiteral("--force"), QStringLiteral("--add-drivers"),
                    kNvidiaKernelModules.join(QLatin1Char(' '))}});

  commands.append({QStringLiteral("dnf"),
                   {QStringLiteral("install"), QStringLiteral("-y"),
                    QStringLiteral("egl-wayland")}});
  commands.append({QStringLiteral("grubby"),
                   {QStringLiteral("--update-kernel=ALL"),
                    QStringLiteral("--args=nvidia-drm.modeset=1 "
                                   "nvidia-drm.fbdev=1")}});

  return commands;
}

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
  QObject::connect(
      &runner, &CommandRunner::outputLine, guard,
      [guard](const QString &message) { emitProgressAsync(guard, message); });

  QObject::connect(
      &runner, &CommandRunner::errorLine, guard,
      [guard](const QString &message) { emitProgressAsync(guard, message); });

  QObject::connect(
      &runner, &CommandRunner::commandStarted, guard,
      [guard](const QString &program, const QStringList &args, int attempt) {
        QStringList visibleArgs = args;
        bool privilegedBatch = false;
        if (!visibleArgs.isEmpty() &&
            visibleArgs.constFirst().contains(
                QStringLiteral("ro-control-helper"))) {
          visibleArgs.removeFirst();
          privilegedBatch =
              !visibleArgs.isEmpty() &&
              visibleArgs.constFirst() == QStringLiteral("--batch");
        }

        if (program == QStringLiteral("pkexec") && privilegedBatch) {
          emitProgressAsync(
              guard, NvidiaInstaller::tr(
                         "Starting privileged installation batch (attempt %1). "
                         "The exact commands and package manager output will "
                         "appear below.")
                         .arg(attempt));
          return;
        }

        const QString commandLine = QStringLiteral("$ %1 %2").arg(
            program, visibleArgs.join(QLatin1Char(' ')).trimmed());
        emitProgressAsync(
            guard, NvidiaInstaller::tr("Starting command (attempt %1): %2")
                       .arg(attempt)
                       .arg(commandLine.trimmed()));
      });

  QObject::connect(
      &runner, &CommandRunner::commandFinished, guard,
      [guard](const QString &program, int exitCode, int attempt,
              int elapsedMs) {
        if (program == QStringLiteral("pkexec")) {
          return;
        }

        emitProgressAsync(
            guard, NvidiaInstaller::tr(
                       "Command finished (attempt %1, exit %2, %3 ms): %4")
                       .arg(attempt)
                       .arg(exitCode)
                       .arg(elapsedMs)
                       .arg(program));
      });
}

} // namespace

NvidiaInstaller::NvidiaInstaller(QObject *parent) : QObject(parent) {
  m_cancelRequested = std::make_shared<std::atomic_bool>(false);
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

  m_cancelRequested->store(false, std::memory_order_relaxed);
  setBusy(true);

  QThread *thread = QThread::create(task);
  connect(thread, &QThread::finished, this, [this, thread]() {
    setBusy(false);
    thread->deleteLater();
  });
  thread->start();
}

void NvidiaInstaller::cancelOperation() {
  if (!m_busy) {
    emit progressMessage(tr("No driver operation is running."));
    return;
  }

  m_cancelRequested->store(true, std::memory_order_relaxed);
  emit progressMessage(
      tr("Cancel requested. Waiting for the active command to stop safely..."));
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
  setProprietaryAgreement(
      true,
      tr("Closed-source NVIDIA driver license summary\n\n"
         "This closed-source NVIDIA driver is provided under NVIDIA's driver "
         "software license. By accepting, you confirm that you have authority "
         "to accept the license terms and that ro-Control may start installing "
         "the closed-source driver packages.\n\n"
         "Important points:\n"
         "- The software is licensed, not sold.\n"
         "- The license is limited, revocable, non-transferable, and "
         "non-sublicensable except where NVIDIA explicitly allows it.\n"
         "- You may install and use copies of the driver software only as "
         "permitted by the license and applicable law.\n"
         "- NVIDIA does not grant extra third-party patent, codec, standards, "
         "or content rights through this driver license.\n"
         "- Open-source components, if any, remain governed by their own "
         "separate open-source licenses.\n"
         "- If you do not accept the NVIDIA license terms, do not install or "
         "use the closed-source driver.\n\n"
         "Choose Accept to continue with the closed-source installation, or "
         "Reject to cancel."));
}

void NvidiaInstaller::install() { installProprietary(false); }

void NvidiaInstaller::installProprietary(bool agreementAccepted) {
  refreshProprietaryAgreement();

  const QString hardwareMessage = missingNvidiaHardwareMessage();
  if (!hardwareMessage.isEmpty()) {
    emit installFinished(false, hardwareMessage);
    return;
  }

  const QString switchMessage =
      blockedDriverSwitchMessage(QStringLiteral("closed-source"));
  if (!switchMessage.isEmpty()) {
    emit installFinished(false, switchMessage);
    return;
  }

  if (m_proprietaryAgreementRequired && !agreementAccepted) {
    emit installFinished(
        false, tr("NVIDIA license review confirmation is required before "
                  "installation."));
    return;
  }

  const QString architectureSupportMessage =
      CapabilityProbe::roAsdNvidiaDriverFlowSupportMessage();
  if (!architectureSupportMessage.isEmpty()) {
    emit installFinished(false, architectureSupportMessage);
    return;
  }

  QPointer<NvidiaInstaller> guard(this);
  runAsyncTask([guard]() {
    if (!guard) {
      return;
    }

    CommandRunner runner;
    attachRunnerLogging(runner, guard);
    CommandRunner::RunOptions runOptions;
    runOptions.cancelRequested = guard->m_cancelRequested;

    emitProgressAsync(
        guard, NvidiaInstaller::tr("Checking RPM Fusion repositories..."));

    CommandRunner rpmRunner;
    const auto platformVersionResult =
        rpmRunner.run(QStringLiteral("rpm"),
                      {QStringLiteral("-E"), QStringLiteral("%fedora")});

    const QString platformVersion = platformVersionResult.stdout.trimmed();
    if (platformVersion.isEmpty()) {
      QMetaObject::invokeMethod(
          guard,
          [guard]() {
            if (guard) {
              emit guard->installFinished(
                  false, NvidiaInstaller::tr(
                             "Platform version could not be detected."));
            }
          },
          Qt::QueuedConnection);
      return;
    }

    const SessionUtil::SessionInfo sessionInfo =
        SessionUtil::detectSessionInfo();
    const QString sessionType = sessionInfo.type.trimmed().toLower();
    if (sessionType != QStringLiteral("wayland")) {
      QMetaObject::invokeMethod(
          guard,
          [guard]() {
            if (guard) {
              emit guard->installFinished(
                  false, NvidiaInstaller::tr(
                             "The active display session could not be detected "
                             "as Wayland. ro-Control supports Wayland driver "
                             "setup only."));
            }
          },
          Qt::QueuedConnection);
      return;
    }

    emitProgressAsync(
        guard,
        NvidiaInstaller::tr(
            "Installing the closed-source NVIDIA driver with one privileged "
            "authorization..."));
    const QString installPackagesMessage =
        NvidiaInstaller::tr("Closed-source install packages for %1: %2")
            .arg(NvidiaInstaller::tr("Wayland"))
            .arg(quotedList(buildDriverInstallTargets(
                QStringLiteral("akmod-nvidia"), sessionType)));
    emitProgressAsync(guard, installPackagesMessage);

    QStringList installArgs{QStringLiteral("install"), QStringLiteral("-y"),
                            QStringLiteral("--refresh"),
                            QStringLiteral("--best"),
                            QStringLiteral("--allowerasing")};
    installArgs << buildDriverInstallTargets(QStringLiteral("akmod-nvidia"),
                                             sessionType);

    QList<CommandRunner::RootCommand> rootCommands;
    rootCommands.append(
        {QStringLiteral("dnf"),
         {QStringLiteral("install"), QStringLiteral("-y"),
          QStringLiteral("https://mirrors.rpmfusion.org/free/fedora/"
                         "rpmfusion-free-release-%1.noarch.rpm")
              .arg(platformVersion),
          QStringLiteral("https://mirrors.rpmfusion.org/nonfree/fedora/"
                         "rpmfusion-nonfree-release-%1.noarch.rpm")
              .arg(platformVersion)}});
    rootCommands.append({QStringLiteral("dnf"), installArgs});
    rootCommands.append(
        {QStringLiteral("akmods"), {QStringLiteral("--force")}});
    rootCommands.append(buildSessionSpecificRootCommands(sessionType));

    const QString detectedSessionMessage =
        NvidiaInstaller::tr("Detected %1 session via %2.")
            .arg(sessionType == QStringLiteral("wayland")
                     ? NvidiaInstaller::tr("Wayland")
                     : sessionType,
                 sessionInfo.source.isEmpty()
                     ? NvidiaInstaller::tr("session probe")
                     : sessionInfo.source);
    emitProgressAsync(guard, detectedSessionMessage);

    auto result = runner.runAsRootBatch(rootCommands, runOptions);
    if (!result.success()) {
      const QString error =
          commandCanceled(result)
              ? NvidiaInstaller::tr("Operation canceled by user.")
              : NvidiaInstaller::tr("Installation failed: ") +
                    commandError(result);
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

    QMetaObject::invokeMethod(
        guard,
        [guard]() {
          if (guard) {
            emit guard->installFinished(
                true, NvidiaInstaller::tr(
                          "The closed-source NVIDIA driver was installed "
                          "successfully. Please restart the system."));
          }
        },
        Qt::QueuedConnection);
  });
}

void NvidiaInstaller::installOpenSource() {
  const QString hardwareMessage = missingNvidiaHardwareMessage();
  if (!hardwareMessage.isEmpty()) {
    emit installFinished(false, hardwareMessage);
    return;
  }

  const QString switchMessage =
      blockedDriverSwitchMessage(QStringLiteral("open-source"));
  if (!switchMessage.isEmpty()) {
    emit installFinished(false, switchMessage);
    return;
  }

  const QString architectureSupportMessage =
      CapabilityProbe::roAsdNvidiaDriverFlowSupportMessage();
  if (!architectureSupportMessage.isEmpty()) {
    emit installFinished(false, architectureSupportMessage);
    return;
  }

  QPointer<NvidiaInstaller> guard(this);
  runAsyncTask([guard]() {
    if (!guard) {
      return;
    }

    CommandRunner runner;
    attachRunnerLogging(runner, guard);
    CommandRunner::RunOptions runOptions;
    runOptions.cancelRequested = guard->m_cancelRequested;

    emitProgressAsync(
        guard, NvidiaInstaller::tr(
                   "Switching to the open-source NVIDIA driver stack..."));

    const SessionUtil::SessionInfo sessionInfo =
        SessionUtil::detectSessionInfo();
    const QString sessionType = sessionInfo.type.trimmed().toLower();
    if (sessionType != QStringLiteral("wayland")) {
      QMetaObject::invokeMethod(
          guard,
          [guard]() {
            if (guard) {
              emit guard->installFinished(
                  false, NvidiaInstaller::tr(
                             "The active display session could not be detected "
                             "as Wayland. ro-Control supports Wayland driver "
                             "setup only."));
            }
          },
          Qt::QueuedConnection);
      return;
    }

    emitProgressAsync(
        guard,
        NvidiaInstaller::tr("Open-source NVIDIA install packages: %1")
            .arg(quotedList(buildOpenSourceDriverInstallTargets(sessionType))));

    QStringList installArgs{QStringLiteral("install"), QStringLiteral("-y"),
                            QStringLiteral("--refresh"),
                            QStringLiteral("--best"),
                            QStringLiteral("--allowerasing")};
    installArgs << buildOpenSourceDriverInstallTargets(sessionType);

    QList<CommandRunner::RootCommand> rootCommands;
    rootCommands.append({QStringLiteral("dnf"), installArgs});
    rootCommands.append(
        {QStringLiteral("akmods"), {QStringLiteral("--force")}});
    rootCommands.append(buildSessionSpecificRootCommands(sessionType));

    const QString detectedSessionMessage =
        NvidiaInstaller::tr("Detected %1 session via %2.")
            .arg(sessionType == QStringLiteral("wayland")
                     ? NvidiaInstaller::tr("Wayland")
                     : sessionType,
                 sessionInfo.source.isEmpty()
                     ? NvidiaInstaller::tr("session probe")
                     : sessionInfo.source);
    emitProgressAsync(guard, detectedSessionMessage);

    auto result = runner.runAsRootBatch(rootCommands, runOptions);
    if (!result.success()) {
      const QString error =
          commandCanceled(result)
              ? NvidiaInstaller::tr("Operation canceled by user.")
              : NvidiaInstaller::tr(
                    "Open-source NVIDIA driver installation failed: ") +
                    commandError(result, NvidiaInstaller::tr("unknown error"));
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

    QMetaObject::invokeMethod(
        guard,
        [guard]() {
          if (guard) {
            emit guard->installFinished(
                true, NvidiaInstaller::tr(
                          "The open-source NVIDIA driver stack was "
                          "prepared successfully. Please restart the system."));
          }
        },
        Qt::QueuedConnection);
  });
}

void NvidiaInstaller::remove() {
  const QString architectureSupportMessage =
      CapabilityProbe::roAsdNvidiaDriverFlowSupportMessage();
  if (!architectureSupportMessage.isEmpty()) {
    emit removeFinished(false, architectureSupportMessage);
    return;
  }

  QPointer<NvidiaInstaller> guard(this);
  runAsyncTask([guard]() {
    if (!guard) {
      return;
    }

    CommandRunner runner;
    attachRunnerLogging(runner, guard);
    CommandRunner::RunOptions runOptions;
    runOptions.cancelRequested = guard->m_cancelRequested;

    emitProgressAsync(guard,
                      NvidiaInstaller::tr("Removing the NVIDIA driver..."));

    const auto result = runner.runAsRoot(
        QStringLiteral("dnf"),
        {QStringLiteral("remove"), QStringLiteral("-y"),
         QStringLiteral("akmod-nvidia"), QStringLiteral("akmod-nvidia-open")},
        runOptions);

    const bool success = result.success();
    const QString message =
        success ? NvidiaInstaller::tr("Driver removed successfully.")
                : (commandCanceled(result)
                       ? NvidiaInstaller::tr("Operation canceled by user.")
                       : NvidiaInstaller::tr("Removal failed: ") +
                             result.stderr.trimmed());
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
  const QString architectureSupportMessage =
      CapabilityProbe::roAsdNvidiaDriverFlowSupportMessage();
  if (!architectureSupportMessage.isEmpty()) {
    emit removeFinished(false, architectureSupportMessage);
    return;
  }

  QPointer<NvidiaInstaller> guard(this);
  runAsyncTask([guard]() {
    if (!guard) {
      return;
    }

    CommandRunner runner;
    attachRunnerLogging(runner, guard);
    CommandRunner::RunOptions runOptions;
    runOptions.cancelRequested = guard->m_cancelRequested;

    emitProgressAsync(
        guard, NvidiaInstaller::tr("Cleaning legacy driver leftovers..."));

    const auto removeResult =
        runner.runAsRoot(QStringLiteral("dnf"),
                         {QStringLiteral("remove"), QStringLiteral("-y"),
                          QStringLiteral("*nvidia*"), QStringLiteral("*akmod*"),
                          QStringLiteral("*nvidia-open*")},
                         runOptions);

    if (!removeResult.success()) {
      const QString error =
          commandCanceled(removeResult)
              ? NvidiaInstaller::tr("Operation canceled by user.")
              : NvidiaInstaller::tr("Deep clean failed: ") +
                    removeResult.stderr.trimmed();
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

    const auto cleanResult = runner.runAsRoot(
        QStringLiteral("dnf"), {QStringLiteral("clean"), QStringLiteral("all")},
        runOptions);
    if (!cleanResult.success()) {
      const QString error =
          commandCanceled(cleanResult)
              ? NvidiaInstaller::tr("Operation canceled by user.")
              : NvidiaInstaller::tr("DNF cache cleanup failed: ") +
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
            emit guard->progressMessage(
                NvidiaInstaller::tr("Deep clean completed."));
            emit guard->removeFinished(
                true, NvidiaInstaller::tr("Legacy NVIDIA cleanup completed."));
          }
        },
        Qt::QueuedConnection);
  });
}
