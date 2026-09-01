#include <QJsonDocument>
#include <QJsonObject>
#include <QTest>

#include "fan/fancontroller.h"
#include "monitor/cpumonitor.h"
#include "monitor/gpumonitor.h"
#include "monitor/rammonitor.h"
#include "power/powercontroller.h"
#include "system/dbusservice.h"
#include "system/healthguard.h"

class TestDBusService : public QObject {
  Q_OBJECT

private slots:
  void testTelemetryGeneration() {
    CpuMonitor cpu;
    GpuMonitor gpu;
    RamMonitor ram;
    FanController fan;
    PowerController power;
    HealthGuard guard;

    RoControlDBusAdaptor adaptor(this, &cpu, &gpu, &ram, &fan, &power, &guard);

    const QString telemetryJson = adaptor.GetTelemetry();
    QVERIFY(!telemetryJson.isEmpty());

    const QJsonDocument doc = QJsonDocument::fromJson(telemetryJson.toUtf8());
    QVERIFY(doc.isObject());
    const QJsonObject obj = doc.object();
    QVERIFY(obj.contains(QStringLiteral("cpu")));
    QVERIFY(obj.contains(QStringLiteral("gpu")));
    QVERIFY(obj.contains(QStringLiteral("ram")));
    QVERIFY(obj.contains(QStringLiteral("fan")));
    QVERIFY(obj.contains(QStringLiteral("power")));
  }

  void testThermalStatus() {
    CpuMonitor cpu;
    GpuMonitor gpu;
    RamMonitor ram;
    FanController fan;
    PowerController power;
    HealthGuard guard;

    RoControlDBusAdaptor adaptor(this, &cpu, &gpu, &ram, &fan, &power, &guard);

    const QString thermalJson = adaptor.GetThermalStatus();
    QVERIFY(!thermalJson.isEmpty());

    const QJsonDocument doc = QJsonDocument::fromJson(thermalJson.toUtf8());
    QVERIFY(doc.isObject());
    const QJsonObject obj = doc.object();
    QVERIFY(obj.contains(QStringLiteral("gpuTemperatureC")));
    QVERIFY(obj.contains(QStringLiteral("cpuTemperatureC")));
    QVERIFY(obj.contains(QStringLiteral("fanRpm")));
    QVERIFY(obj.contains(QStringLiteral("alertActive")));
  }

  void testGpuHealth() {
    CpuMonitor cpu;
    GpuMonitor gpu;
    RamMonitor ram;
    FanController fan;
    PowerController power;
    HealthGuard guard;

    RoControlDBusAdaptor adaptor(this, &cpu, &gpu, &ram, &fan, &power, &guard);

    const QString healthJson = adaptor.GetGpuHealth();
    QVERIFY(!healthJson.isEmpty());

    const QJsonDocument doc = QJsonDocument::fromJson(healthJson.toUtf8());
    QVERIFY(doc.isObject());
  }
};

QTEST_MAIN(TestDBusService)
#include "test_dbus_service.moc"
