#include <QTest>

#include "monitor/cpumonitor.h"
#include "monitor/gpumonitor.h"
#include "monitor/rammonitor.h"

class TestMonitor : public QObject {
  Q_OBJECT

private slots:
  void testCpuConstruction() {
    CpuMonitor cpu;
    Q_UNUSED(cpu);
    QVERIFY(true);
  }

  void testGpuConstruction() {
    GpuMonitor gpu;
    Q_UNUSED(gpu);
    QVERIFY(true);
  }

  void testRamConstruction() {
    RamMonitor ram;
    Q_UNUSED(ram);
    QVERIFY(true);
  }
};

QTEST_MAIN(TestMonitor)
#include "test_monitor.moc"
