#include "languagemanager.h"

#include <QCoreApplication>
#include <QLocale>
#include <QQmlEngine>
#include <QSettings>
#include <QTranslator>
#include <utility>

namespace {

struct LanguageEntry {
  const char *code;
  const char *nativeLabel;
  bool shipped;
};

constexpr LanguageEntry kSupportedLanguages[] = {
    {"en", "English", true},
    {"de", "Deutsch", true},
    {"es", "Español", true},
    {"tr", "Türkçe", true},
};

QString localizedLanguageLabel(const QString &code) {
  if (code == QStringLiteral("en")) {
    return QCoreApplication::translate("LanguageManager", "English");
  }
  if (code == QStringLiteral("de")) {
    return QCoreApplication::translate("LanguageManager", "German");
  }
  if (code == QStringLiteral("es")) {
    return QCoreApplication::translate("LanguageManager", "Spanish");
  }
  if (code == QStringLiteral("tr")) {
    return QCoreApplication::translate("LanguageManager", "Turkish");
  }
  return code;
}

bool isSupportedLanguage(const QString &languageCode) {
  for (const auto &entry : kSupportedLanguages) {
    if (QString::fromLatin1(entry.code) == languageCode && entry.shipped) {
      return true;
    }
  }

  return false;
}

} // namespace

LanguageManager::LanguageManager(QCoreApplication *application,
                                 QQmlEngine *engine, QTranslator *translator,
                                 QObject *parent)
    : QObject(parent), m_application(application), m_engine(engine),
      m_translator(translator) {
  QSettings settings;
  const QString systemLanguage = normalizeLanguageCode(systemLanguageCode());
  setCurrentLanguage(systemLanguage);
}

QString LanguageManager::currentLanguage() const { return m_currentLanguage; }

QString LanguageManager::effectiveLanguage() const {
  return effectiveLanguageCode(m_currentLanguage);
}

QString LanguageManager::currentLanguageLabel() const {
  return displayNameForLanguage(m_currentLanguage);
}

QVariantList LanguageManager::availableLanguages() const {
  QVariantList languages;
  for (const auto &entry : kSupportedLanguages) {
    if (!entry.shipped) {
      continue;
    }

    const QString code = QString::fromLatin1(entry.code);
    QVariantMap language;
    language.insert(QStringLiteral("code"), code);
    language.insert(QStringLiteral("label"), localizedLanguageLabel(code));
    language.insert(QStringLiteral("nativeLabel"),
                    QString::fromUtf8(entry.nativeLabel));
    language.insert(QStringLiteral("shipped"), entry.shipped);
    languages.append(language);
  }

  return languages;
}

void LanguageManager::setCurrentLanguage(const QString &languageCode) {
  const QString normalizedLanguage = normalizeLanguageCode(languageCode);
  if (normalizedLanguage == m_currentLanguage) {
    return;
  }

  if (!loadLanguage(normalizedLanguage)) {
    return;
  }

  m_currentLanguage = normalizedLanguage;

  QSettings settings;
  settings.setValue(QStringLiteral("ui/language"), m_currentLanguage);

  emit currentLanguageChanged();
}

QString
LanguageManager::displayNameForLanguage(const QString &languageCode) const {
  const QString trimmedLanguage = languageCode.trimmed().toLower();
  for (const auto &entry : kSupportedLanguages) {
    if (QString::fromLatin1(entry.code) == trimmedLanguage) {
      return QString::fromUtf8(entry.nativeLabel);
    }
  }

  const QLocale locale(trimmedLanguage);
  const QString nativeLanguageName = locale.nativeLanguageName();
  if (!nativeLanguageName.isEmpty()) {
    return nativeLanguageName;
  }

  return trimmedLanguage;
}

QString
LanguageManager::normalizeLanguageCode(const QString &languageCode) const {
  const QString normalizedLanguage = languageCode.trimmed().toLower();
  if (isSupportedLanguage(normalizedLanguage)) {
    return normalizedLanguage;
  }

  const QString systemLanguage = systemLanguageCode();
  if (isSupportedLanguage(systemLanguage)) {
    return systemLanguage;
  }

  return QStringLiteral("en");
}

QString LanguageManager::systemLanguageCode() const {
  return QLocale::system().name().section(QLatin1Char('_'), 0, 0).toLower();
}

QString
LanguageManager::effectiveLanguageCode(const QString &languageCode) const {
  return normalizeLanguageCode(languageCode);
}

bool LanguageManager::loadLanguage(const QString &languageCode) {
  if (m_application == nullptr || m_engine == nullptr ||
      m_translator == nullptr) {
    return false;
  }

  const QString effectiveLanguage = effectiveLanguageCode(languageCode);

  m_application->removeTranslator(m_translator);

  bool loaded = false;
  if (effectiveLanguage != QStringLiteral("en")) {
    loaded = m_translator->load(
        QStringLiteral(":/i18n/ro-control_%1.qm").arg(effectiveLanguage));
  }

  if (loaded) {
    m_application->installTranslator(m_translator);
  }

  m_engine->setUiLanguage(effectiveLanguage);
  m_engine->retranslate();
  return true;
}
