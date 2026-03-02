// qmllint disable unqualified
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as Controls
import io.github.AcikKaynakGelistirmeToplulugu.rocontrol

Item {
    id: root

    property int value: 0
    property string label: ""
    property bool showValue: true
    property int thresholdYellow: 60
    property int thresholdRed: 85
    property bool animated: true


    implicitHeight: label !== "" || showValue ? 60 : 40

    ColumnLayout {
        anchors.fill: parent; spacing: 12

        RowLayout {
            visible: root.label !== "" || root.showValue
            Layout.fillWidth: true

            Controls.Label {
                visible: root.label !== ""
                text: root.label
                font.pixelSize: 14; font.weight: Font.Medium; color: Theme.foreground
            }
            Item { Layout.fillWidth: true }
            Controls.Label {
                visible: root.showValue
                text: root.value + "%"
                font.pixelSize: 14; font.weight: Font.Bold
                color: Theme.mutedForeground; font.family: "monospace"

                scale: _valTimer.running ? 1.2 : 1.0
                Behavior on scale { NumberAnimation { duration: 150 } }
            }
        }

        Rectangle {
            Layout.fillWidth: true; Layout.preferredHeight: 10
            radius: 5; color: Theme.muted

            Rectangle {
                id: _fill
                width: parent.width * Math.min(100, Math.max(0, root.value)) / 100
                height: parent.height; radius: parent.radius

                gradient: Gradient {
                    GradientStop {
                        position: 0.0
                        color: root.value >= root.thresholdRed ? Theme.error :
                               (root.value >= root.thresholdYellow ? Theme.warning : Theme.success)
                    }
                    GradientStop {
                        position: 1.0
                        color: root.value >= root.thresholdRed ? Qt.darker(Theme.error, 1.2) :
                               (root.value >= root.thresholdYellow ? Qt.darker(Theme.warning, 1.2) : Qt.darker(Theme.success, 1.2))
                    }
                    orientation: Gradient.Horizontal
                }

                Behavior on width {
                    enabled: root.animated
                    NumberAnimation { duration: 500; easing.type: Easing.OutCubic }
                }

                Rectangle {
                    anchors.fill: parent; radius: parent.radius
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: Qt.rgba(1,1,1,0.2) }
                        GradientStop { position: 0.5; color: Qt.rgba(1,1,1,0.1) }
                        GradientStop { position: 1.0; color: "transparent" }
                    }
                }

                Rectangle {
                    visible: root.animated && root.value > 0
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    width: 16; height: 16; radius: 8; color: "white"

                    SequentialAnimation on opacity {
                        running: root.animated && root.value > 0; loops: Animation.Infinite
                        NumberAnimation { from: 1.0; to: 0.5; duration: 750 }
                        NumberAnimation { from: 0.5; to: 1.0; duration: 750 }
                    }
                    SequentialAnimation on scale {
                        running: root.animated && root.value > 0; loops: Animation.Infinite
                        NumberAnimation { from: 1.0; to: 1.3; duration: 750 }
                        NumberAnimation { from: 1.3; to: 1.0; duration: 750 }
                    }
                }
            }
        }
    }

    Timer { id: _valTimer; interval: 200 }
    onValueChanged: _valTimer.restart()
}
