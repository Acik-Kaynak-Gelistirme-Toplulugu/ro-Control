import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as Controls

Controls.Button {
    id: root

    property string iconEmoji: ""
    property string cardTitle: ""
    property string description: ""
    property string statusText: ""
    property color statusColor: "#10b981"
    property bool selected: false
    property bool showGradientOverlay: false
    property bool darkMode: false

    readonly property color cCard:    darkMode ? "#1e293b" : "#fcfcfc"
    readonly property color cBorder:  darkMode ? "#334155" : "#e5e7eb"
    readonly property color cFg:      darkMode ? "#e2e8f0" : "#1a1d23"
    readonly property color cMutedFg: darkMode ? "#94a3b8" : "#64748b"
    readonly property color cPrimary: darkMode ? "#60a5fa" : "#3b82f6"
    readonly property color cAccent:  darkMode ? "#a78bfa" : "#8b5cf6"
    readonly property color cMuted:   darkMode ? "#1e293b" : "#f1f5f9"

    implicitHeight: 140

    background: Rectangle {
        color: root.cCard
        radius: 16
        border.width: root.selected ? 2 : 1
        border.color: root.selected ? root.cPrimary : root.cBorder

        Rectangle {
            anchors.fill: parent; radius: parent.radius
            opacity: root.hovered && root.showGradientOverlay ? 0.05 : 0
            gradient: Gradient {
                GradientStop { position: 0.0; color: root.cPrimary }
                GradientStop { position: 1.0; color: root.cAccent }
                orientation: Gradient.Horizontal
            }
            Behavior on opacity { NumberAnimation { duration: 300 } }
        }

        Rectangle {
            visible: root.selected
            anchors.right: parent.right
            anchors.top: parent.top; anchors.bottom: parent.bottom
            width: 3; radius: 6
            gradient: Gradient {
                GradientStop { position: 0.0; color: root.cPrimary }
                GradientStop { position: 1.0; color: root.cAccent }
            }
        }

        scale: root.pressed ? 0.98 : (root.hovered ? 1.01 : 1.0)
        Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
        Behavior on border.color { ColorAnimation { duration: 300 } }
    }

    contentItem: RowLayout {
        spacing: 16

        Rectangle {
            Layout.preferredWidth: 40; Layout.preferredHeight: 40
            Layout.alignment: Qt.AlignTop
            radius: 12
            gradient: Gradient {
                GradientStop { position: 0.0; color: root.statusColor }
                GradientStop { position: 1.0; color: Qt.darker(root.statusColor, 1.2) }
            }

            Controls.Label {
                anchors.centerIn: parent
                text: root.iconEmoji; font.pixelSize: 20
            }

            rotation: root.hovered ? _rotObj.angle : 0
            Behavior on rotation { NumberAnimation { duration: 150 } }
            QtObject { id: _rotObj; property real angle: 0 }
            Timer {
                running: root.hovered; repeat: true; interval: 50
                onTriggered: _rotObj.angle = Math.sin(Date.now() / 200) * 5
            }
        }

        ColumnLayout {
            Layout.fillWidth: true; Layout.alignment: Qt.AlignTop
            spacing: 12

            Controls.Label {
                text: root.cardTitle
                font.pixelSize: 16; font.weight: Font.Bold
                color: root.cFg; Layout.fillWidth: true
            }

            Controls.Label {
                text: root.description
                font.pixelSize: 14; color: root.cMutedFg
                wrapMode: Text.WordWrap; Layout.fillWidth: true; lineHeight: 1.4
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
                    anchors.fill: parent; anchors.margins: 8; spacing: 8
                    Rectangle { width: 4; height: 4; radius: 2; color: root.statusColor }
                    Controls.Label {
                        id: _statusLbl; text: root.statusText
                        font.pixelSize: 12; font.weight: Font.Bold; color: root.statusColor
                    }
                }

                SequentialAnimation on scale {
                    running: root.statusText !== ""; loops: Animation.Infinite
                    NumberAnimation { from: 1.0; to: 1.05; duration: 1000 }
                    NumberAnimation { from: 1.05; to: 1.0; duration: 1000 }
                }
            }
        }
    }
}
