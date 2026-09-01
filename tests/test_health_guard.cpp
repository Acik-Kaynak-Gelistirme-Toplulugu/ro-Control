#include <QCoreApplication>
#include <QSettings>
#include <QSignalSpy>
#include <QTest>

#include "system/healthguard.h"

class TestHealthGuard : public QObject {
  Q_OBJECT

private slots:
  void init() {
    QCoreApplication::setOrganizationName(
        QStringLiteral("Project-Ro-ASD-TestSuite"));
    QCoreApplication::setApplicationName(
        QStringLiteral("ro-control-healthguard-test"));

    QSettings settings;
    settings.clear();
    settings.sync();
  }

  void testInitialDefaults() {
    HealthGuard guard;
    QVERIFY(guard.notificationsEnabled());
    QCOMPARE(guard.gpuWarningThresholdC(), 82);
    QCOMPARE(guard.gpuCriticalThresholdC(), 88);
    QVERIFY(!guard.alertActive());
  }

  void testWarningAlertTrigger() {
    HealthGuard guard;
    guard.setNotificationsEnabled(true);
    guard.setGpuWarningThresholdC(75);

    QSignalSpy alertSpy(&guard, &HealthGuard::thermalAlertTriggered);
    guard.updateGpuTemperature(78);

    QVERIFY(guard.alertActive());
    QCOMPARE(guard.lastAlertSeverity(), QStringLiteral("warning"));
    QCOMPARE(alertSpy.count(), 1);
  }

  void testCriticalAlertTrigger() {
    HealthGuard guard;
    guard.setNotificationsEnabled(true);
    guard.setGpuCriticalThresholdC(85);

    QSignalSpy alertSpy(&guard, &HealthGuard::thermalAlertTriggered);
    guard.updateGpuTemperature(90);

    QVERIFY(guard.alertActive());
    QCOMPARE(guard.lastAlertSeverity(), QStringLiteral("critical"));
    QCOMPARE(alertSpy.count(), 1);
  }

  void testClearAlert() {
    HealthGuard guard;
    guard.setGpuWarningThresholdC(60);
    guard.updateGpuTemperature(65);
    QVERIFY(guard.alertActive());

    guard.clearAlert();
    QVERIFY(!guard.alertActive());
  }
};

QTEST_MAIN(TestHealthGuard)
#include "test_health_guard.moc"
