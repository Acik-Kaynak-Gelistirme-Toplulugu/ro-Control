#include <QApplication>
#include <QCoreApplication>
#include <QEventLoop>
#include <QIcon>
#include <QJsonDocument>
#include <QJsonObject>
#include <QLocale>
#include <QObject>
#include <QQmlApplicationEngine>
#include <QQuickWindow>
#include <QSGRendererInterface>
#include <QStringList>
#include <QTextStream>
#include <QTranslator>
#include <QVariant>

#include "backend/fan/fancontroller.h"
#include "backend/monitor/cpumonitor.h"
#include "backend/monitor/gpumonitor.h"
#include "backend/monitor/rammonitor.h"
#include "backend/nvidia/detector.h"
#include "backend/nvidia/installer.h"
#include "backend/nvidia/updater.h"
#include "backend/system/languagemanager.h"
#include "backend/system/systeminfoprovider.h"
#include "backend/system/uipreferencesmanager.h"
#include "cli/cli.h"

namespace {

struct CliExecutionResult {
  int exitCode = 0;
  QString stdoutText;
  QString stderrText;
};

CliExecutionResult executeCliCommand(const RoControlCli::ParsedCommand &command,
                                     const QString &applicationName,
                                     const QString &applicationVersion) {
  CliExecutionResult result;

  if (command.action == RoControlCli::CommandAction::PrintStatusText ||
      command.action == RoControlCli::CommandAction::PrintStatusJson ||
      command.action == RoControlCli::CommandAction::PrintDiagnosticsText ||
      command.action == RoControlCli::CommandAction::PrintDiagnosticsJson) {
    const auto snapshot =
        RoControlCli::collectDiagnostics(applicationName, applicationVersion);

    if (command.action == RoControlCli::CommandAction::PrintStatusJson) {
      result.stdoutText = QString::fromUtf8(
          QJsonDocument(RoControlCli::renderStatusJsonObject(snapshot))
              .toJson(QJsonDocument::Indented));
    } else if (command.action == RoControlCli::CommandAction::PrintStatusText) {
      result.stdoutText = RoControlCli::renderStatusText(snapshot);
    } else if (command.action ==
               RoControlCli::CommandAction::PrintDiagnosticsJson) {
      result.stdoutText = QString::fromUtf8(
          QJsonDocument(RoControlCli::renderDiagnosticsJsonObject(snapshot))
              .toJson(QJsonDocument::Indented));
    } else {
      result.stdoutText = RoControlCli::renderDiagnosticsText(snapshot);
    }

    return result;
  }

  if (command.action == RoControlCli::CommandAction::PrintFanStatusText ||
      command.action == RoControlCli::CommandAction::PrintFanStatusJson) {
    const auto snapshot =
        RoControlCli::collectDiagnostics(applicationName, applicationVersion);
    if (command.action == RoControlCli::CommandAction::PrintFanStatusJson) {
      QJsonObject obj;
      obj.insert(QStringLiteral("command"), QStringLiteral("fan-status"));
      obj.insert(QStringLiteral("supported"), snapshot.fanSupported);
      obj.insert(QStringLiteral("controlSupported"),
                 snapshot.fanControlSupported);
      obj.insert(QStringLiteral("capability"), snapshot.fanCapability);
      obj.insert(QStringLiteral("hardwareType"), snapshot.fanHardwareType);
      obj.insert(QStringLiteral("gpuFanSpeedPercent"),
                 snapshot.gpuFanSpeedPercent);
      obj.insert(QStringLiteral("fanRpm"), snapshot.fanRpm);
      obj.insert(QStringLiteral("mode"), snapshot.fanMode);
      obj.insert(QStringLiteral("targetFanSpeedPercent"),
                 snapshot.fanTargetSpeedPercent);
      obj.insert(QStringLiteral("safetyOverrideActive"),
                 snapshot.fanSafetyOverride);
      obj.insert(QStringLiteral("thermalThresholdC"),
                 snapshot.fanThermalThresholdC);
      obj.insert(QStringLiteral("gpuTemperatureC"), snapshot.gpuTemperatureC);
      result.stdoutText =
          QString::fromUtf8(QJsonDocument(obj).toJson(QJsonDocument::Indented));
    } else {
      result.stdoutText =
          QStringLiteral("fan_supported: %1\n"
                         "fan_control_supported: %2\n"
                         "fan_capability: %3\n"
                         "fan_hardware_type: %4\n"
                         "gpu_fan_speed_percent: %5%\n"
                         "fan_rpm: %6\n"
                         "fan_mode: %7\n"
                         "fan_target_speed_percent: %8%\n"
                         "gpu_temperature_c: %9 C\n"
                         "thermal_threshold_c: %10 C\n"
                         "safety_override: %11\n")
              .arg(snapshot.fanSupported ? QStringLiteral("yes")
                                         : QStringLiteral("no"))
              .arg(snapshot.fanControlSupported ? QStringLiteral("yes")
                                                : QStringLiteral("no"))
              .arg(snapshot.fanCapability.isEmpty()
                       ? QStringLiteral("unsupported")
                       : snapshot.fanCapability)
              .arg(snapshot.fanHardwareType.isEmpty()
                       ? QStringLiteral("None")
                       : snapshot.fanHardwareType)
              .arg(snapshot.gpuFanSpeedPercent)
              .arg(snapshot.fanRpm)
              .arg(snapshot.fanMode.isEmpty() ? QStringLiteral("auto")
                                              : snapshot.fanMode)
              .arg(snapshot.fanTargetSpeedPercent)
              .arg(snapshot.gpuTemperatureC)
              .arg(snapshot.fanThermalThresholdC)
              .arg(snapshot.fanSafetyOverride ? QStringLiteral("active")
                                              : QStringLiteral("inactive"));
    }
    return result;
  }

  if (command.action == RoControlCli::CommandAction::FanSetSpeed) {
    FanController fanController;
    fanController.stop();
    if (!fanController.controlSupported()) {
      result.stderrText = QStringLiteral(
          "Error: Fan control is unsupported or read-only on this hardware.\n");
      result.exitCode = 1;
      return result;
    }
    const int speed = command.payload.toInt();
    fanController.setFanMode(QStringLiteral("manual"));
    fanController.setManualFanSpeedPercent(speed);
    result.stdoutText =
        QStringLiteral("Fan speed set to %1% (manual mode).\n").arg(speed);
    result.exitCode = 0;
    return result;
  }

  if (command.action == RoControlCli::CommandAction::FanSetMode) {
    FanController fanController;
    fanController.stop();
    if (command.payload != QStringLiteral("auto") &&
        !fanController.controlSupported()) {
      result.stderrText = QStringLiteral(
          "Error: Fan control is unsupported or read-only on this hardware.\n");
      result.exitCode = 1;
      return result;
    }
    fanController.setFanMode(command.payload);
    result.stdoutText =
        QStringLiteral("Fan mode set to '%1'.\n").arg(command.payload);
    result.exitCode = 0;
    return result;
  }

  if (command.action == RoControlCli::CommandAction::FanReset) {
    FanController fanController;
    fanController.stop();
    fanController.resetToAuto();
    result.stdoutText =
        QStringLiteral("Fan control reset to automatic driver/VBIOS mode.\n");
    result.exitCode = 0;
    return result;
  }

  QTextStream progressStream(&result.stdoutText);
  auto appendProgress = [&](const QString &message) {
    if (!message.trimmed().isEmpty()) {
      progressStream << message.trimmed() << '\n';
    }
  };

  if (command.action == RoControlCli::CommandAction::InstallProprietaryDriver ||
      command.action == RoControlCli::CommandAction::InstallOpenSourceDriver ||
      command.action == RoControlCli::CommandAction::RemoveDriver ||
      command.action == RoControlCli::CommandAction::DeepCleanDriver) {
    NvidiaInstaller installer;
    QObject::connect(&installer, &NvidiaInstaller::progressMessage, &installer,
                     appendProgress);

    bool finished = false;
    bool success = false;
    QString finalMessage;
    QEventLoop loop;

    QObject::connect(&installer, &NvidiaInstaller::installFinished, &installer,
                     [&](bool ok, const QString &message) {
                       finished = true;
                       success = ok;
                       finalMessage = message;
                       loop.quit();
                     });
    QObject::connect(&installer, &NvidiaInstaller::removeFinished, &installer,
                     [&](bool ok, const QString &message) {
                       finished = true;
                       success = ok;
                       finalMessage = message;
                       loop.quit();
                     });

    if (command.action ==
        RoControlCli::CommandAction::InstallProprietaryDriver) {
      installer.installProprietary(command.acceptLicense);
    } else if (command.action ==
               RoControlCli::CommandAction::InstallOpenSourceDriver) {
      installer.installOpenSource();
    } else if (command.action == RoControlCli::CommandAction::RemoveDriver) {
      installer.remove();
    } else {
      installer.deepClean();
    }

    if (!finished) {
      loop.exec();
    }

    if (!finalMessage.isEmpty()) {
      if (success) {
        appendProgress(finalMessage);
      } else {
        result.stderrText = finalMessage;
      }
    }

    result.exitCode = finished && success ? 0 : 1;
    return result;
  }

  if (command.action == RoControlCli::CommandAction::UpdateDriver) {
    NvidiaUpdater updater;
    QObject::connect(&updater, &NvidiaUpdater::progressMessage, &updater,
                     appendProgress);

    bool finished = false;
    bool success = false;
    QString finalMessage;
    QEventLoop loop;

    QObject::connect(&updater, &NvidiaUpdater::updateFinished, &updater,
                     [&](bool ok, const QString &message) {
                       finished = true;
                       success = ok;
                       finalMessage = message;
                       loop.quit();
                     });

    updater.applyUpdate();

    if (!finished) {
      loop.exec();
    }

    if (!finalMessage.isEmpty()) {
      if (success) {
        appendProgress(finalMessage);
      } else {
        result.stderrText = finalMessage;
      }
    }

    result.exitCode = finished && success ? 0 : 1;
    return result;
  }

  result.exitCode = 2;
  result.stderrText = QStringLiteral("Unsupported CLI command.");
  return result;
}

void configureGuiGraphicsEnvironment() {
#if defined(Q_OS_LINUX)
  // ro-Control is a driver management tool, not a GPU-accelerated UI. Using
  // Qt Quick's software renderer on Linux avoids EGL/DRI startup warnings and
  // keeps the app usable while the graphics driver stack is broken or changing.
  if (qEnvironmentVariableIsEmpty("RO_CONTROL_USE_HARDWARE_RENDER")) {
    if (qEnvironmentVariableIsEmpty("QT_QPA_PLATFORM")) {
      qputenv("QT_QPA_PLATFORM", QByteArrayLiteral("wayland"));
    }
    qputenv("QT_QUICK_BACKEND", QByteArrayLiteral("software"));
    QQuickWindow::setGraphicsApi(QSGRendererInterface::Software);
    return;
  }

  // Keep an explicit escape hatch for hosts that still need software rendering.
  if (!qEnvironmentVariableIsEmpty("RO_CONTROL_FORCE_SOFTWARE_RENDER")) {
    qputenv("QT_QUICK_BACKEND", QByteArrayLiteral("software"));
    QQuickWindow::setGraphicsApi(QSGRendererInterface::Software);
  }
#endif
}

} // namespace

