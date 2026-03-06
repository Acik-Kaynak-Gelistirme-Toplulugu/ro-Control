import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 14

        Label {
            text: "Surucu Teyit"
            font.pixelSize: 24
            font.bold: true
        }

        RowLayout {
            spacing: 10

            Label {
                text: "GPU: " + (nvidiaDetector.gpuFound ? nvidiaDetector.gpuName : "Tespit edilemedi")
                wrapMode: Text.Wrap
                Layout.fillWidth: true
            }
        }

        Label {
            text: "Surucu versiyonu: " + (nvidiaDetector.driverVersion.length > 0 ? nvidiaDetector.driverVersion : "Yok")
            wrapMode: Text.Wrap
        }

        Label {
            text: "Secure Boot: " + (nvidiaDetector.secureBootEnabled ? "Acik" : "Kapali/Bilinmiyor")
            color: nvidiaDetector.secureBootEnabled ? "#c43a3a" : "#2b8a3e"
            font.bold: true
        }

        Rectangle {
            Layout.fillWidth: true
            radius: 8
            border.width: 1
            border.color: "#5f6b86"
            color: "transparent"
            implicitHeight: reportLabel.implicitHeight + 20

            Label {
                id: reportLabel
                anchors.fill: parent
                anchors.margins: 10
                text: nvidiaDetector.verificationReport
                wrapMode: Text.Wrap
            }
        }

        RowLayout {
            spacing: 10

            Button {
                text: "Yeniden Tara"
                onClicked: nvidiaDetector.refresh()
            }

            Button {
                text: "Guncelleme Kontrol Et"
                onClicked: nvidiaUpdater.checkForUpdate()
            }

            Label {
                visible: nvidiaUpdater.updateAvailable
                text: "Yeni surum: " + nvidiaUpdater.latestVersion
                color: "#996c00"
            }
        }

        Label {
            visible: nvidiaDetector.secureBootEnabled
            text: "Uyari: Secure Boot acikken kapali kaynak surucu modulu yuklenmeyebilir."
            color: "#c43a3a"
            wrapMode: Text.Wrap
        }

        Item {
            Layout.fillHeight: true
        }
    }

    Component.onCompleted: nvidiaDetector.refresh()
}
