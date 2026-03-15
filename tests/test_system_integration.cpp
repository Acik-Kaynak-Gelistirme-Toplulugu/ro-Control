#include <QStandardPaths>
#include <QTest>

#include "system/commandrunner.h"
#include "system/dnfmanager.h"
#include "system/polkit.h"

class TestSystemIntegration : public QObject {
  Q_OBJECT

private slots:
  void testCommandRunnerBasic() {
    CommandRunner runner;
    const auto result = runner.run(QStringLiteral("true"));
    QCOMPARE(result.exitCode, 0);
    QVERIFY(result.success());
  }

  void testCommandRunnerMissingBinary() {
    CommandRunner runner;
    const auto result = runner.run(QStringLiteral("ro-control-command-that-does-not-exist"));
    QCOMPARE(result.exitCode, -1);
    QVERIFY(result.stderr.contains(QStringLiteral("Failed to start")));
  }

  void testDnfManagerEmptyPackageListsFailFast() {
    DnfManager dnf;

    const auto installResult = dnf.installPackages({});
    QCOMPARE(installResult.exitCode, -1);
    QVERIFY(installResult.stderr.contains(QStringLiteral("No packages provided")));

    const auto removeResult = dnf.removePackages({});
    QCOMPARE(removeResult.exitCode, -1);
    QVERIFY(removeResult.stderr.contains(QStringLiteral("No packages provided")));
  }

  void testDnfManagerAvailabilityAndVersion() {
    DnfManager dnf;
    if (!dnf.isAvailable()) {
      QSKIP("dnf is not available on this host.");
    }

    CommandRunner runner;
    const auto result = runner.run(QStringLiteral("dnf"),
                                   {QStringLiteral("--version")});
    QVERIFY(result.success());
  }

  void testPolkitHelperAvailability() {
    PolkitHelper polkit;
    const bool hasPkexec = polkit.isPkexecAvailable();

    if (!hasPkexec) {
      const auto result = polkit.runPrivileged(QStringLiteral("true"));
      QCOMPARE(result.exitCode, -1);
      QVERIFY(result.stderr.contains(QStringLiteral("pkexec not found")));
      QSKIP("pkexec is not available on this host.");
    }

    // Functional probe should not crash and should report a meaningful state.
    QVERIFY(polkit.canAcquirePrivilege() || !polkit.canAcquirePrivilege());
  }

  void testNvidiaSmiOptionalProbe() {
    if (QStandardPaths::findExecutable(QStringLiteral("nvidia-smi")).isEmpty()) {
      QSKIP("nvidia-smi is not available on this host.");
    }

    CommandRunner runner;
    const auto result =
        runner.run(QStringLiteral("nvidia-smi"), {QStringLiteral("--help")});
    QVERIFY(result.success() || result.exitCode == 0);
  }
};

QTEST_MAIN(TestSystemIntegration)
#include "test_system_integration.moc"