int main(int argc, char *argv[]) {
  constexpr auto kApplicationName = "ro-control";
  constexpr auto kDisplayName = "ro-Control";
  constexpr auto kApplicationVersion = RO_CONTROL_APP_VERSION;
  const QString applicationDescription =
      QStringLiteral("ro-Control GPU driver manager and diagnostics CLI.");

  QStringList arguments;
  arguments.reserve(argc);
  for (int i = 0; i < argc; ++i) {
    arguments << QString::fromLocal8Bit(argv[i]);
  }

  const auto command = RoControlCli::parseArguments(
      arguments, QString::fromLatin1(kApplicationName),
      QString::fromLatin1(kApplicationVersion), applicationDescription);

  QTextStream out(stdout);
  QTextStream err(stderr);

  if (command.action == RoControlCli::CommandAction::PrintHelp ||
      command.action == RoControlCli::CommandAction::PrintVersion) {
    out << command.payload;
    if (!command.payload.endsWith(QLatin1Char('\n'))) {
      out << Qt::endl;
    }
    return 0;
  }

  if (command.action == RoControlCli::CommandAction::Invalid) {
    err << command.payload << Qt::endl;
    err << "Run `ro-control --help` for usage." << Qt::endl;
    return 2;
  }

  if (command.action != RoControlCli::CommandAction::LaunchGui) {
    QCoreApplication cliApp(argc, argv);
    cliApp.setApplicationName(QString::fromLatin1(kApplicationName));
    cliApp.setApplicationVersion(QString::fromLatin1(kApplicationVersion));

    const auto result = executeCliCommand(command, cliApp.applicationName(),
                                          cliApp.applicationVersion());
    if (!result.stdoutText.isEmpty()) {
      out << result.stdoutText;
      if (!result.stdoutText.endsWith(QLatin1Char('\n'))) {
        out << Qt::endl;
      }
    }
    if (!result.stderrText.isEmpty()) {
      err << result.stderrText;
      if (!result.stderrText.endsWith(QLatin1Char('\n'))) {
        err << Qt::endl;
      }
    }
    return result.exitCode;
  }

  configureGuiGraphicsEnvironment();

  QApplication app(argc, argv);

  app.setApplicationName(QString::fromLatin1(kApplicationName));
  app.setApplicationDisplayName(QString::fromLatin1(kDisplayName));
  app.setApplicationVersion(QString::fromLatin1(kApplicationVersion));
  app.setOrganizationName("Project-Ro-ASD");
  app.setOrganizationDomain("github.com/Project-Ro-ASD");
  app.setWindowIcon(QIcon::fromTheme(
      "ro-control", QIcon(":/qt/qml/rocontrol/assets/ro-control-logo.svg")));

  QTranslator translator;
  NvidiaDetector detector;
  NvidiaInstaller installer;
  NvidiaUpdater updater;
  CpuMonitor cpuMonitor;
  GpuMonitor gpuMonitor;
  RamMonitor ramMonitor;
  FanController fanController;
  SystemInfoProvider systemInfo;

  QObject::connect(
      &gpuMonitor, &GpuMonitor::temperatureCChanged, &fanController,
      [&]() { fanController.updateTemperature(gpuMonitor.temperatureC()); });

  QObject::connect(
      &cpuMonitor, &CpuMonitor::temperatureCChanged, &fanController,
      [&]() { fanController.updateCpuTemperature(cpuMonitor.temperatureC()); });

  detector.refresh();

  QQmlApplicationEngine engine;
  LanguageManager languageManager(&app, &engine, &translator);
  UiPreferencesManager uiPreferencesManager;

  QVariantMap initialProperties;
  initialProperties.insert(QStringLiteral("nvidiaDetector"),
                           QVariant::fromValue(&detector));
  initialProperties.insert(QStringLiteral("nvidiaInstaller"),
                           QVariant::fromValue(&installer));
  initialProperties.insert(QStringLiteral("nvidiaUpdater"),
                           QVariant::fromValue(&updater));
  initialProperties.insert(QStringLiteral("cpuMonitor"),
                           QVariant::fromValue(&cpuMonitor));
  initialProperties.insert(QStringLiteral("gpuMonitor"),
                           QVariant::fromValue(&gpuMonitor));
  initialProperties.insert(QStringLiteral("ramMonitor"),
                           QVariant::fromValue(&ramMonitor));
  initialProperties.insert(QStringLiteral("fanController"),
                           QVariant::fromValue(&fanController));
  initialProperties.insert(QStringLiteral("systemInfo"),
                           QVariant::fromValue(&systemInfo));
  initialProperties.insert(QStringLiteral("languageManager"),
                           QVariant::fromValue(&languageManager));
  initialProperties.insert(QStringLiteral("uiPreferences"),
                           QVariant::fromValue(&uiPreferencesManager));
  engine.setInitialProperties(initialProperties);

  QObject::connect(
      &engine, &QQmlApplicationEngine::objectCreationFailed, &app,
      []() { QCoreApplication::exit(-1); }, Qt::QueuedConnection);

  engine.loadFromModule("rocontrol", "Main");

  return app.exec();
}
