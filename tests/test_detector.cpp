#include <QTest>
#include <QFile>
#include <QTemporaryDir>

#include "nvidia/detector.h"

class TestDetector : public QObject {
  Q_OBJECT

private slots:
  void testConstruction() {
    NvidiaDetector detector;
    Q_UNUSED(detector);
    QVERIFY(true);
  }

  void testGpuInfoDefaults() {
    NvidiaDetector::GpuInfo info{};
    QCOMPARE(info.found, false);
    QVERIFY(info.name.isEmpty());
    QVERIFY(info.driverVersion.isEmpty());
    QCOMPARE(info.driverPackageInstalled, false);
    QCOMPARE(info.driverLoaded, false);
    QCOMPARE(info.nouveauActive, false);
    QCOMPARE(info.openKernelModulesInstalled, false);
    QCOMPARE(info.secureBootEnabled, false);
  }

  void testDetectDoesNotCrash() {
    NvidiaDetector detector;
    auto info = detector.detect();
    Q_UNUSED(info);
    QVERIFY(true);
  }

  void testHasNvidiaGpu() {
    NvidiaDetector detector;
    const bool hasGpu = detector.hasNvidiaGpu();
    const auto info = detector.detect();
    QCOMPARE(hasGpu, info.found);
  }

  void testIsDriverInstalled() {
    NvidiaDetector detector;
    const bool installed = detector.isDriverInstalled();
    const auto info = detector.detect();
    QCOMPARE(installed,
             !detector.installedDriverVersion().isEmpty() ||
                 info.driverPackageInstalled);
  }

  void testInstalledDriverVersion() {
    NvidiaDetector detector;
    QString version = detector.installedDriverVersion();
    if (!version.isEmpty()) {
      QVERIFY(version.contains(QChar('.')));
    }
  }

  void testDetectConsistency() {
    NvidiaDetector detector;
    auto info = detector.detect();
    if (!info.found) {
      QVERIFY(info.name.isEmpty());
    }
    if (info.driverVersion.isEmpty() && !info.driverPackageInstalled) {
      QVERIFY(!detector.isDriverInstalled());
    }
  }

  // verificationReport() en azından temel güvenlik bilgisini döndürmeli.
  void testVerificationReport() {
    NvidiaDetector detector;
    detector.refresh();
    const QString report = detector.verificationReport();
    QVERIFY(!report.isEmpty());
    QVERIFY(report.contains(QStringLiteral("GPU: ")));
    QVERIFY(report.contains(QStringLiteral("Driver Version: ")));
    QVERIFY(report.contains(QStringLiteral("Secure Boot")));
  }

  void testActiveDriverStringIsNeverEmpty() {
    NvidiaDetector detector;
    detector.refresh();
    QVERIFY(!detector.activeDriver().trimmed().isEmpty());
  }

  void testSecureBootEfivarOverride() {
    QTemporaryDir tempDir;
    QVERIFY(tempDir.isValid());

    const QString efivarPath = tempDir.filePath(QStringLiteral("SecureBoot-test"));
    QFile file(efivarPath);
    QVERIFY(file.open(QIODevice::WriteOnly));
    QVERIFY(file.write(QByteArray::fromHex("0700000001")) == 5);
    file.close();

    qputenv("RO_CONTROL_SECURE_BOOT_EFIVAR_PATH", efivarPath.toUtf8());

    NvidiaDetector detector;
    const auto info = detector.detect();
    QVERIFY(info.secureBootKnown);
    QVERIFY(info.secureBootEnabled);

    qunsetenv("RO_CONTROL_SECURE_BOOT_EFIVAR_PATH");
  }
};

QTEST_MAIN(TestDetector)
#include "test_detector.moc"
