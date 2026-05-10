#include "uipreferencesmanager.h"

#include <QCoreApplication>
#include <QGuiApplication>
#include <QPalette>
#include <QSettings>
#include <QStyleHints>
#include <QtGlobal>

namespace {

struct ThemeModeEntry {
  const char *code;
};

constexpr ThemeModeEntry kThemeModes[] = {
    {"light"},
    {"dark"},
};

QString themeModeLabel(const QString &code) {
  if (code == QStringLiteral("light")) {
    return QCoreApplication::translate("UiPreferencesManager", "Light");
  }
  if (code == QStringLiteral("dark")) {
    return QCoreApplication::translate("UiPreferencesManager", "Dark");
  }
  return code;
}

} // namespace

UiPreferencesManager::UiPreferencesManager(QObject *parent) : QObject(parent) {
  m_systemDarkMode = detectSystemDarkMode();
#if QT_VERSION >= QT_VERSION_CHECK(6, 5, 0)
  auto *guiApplication =
      qobject_cast<QGuiApplication *>(QCoreApplication::instance());
  if (guiApplication != nullptr && guiApplication->styleHints() != nullptr) {
    connect(guiApplication->styleHints(), &QStyleHints::colorSchemeChanged,
            this, [this]() {
              const bool systemDarkMode = detectSystemDarkMode();
              if (systemDarkMode == m_systemDarkMode) {
                return;
              }

              m_systemDarkMode = systemDarkMode;
              m_themeMode = systemThemeMode();
              persistValue(QStringLiteral("ui/themeMode"), m_themeMode);
              emit themeModeChanged();
            });
  }
#endif

  QSettings settings;
  m_themeMode = systemThemeMode();
  settings.setValue(QStringLiteral("ui/themeMode"), m_themeMode);
  m_compactMode =
      settings.value(QStringLiteral("ui/compactMode"), m_compactMode).toBool();
  m_showAdvancedInfo =
      settings.value(QStringLiteral("ui/showAdvancedInfo"), m_showAdvancedInfo)
          .toBool();
}

QString UiPreferencesManager::themeMode() const { return m_themeMode; }

QVariantList UiPreferencesManager::availableThemeModes() const {
  QVariantList modes;
  for (const auto &entry : kThemeModes) {
    const QString code = QString::fromLatin1(entry.code);
    QVariantMap mode;
    mode.insert(QStringLiteral("code"), code);
    mode.insert(QStringLiteral("label"), themeModeLabel(code));
    modes.append(mode);
  }
  return modes;
}

bool UiPreferencesManager::compactMode() const { return m_compactMode; }

bool UiPreferencesManager::showAdvancedInfo() const {
  return m_showAdvancedInfo;
}

void UiPreferencesManager::setThemeMode(const QString &themeMode) {
  const QString normalizedThemeMode = normalizeThemeMode(themeMode);
  if (normalizedThemeMode == m_themeMode) {
    return;
  }

  m_themeMode = normalizedThemeMode;
  persistValue(QStringLiteral("ui/themeMode"), m_themeMode);
  emit themeModeChanged();
}

void UiPreferencesManager::setCompactMode(bool compactMode) {
  if (compactMode == m_compactMode) {
    return;
  }

  m_compactMode = compactMode;
  persistValue(QStringLiteral("ui/compactMode"), m_compactMode);
  emit compactModeChanged();
}

void UiPreferencesManager::setShowAdvancedInfo(bool showAdvancedInfo) {
  if (showAdvancedInfo == m_showAdvancedInfo) {
    return;
  }

  m_showAdvancedInfo = showAdvancedInfo;
  persistValue(QStringLiteral("ui/showAdvancedInfo"), m_showAdvancedInfo);
  emit showAdvancedInfoChanged();
}

void UiPreferencesManager::resetToDefaults() {
  setThemeMode(systemThemeMode());
  setCompactMode(false);
  setShowAdvancedInfo(true);
}

QString
UiPreferencesManager::normalizeThemeMode(const QString &themeMode) const {
  const QString normalizedThemeMode = themeMode.trimmed().toLower();
  for (const auto &entry : kThemeModes) {
    if (normalizedThemeMode == QLatin1String(entry.code)) {
      return normalizedThemeMode;
    }
  }

  return systemThemeMode();
}

bool UiPreferencesManager::detectSystemDarkMode() const {
  auto *guiApplication =
      qobject_cast<QGuiApplication *>(QCoreApplication::instance());
  if (guiApplication == nullptr) {
    return false;
  }

#if QT_VERSION >= QT_VERSION_CHECK(6, 5, 0)
  if (guiApplication->styleHints() != nullptr) {
    const Qt::ColorScheme colorScheme =
        guiApplication->styleHints()->colorScheme();
    if (colorScheme == Qt::ColorScheme::Dark) {
      return true;
    }
    if (colorScheme == Qt::ColorScheme::Light) {
      return false;
    }
  }
#endif

  const QColor windowColor = guiApplication->palette().window().color();
  return ((0.2126 * windowColor.redF()) + (0.7152 * windowColor.greenF()) +
          (0.0722 * windowColor.blueF())) < 0.5;
}

QString UiPreferencesManager::systemThemeMode() const {
  return m_systemDarkMode ? QStringLiteral("dark") : QStringLiteral("light");
}

void UiPreferencesManager::persistValue(const QString &key,
                                        const QVariant &value) const {
  QSettings settings;
  settings.setValue(key, value);
}
