use cxx_qt_build::{CxxQtBuilder, QmlModule};

fn main() {
    CxxQtBuilder::new()
        .qml_module(QmlModule {
            uri: "io.github.AcikKaynakGelistirmeToplulugu.rocontrol",
            qml_files: &[
                "src/qml/Main.qml",
                "src/qml/Theme.qml",
                "src/qml/components/StatRow.qml",
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
