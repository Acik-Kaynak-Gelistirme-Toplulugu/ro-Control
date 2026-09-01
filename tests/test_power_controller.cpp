#include <QCoreApplication>
#include <QSettings>
#include <QSignalSpy>
#include <QTest>

#include "power/powercontroller.h"

class TestPowerController : public QObject {
  Q_OBJECT

private slots:
  void init() {
    QCoreApplication::setOrganizationName(
        QStringLiteral("Project-Ro-ASD-TestSuite"));
    QCoreApplication::setApplicationName(
        QStringLiteral("ro-control-power-test"));

    QSettings settings;
    settings.clear();
    settings.sync();
  }

  void testInitialProperties() {
    PowerController controller;
    QVERIFY(controller.availablePresets().contains(QStringLiteral("eco")));
    QVERIFY(controller.availablePresets().contains(QStringLiteral("balanced")));
    QVERIFY(
        controller.availablePresets().contains(QStringLiteral("performance")));
    QVERIFY(controller.availablePresets().contains(QStringLiteral("custom")));
  }

  void testUpdatePowerDraw() {
    PowerController controller;
    QSignalSpy drawSpy(&controller, &PowerController::currentPowerDrawWChanged);

    controller.updatePowerDraw(125.5);
    QCOMPARE(controller.currentPowerDrawW(), 125.5);
    QCOMPARE(drawSpy.count(), 1);

    // Same value should not trigger another signal
    controller.updatePowerDraw(125.5);
    QCOMPARE(drawSpy.count(), 1);
  }

  void testPresetSelection() {
    PowerController controller;
    QSignalSpy presetSpy(&controller, &PowerController::powerPresetChanged);

    QVERIFY(controller.applyPowerPreset(QStringLiteral("custom")));
    QCOMPARE(controller.powerPreset(), QStringLiteral("custom"));
    QCOMPARE(presetSpy.count(), 1);
  }
};

QTEST_MAIN(TestPowerController)
#include "test_power_controller.moc"
