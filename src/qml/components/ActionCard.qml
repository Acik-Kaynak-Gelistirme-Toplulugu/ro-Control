// qmllint disable unqualified
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as Controls
import io.github.AcikKaynakGelistirmeToplulugu.rocontrol

Controls.Button {
    id: root

    property string iconEmoji: ""
    property string cardTitle: ""
    property string description: ""
    property string statusText: ""
    property color statusColor: "#10b981"
    property bool selected: false
    property bool showGradientOverlay: false

    implicitHeight: 140

    background: Rectangle {
        color: Theme.card
        radius: 16
        border.width: root.selected ? 2 : 1
        border.color: root.selected ? Theme.primary : Theme.border

        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            opacity: root.hovered && root.showGradientOverlay ? 0.05 : 0
            gradient: Gradient {
                GradientStop {
                    position: 0.0
                    color: Theme.primary
                }
                GradientStop {
                    position: 1.0
                    color: Theme.accent
                }
                orientation: Gradient.Horizontal
            }
            Behavior on opacity {
                NumberAnimation {
                    duration: 300
                }
            }
        }

        Rectangle {
            visible: root.selected
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: 3
            radius: 6
            gradient: Gradient {
                GradientStop {
                    position: 0.0
                    color: Theme.primary
                }
                GradientStop {
                    position: 1.0
                    color: Theme.accent
                }
            }
        }

        scale: root.pressed ? 0.98 : (root.hovered ? 1.01 : 1.0)
        Behavior on scale {
            NumberAnimation {
                duration: 150
                easing.type: Easing.OutCubic
            }
        }
        Behavior on border.color {
            ColorAnimation {
                duration: 300
            }
        }
    }

    contentItem: RowLayout {
        spacing: 16

        Rectangle {
            Layout.preferredWidth: 40
            Layout.preferredHeight: 40
            Layout.alignment: Qt.AlignTop
            radius: 12
            gradient: Gradient {
                GradientStop {
                    position: 0.0
                    color: root.statusColor
                }
                GradientStop {
                    position: 1.0
                    color: Qt.darker(root.statusColor, 1.2)
                }
            }

            Controls.Label {
                anchors.centerIn: parent
                text: root.iconEmoji
                font.pixelSize: 20
            }

            rotation: root.hovered ? _rotObj.angle : 0
            Behavior on rotation {
                NumberAnimation {
                    duration: 150
                }
            }
            QtObject {
                id: _rotObj
                property real angle: 0
            }
            Timer {
                running: root.hovered
                repeat: true
                interval: 50
                onTriggered: _rotObj.angle = Math.sin(Date.now() / 200) * 5
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignTop
            spacing: 12

            Controls.Label {
                text: root.cardTitle
                font.pixelSize: 16
                font.weight: Font.Bold
                color: Theme.foreground
                Layout.fillWidth: true
            }

            Controls.Label {
                text: root.description
                font.pixelSize: 14
                color: Theme.mutedForeground
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
                lineHeight: 1.4
            }

            Rectangle {
                visible: root.statusText !== ""
                Layout.topMargin: 8
                implicitHeight: 28
                implicitWidth: _statusLbl.width + 16
                radius: 8
                color: Qt.rgba(root.statusColor.r, root.statusColor.g, root.statusColor.b, 0.1)
                border.width: 1
                border.color: Qt.rgba(root.statusColor.r, root.statusColor.g, root.statusColor.b, 0.3)

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 8
                    Rectangle {
                        implicitWidth: 4
                        implicitHeight: 4
                        radius: 2
                        color: root.statusColor
                    }
                    Controls.Label {
                        id: _statusLbl
                        text: root.statusText
                        font.pixelSize: 12
                        font.weight: Font.Bold
                        color: root.statusColor
                    }
                }

                SequentialAnimation on scale {
                    running: root.statusText !== ""
                    loops: Animation.Infinite
                    NumberAnimation {
                        from: 1.0
                        to: 1.05
                        duration: 1000
                    }
                    NumberAnimation {
                        from: 1.05
                        to: 1.0
                        duration: 1000
                    }
                }
            }
        }
    }
}
