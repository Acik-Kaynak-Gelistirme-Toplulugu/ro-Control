#pragma once

#include <QObject>
#include <QString>
#include <atomic>
#include <functional>
#include <memory>

class CommandRunner;
namespace SessionUtil {
struct SessionInfo;
}

// NvidiaInstaller: DNF üzerinden NVIDIA sürücü kurulum/kaldırma işlemleri.
// Tüm işlemler root gerektirir — polkit üzerinden yetki alınır.
class NvidiaInstaller : public QObject {
  Q_OBJECT

  Q_PROPERTY(bool proprietaryAgreementRequired READ proprietaryAgreementRequired
                 NOTIFY proprietaryAgreementChanged)
  Q_PROPERTY(QString proprietaryAgreementText READ proprietaryAgreementText
                 NOTIFY proprietaryAgreementChanged)
  Q_PROPERTY(bool busy READ busy NOTIFY busyChanged)

public:
  explicit NvidiaInstaller(QObject *parent = nullptr);

  bool proprietaryAgreementRequired() const {
    return m_proprietaryAgreementRequired;
  }
  QString proprietaryAgreementText() const {
    return m_proprietaryAgreementText;
  }
  bool busy() const { return m_busy; }

  // Sozlesme durumunu yeniden kontrol et
  Q_INVOKABLE void refreshProprietaryAgreement();

  // Kapali kaynak kurulum (kullanici onayi bilgisiyle)
  Q_INVOKABLE void installProprietary(bool agreementAccepted);

  // Topluluk acik kaynak grafik surucusune gecis/kurulum
  Q_INVOKABLE void installOpenSource();

  // Sürücüyü kur (akmod-nvidia)
  Q_INVOKABLE void install();

  // Sürücüyü kaldır
  Q_INVOKABLE void remove();

  // Eski sürücü kalıntılarını temizle
  Q_INVOKABLE void deepClean();

  // Devam eden kurulum/kaldırma işlemini best-effort iptal et
  Q_INVOKABLE void cancelOperation();

signals:
  // İşlem adımları — QML'e ilerleme göstermek için
  void progressMessage(const QString &message);

  void proprietaryAgreementChanged();
  void busyChanged();

  // İşlem tamamlandı
  void installFinished(bool success, const QString &message);
  void removeFinished(bool success, const QString &message);

private:
  void setBusy(bool busy);
  void runAsyncTask(const std::function<void()> &task);
  void setProprietaryAgreement(bool required, const QString &text);
  bool applySessionSpecificSetup(CommandRunner &runner,
                                 const SessionUtil::SessionInfo &sessionInfo,
                                 QString *errorMessage);

  bool m_proprietaryAgreementRequired = false;
  QString m_proprietaryAgreementText;
  bool m_busy = false;
  std::shared_ptr<std::atomic_bool> m_cancelRequested;
};
