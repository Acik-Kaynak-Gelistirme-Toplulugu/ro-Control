#include "installer.h"
#include "system/commandrunner.h"

NvidiaInstaller::NvidiaInstaller(QObject *parent) : QObject(parent) {}

void NvidiaInstaller::install() {
  CommandRunner runner;

  // CommandRunner'dan gelen her satırı QML'e ilet
  connect(&runner, &CommandRunner::outputLine, this,
          &NvidiaInstaller::progressMessage);

  emit progressMessage(QStringLiteral("RPM Fusion deposu kontrol ediliyor..."));

  CommandRunner rpmRunner;
  const auto fedora = rpmRunner.run(QStringLiteral("rpm"),
                                    {QStringLiteral("-E"), QStringLiteral("%fedora")});
  const QString fedoraVersion = fedora.stdout.trimmed();

  if (fedoraVersion.isEmpty()) {
    emit installFinished(false, QStringLiteral("Fedora surumu tespit edilemedi."));
    return;
  }

  // Adım 1: RPM Fusion reposunu etkinleştir
  auto result = runner.runAsRoot(
      QStringLiteral("dnf"),
      {QStringLiteral("install"), QStringLiteral("-y"),
       QStringLiteral("https://mirrors.rpmfusion.org/free/fedora/"
                      "rpmfusion-free-release-%1.noarch.rpm")
           .arg(fedoraVersion),
       QStringLiteral(
           "https://mirrors.rpmfusion.org/nonfree/fedora/"
           "rpmfusion-nonfree-release-%1.noarch.rpm")
           .arg(fedoraVersion)});

  if (!result.success()) {
    emit installFinished(false, QStringLiteral("RPM Fusion repo eklenemedi: ") +
                                    result.stderr);
    return;
  }

  emit progressMessage(
      QStringLiteral("NVIDIA sürücüsü kuruluyor (akmod-nvidia)..."));

  // Adım 2: akmod-nvidia kur
  result = runner.runAsRoot(QStringLiteral("dnf"),
                            {QStringLiteral("install"), QStringLiteral("-y"),
                             QStringLiteral("akmod-nvidia")});

  if (!result.success()) {
    emit installFinished(false,
                         QStringLiteral("Kurulum başarısız: ") + result.stderr);
    return;
  }

  emit progressMessage(QStringLiteral(
      "Kernel modülü derleniyor (bu birkaç dakika sürebilir)..."));

  // Adım 3: akmods ile modülü derle
  runner.runAsRoot(QStringLiteral("akmods"), {QStringLiteral("--force")});

  emit installFinished(true,
                       QStringLiteral("NVIDIA sürücüsü başarıyla kuruldu. "
                                      "Lütfen sistemi yeniden başlatın."));
}

void NvidiaInstaller::remove() {
  CommandRunner runner;
  connect(&runner, &CommandRunner::outputLine, this,
          &NvidiaInstaller::progressMessage);

  emit progressMessage(QStringLiteral("NVIDIA sürücüsü kaldırılıyor..."));

  const auto result = runner.runAsRoot(
      QStringLiteral("dnf"),
      {QStringLiteral("remove"), QStringLiteral("-y"),
       QStringLiteral("akmod-nvidia"), QStringLiteral("xorg-x11-drv-nvidia*")});

  emit removeFinished(result.success(),
                      result.success()
                          ? QStringLiteral("Sürücü başarıyla kaldırıldı.")
                          : QStringLiteral("Kaldırma başarısız: ") +
                                result.stderr);
}

void NvidiaInstaller::deepClean() {
  CommandRunner runner;
  connect(&runner, &CommandRunner::outputLine, this,
          &NvidiaInstaller::progressMessage);

  emit progressMessage(
      QStringLiteral("Eski sürücü kalıntıları temizleniyor..."));

  // Tüm nvidia paketlerini kaldır
  runner.runAsRoot(QStringLiteral("dnf"),
                   {QStringLiteral("remove"), QStringLiteral("-y"),
                    QStringLiteral("*nvidia*"), QStringLiteral("*akmod*")});

  // DNF cache temizle
  runner.runAsRoot(QStringLiteral("dnf"),
                   {QStringLiteral("clean"), QStringLiteral("all")});

  emit progressMessage(QStringLiteral("Temizlik tamamlandı."));
}
