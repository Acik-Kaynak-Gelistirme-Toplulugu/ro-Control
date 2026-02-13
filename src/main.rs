// ro-control — NVIDIA GPU Driver Manager for KDE Plasma
//
// Entry point: initializes Qt6 application with QML UI

mod bridge;
mod config;
mod core;
mod utils;

use cxx_qt_lib::{QGuiApplication, QQmlApplicationEngine, QQuickStyle, QString, QUrl};
use cxx_qt_lib_extras::QApplication;

fn main() {
    // Initialize logging and i18n
    utils::logger::init();
    utils::i18n::init();

    // Create Qt Application
    let mut app = QApplication::new();
    let mut engine = QQmlApplicationEngine::new();

    // Associate with desktop file for taskbar integration
    QGuiApplication::set_desktop_file_name(&QString::from(config::APP_ID));

    // Use KDE Breeze style if no style override is set
    if std::env::var("QT_QUICK_CONTROLS_STYLE").is_err() {
        QQuickStyle::set_style(&QString::from("org.kde.desktop"));
    }

    // Load QML entry point
    if let Some(engine) = engine.as_mut() {
        engine.load(&QUrl::from(
            "qrc:/qt/qml/io/github/AcikKaynakGelistirmeToplulugu/rocontrol/src/qml/Main.qml",
        ));
    }

    // Run event loop
    if let Some(app) = app.as_mut() {
        app.exec();
    }
}
