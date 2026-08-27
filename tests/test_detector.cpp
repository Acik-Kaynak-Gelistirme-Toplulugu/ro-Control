#include <QFile>
#include <QTemporaryDir>
#include <QTest>

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
    QCOMPARE(installed, !detector.installedDriverVersion().isEmpty() ||
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

    const QString efivarPath =
        tempDir.filePath(QStringLiteral("SecureBoot-test"));
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

  void testSecureBootEfivarDisabledOverride() {
    QTemporaryDir tempDir;
    QVERIFY(tempDir.isValid());

    const QString efivarPath =
        tempDir.filePath(QStringLiteral("SecureBoot-disabled-test"));
    QFile file(efivarPath);
    QVERIFY(file.open(QIODevice::WriteOnly));
    QVERIFY(file.write(QByteArray::fromHex("0700000000")) == 5);
    file.close();

    qputenv("RO_CONTROL_SECURE_BOOT_EFIVAR_PATH", efivarPath.toUtf8());

    NvidiaDetector detector;
    const auto info = detector.detect();
    QVERIFY(info.secureBootKnown);
    QVERIFY(!info.secureBootEnabled);

    qunsetenv("RO_CONTROL_SECURE_BOOT_EFIVAR_PATH");
  }

  void testCleanGpuName() {
    // 1. Bracketed NVIDIA GPU with chip code
    QCOMPARE(NvidiaDetector::cleanGpuName(
                 QStringLiteral("TU106 [GeForce RTX 2060 SUPER]")),
             QStringLiteral("NVIDIA GeForce RTX 2060 SUPER"));

    // 2. Already clean NVIDIA GPU
    QCOMPARE(NvidiaDetector::cleanGpuName(
                 QStringLiteral("NVIDIA GeForce RTX 2060 SUPER")),
             QStringLiteral("NVIDIA GeForce RTX 2060 SUPER"));

    // 3. Bracketed with revision suffix and corporation prefix
    QCOMPARE(
        NvidiaDetector::cleanGpuName(
            QStringLiteral(
                "NVIDIA Corporation TU106 [GeForce RTX 2060 SUPER] (rev a1)"),
            QStringLiteral("NVIDIA Corporation")),
        QStringLiteral("NVIDIA GeForce RTX 2060 SUPER"));

    // 4. Ada Lovelace RTX 4090
    QCOMPARE(NvidiaDetector::cleanGpuName(
                 QStringLiteral("AD102 [GeForce RTX 4090]")),
             QStringLiteral("NVIDIA GeForce RTX 4090"));

    // 5. Intel integrated graphics
    QCOMPARE(NvidiaDetector::cleanGpuName(
                 QStringLiteral("Raptor Lake-S GT1 [UHD Graphics 770]"),
                 QStringLiteral("Intel Corporation")),
             QStringLiteral("Intel UHD Graphics 770"));

    // 6. AMD Radeon GPU
    QCOMPARE(NvidiaDetector::cleanGpuName(
                 QStringLiteral("Navi 21 [Radeon RX 6800/6800 XT / 6900 XT]"),
                 QStringLiteral("Advanced Micro Devices, Inc. [AMD/ATI]")),
             QStringLiteral("AMD Radeon RX 6800/6800 XT / 6900 XT"));

    // 7. Quadro GPU
    QCOMPARE(NvidiaDetector::cleanGpuName(QStringLiteral("Quadro RTX 4000")),
             QStringLiteral("NVIDIA Quadro RTX 4000"));
  }
};

QTEST_MAIN(TestDetector)
#include "test_detector.moc"
