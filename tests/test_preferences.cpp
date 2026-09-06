#include <QCoreApplication>
#include <QQmlEngine>
#include <QSettings>
#include <QSignalSpy>
#include <QTest>
#include <QTranslator>

#include "backend/system/languagemanager.h"
#include "backend/system/uipreferencesmanager.h"

class TestPreferences : public QObject {
  Q_OBJECT

private slots:
  void init();
  void testUiPreferencesDefaults();
  void testUiPreferencesPersistChanges();
  void testUiPreferencesNormalizesInvalidThemeMode();
  void testLanguageManagerExposesEffectiveLanguageMetadata();
};

void TestPreferences::init() {
  QCoreApplication::setOrganizationName(
      QStringLiteral("Project-Ro-ASD-TestSuite"));
  QCoreApplication::setApplicationName(
      QStringLiteral("ro-control-preferences"));

  QSettings settings;
  settings.clear();
  settings.sync();
}

void TestPreferences::testUiPreferencesDefaults() {
  UiPreferencesManager preferences;

  QVERIFY(preferences.themeMode() == QStringLiteral("light") ||
          preferences.themeMode() == QStringLiteral("dark"));
  QCOMPARE(preferences.showAdvancedInfo(), true);
  QCOMPARE(preferences.availableThemeModes().size(), 2);
}

void TestPreferences::testUiPreferencesPersistChanges() {
  UiPreferencesManager preferences;
  QSignalSpy themeSpy(&preferences, &UiPreferencesManager::themeModeChanged);
  QSignalSpy advancedSpy(&preferences,
                         &UiPreferencesManager::showAdvancedInfoChanged);

  preferences.setThemeMode(QStringLiteral("dark"));
  preferences.setShowAdvancedInfo(false);

  QCOMPARE(themeSpy.count(), 1);
  QCOMPARE(advancedSpy.count(), 1);

  UiPreferencesManager reloadedPreferences;
  QVERIFY(reloadedPreferences.themeMode() == QStringLiteral("light") ||
          reloadedPreferences.themeMode() == QStringLiteral("dark"));
  QCOMPARE(reloadedPreferences.showAdvancedInfo(), false);
}

void TestPreferences::testUiPreferencesNormalizesInvalidThemeMode() {
  UiPreferencesManager preferences;

  preferences.setThemeMode(QStringLiteral("midnight"));
  QVERIFY(preferences.themeMode() == QStringLiteral("light") ||
          preferences.themeMode() == QStringLiteral("dark"));
}

void TestPreferences::testLanguageManagerExposesEffectiveLanguageMetadata() {
  QQmlEngine engine;
  QTranslator translator;
  LanguageManager manager(QCoreApplication::instance(), &engine, &translator);

  const QVariantList languages = manager.availableLanguages();
  QVERIFY(!languages.isEmpty());
  QCOMPARE(languages.first().toMap().value(QStringLiteral("code")).toString(),
           QStringLiteral("en"));
  QVERIFY(languages.first().toMap().contains(QStringLiteral("nativeLabel")));

  manager.setCurrentLanguage(QStringLiteral("system"));
  QVERIFY(manager.currentLanguage() != QStringLiteral("system"));
  QCOMPARE(manager.currentLanguage(), manager.effectiveLanguage());

  manager.setCurrentLanguage(QStringLiteral("tr"));
  QCOMPARE(manager.currentLanguage(), QStringLiteral("tr"));
  QCOMPARE(manager.effectiveLanguage(), QStringLiteral("tr"));
  QCOMPARE(manager.currentLanguageLabel(), QStringLiteral("Türkçe"));

  QStringList languageCodes;
  for (const QVariant &language : languages) {
    languageCodes.append(
        language.toMap().value(QStringLiteral("code")).toString());
  }
  QVERIFY(languageCodes.contains(QStringLiteral("de")));
  QVERIFY(languageCodes.contains(QStringLiteral("es")));
}

QTEST_MAIN(TestPreferences)

#include "test_preferences.moc"
