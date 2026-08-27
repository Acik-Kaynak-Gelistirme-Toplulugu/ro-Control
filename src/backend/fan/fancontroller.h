#pragma once

#include <QObject>
#include <QSettings>
#include <QString>
#include <QStringList>
#include <QTimer>
#include <QVariantList>
#include <QVector>

struct FanCurvePoint {
  int temperatureC = 0;
  int fanSpeedPercent = 0;

  bool operator==(const FanCurvePoint &other) const {
    return temperatureC == other.temperatureC &&
           fanSpeedPercent == other.fanSpeedPercent;
  }
};

class FanController : public QObject {
  Q_OBJECT

  Q_PROPERTY(bool supported READ supported NOTIFY supportedChanged)
  Q_PROPERTY(bool controlSupported READ controlSupported NOTIFY controlSupportedChanged)
  Q_PROPERTY(bool running READ running NOTIFY runningChanged)
  Q_PROPERTY(int fanCount READ fanCount NOTIFY fanCountChanged)
  Q_PROPERTY(int currentFanSpeedPercent READ currentFanSpeedPercent NOTIFY
                 currentFanSpeedPercentChanged)
  Q_PROPERTY(int currentRpm READ currentRpm NOTIFY currentRpmChanged)
  Q_PROPERTY(int targetFanSpeedPercent READ targetFanSpeedPercent NOTIFY
                 targetFanSpeedPercentChanged)
  Q_PROPERTY(int manualFanSpeedPercent READ manualFanSpeedPercent WRITE
                 setManualFanSpeedPercent NOTIFY manualFanSpeedPercentChanged)
  Q_PROPERTY(
      QString fanMode READ fanMode WRITE setFanMode NOTIFY fanModeChanged)
  Q_PROPERTY(QStringList availableModes READ availableModes CONSTANT)
  Q_PROPERTY(bool safetyOverrideActive READ safetyOverrideActive NOTIFY
                 safetyOverrideActiveChanged)
  Q_PROPERTY(int thermalThresholdC READ thermalThresholdC NOTIFY
                 thermalThresholdCChanged)
  Q_PROPERTY(
      QString statusMessage READ statusMessage NOTIFY statusMessageChanged)
  Q_PROPERTY(QString hardwareType READ hardwareType NOTIFY hardwareTypeChanged)
  Q_PROPERTY(QString capabilityString READ capabilityString NOTIFY capabilityChanged)
  Q_PROPERTY(QVariantList customCurvePoints READ customCurvePointsVariant NOTIFY
                 customCurvePointsChanged)
  Q_PROPERTY(int gpuTemperatureC READ gpuTemperatureC NOTIFY
                 gpuTemperatureCChanged)

public:
  enum class FanMode {
    Auto,        // VBIOS / Driver default
    Silent,      // Acoustic priority curve
    Balanced,    // Optimized balanced curve
    Performance, // Aggressive cooling curve
    Manual,      // User-defined fixed percentage
    Custom       // User-defined custom curve points
  };
  Q_ENUM(FanMode)

  enum class ControlCapability {
    Unsupported,
    TelemetryOnly,
    Controllable,
    PermissionDenied,
    Unavailable,
    InitializationFailed
  };
  Q_ENUM(ControlCapability)

  explicit FanController(QObject *parent = nullptr);
  ~FanController() override;

  bool supported() const;
  bool controlSupported() const;
  ControlCapability capability() const;
  QString capabilityString() const;
  QString hardwareType() const;
  bool running() const;
  int fanCount() const;
  int currentFanSpeedPercent() const;
  int currentRpm() const;
  int targetFanSpeedPercent() const;
  int manualFanSpeedPercent() const;
  QString fanMode() const;
  FanMode modeEnum() const;
  QStringList availableModes() const;
  bool safetyOverrideActive() const;
  int thermalThresholdC() const;
  QString statusMessage() const;
  QVariantList customCurvePointsVariant() const;
  QVector<FanCurvePoint> customCurvePoints() const;
  int gpuTemperatureC() const;

  static QString modeToString(FanMode mode);
  static FanMode stringToMode(const QString &modeStr);
  static QString capabilityToString(ControlCapability cap);

  static int calculateCurveFanSpeed(const QVector<FanCurvePoint> &curve,
                                    int temperatureC);
  static QVector<FanCurvePoint> defaultSilentCurve();
  static QVector<FanCurvePoint> defaultBalancedCurve();
  static QVector<FanCurvePoint> defaultPerformanceCurve();
  static QVector<FanCurvePoint> defaultCustomCurve();

  Q_INVOKABLE void refresh();
  Q_INVOKABLE void start();
  Q_INVOKABLE void stop();
  Q_INVOKABLE void setFanMode(const QString &mode);
  Q_INVOKABLE void setManualFanSpeedPercent(int percent);
  Q_INVOKABLE bool setCustomCurvePoint(int index, int tempC, int speedPercent);
  Q_INVOKABLE void resetCustomCurve();
  Q_INVOKABLE void resetToAuto();
  Q_INVOKABLE void updateTemperature(int tempC);

signals:
  void supportedChanged();
  void controlSupportedChanged();
  void capabilityChanged();
  void hardwareTypeChanged();
  void runningChanged();
  void fanCountChanged();
  void currentFanSpeedPercentChanged();
  void currentRpmChanged();
  void targetFanSpeedPercentChanged();
  void manualFanSpeedPercentChanged();
  void fanModeChanged();
  void safetyOverrideActiveChanged();
  void thermalThresholdCChanged();
  void statusMessageChanged();
  void customCurvePointsChanged();
  void gpuTemperatureCChanged();
  void fanSpeedApplied(int targetPercent, bool success);

private:
  void loadSettings();
  void saveSettings();
  void detectHardwareCapabilities();
  void evaluateAndApplyFanSpeed(bool force = false);
  bool executeSetFanSpeed(int percent, bool isAutoMode);
  void readCurrentFanTelemetry();
  void setSupported(bool value);
  void setControlSupported(bool value);
  void setCapability(ControlCapability cap);
  void setHardwareType(const QString &hwType);
  void setStatusMessage(const QString &msg);

  QTimer m_timer;
  bool m_supported = false;
  bool m_controlSupported = false;
  ControlCapability m_capability = ControlCapability::Unsupported;
  QString m_hardwareType = QStringLiteral("None");
  int m_fanCount = 1;
  int m_currentFanSpeedPercent = 0;
  int m_currentRpm = 0;
  int m_targetFanSpeedPercent = 0;
  int m_manualFanSpeedPercent = 50;
  FanMode m_mode = FanMode::Auto;
  bool m_safetyOverrideActive = false;
  int m_thermalThresholdC = 85;
  int m_thermalRecoveryMarginC = 5;
  int m_hysteresisTempC = 2;
  int m_lastEvaluatedTempC = -1;
  QString m_statusMessage;
  QVector<FanCurvePoint> m_customCurve;
  int m_gpuTemperatureC = 0;
  int m_lastAppliedPercent = -1;
  bool m_lastAppliedModeWasAuto = true;
  QString m_verifiedHwmonPwmPath;
  QString m_verifiedHwmonPwmEnablePath;
};
