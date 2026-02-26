use cxx_qt_build::{CxxQtBuilder, QmlModule};

fn main() {
    CxxQtBuilder::new()
        .qml_module(QmlModule {
            uri: "io.github.AcikKaynakGelistirmeToplulugu.rocontrol",
            qml_files: &[
                // Main + Theme
                "src/qml/Main.qml",
                "src/qml/Theme.qml",
                // Components
                "src/qml/components/ActionCard.qml",
                "src/qml/components/CustomProgressBar.qml",
                "src/qml/components/GradientButton.qml",
                "src/qml/components/StatusBar.qml",
                "src/qml/components/StepItem.qml",
                // Pages
                "src/qml/pages/InstallPage.qml",
                "src/qml/pages/ExpertPage.qml",
                "src/qml/pages/PerfPage.qml",
                "src/qml/pages/ProgressPage.qml",
            ],
            rust_files: &["src/bridge.rs"],
            ..Default::default()
        })
        .build();
}
