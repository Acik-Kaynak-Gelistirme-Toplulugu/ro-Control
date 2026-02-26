import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as Controls

Rectangle {
    id: root

    property string status: "pending"  // pending, running, done, error
    property string label: ""
    property bool darkMode: false

    readonly property color cPrimary: darkMode ? "#60a5fa" : "#3b82f6"
    readonly property color cSuccess: darkMode ? "#34d399" : "#10b981"
    readonly property color cError:   darkMode ? "#f87171" : "#ef4444"
    readonly property color cMuted:   darkMode ? "#1e293b" : "#f1f5f9"
    readonly property color cFg:      darkMode ? "#e2e8f0" : "#1a1d23"

    implicitHeight: 44
    implicitWidth: parent ? parent.width : 300
    radius: 12
    color: {
        switch(status) {
            case "running": return Qt.rgba(cPrimary.r, cPrimary.g, cPrimary.b, 0.1)
            case "done":    return Qt.rgba(cSuccess.r, cSuccess.g, cSuccess.b, 0.1)
            case "error":   return Qt.rgba(cError.r, cError.g, cError.b, 0.1)
            default:        return Qt.rgba(cMuted.r, cMuted.g, cMuted.b, 0.3)
        }
    }
    Behavior on color { ColorAnimation { duration: 300 } }

    RowLayout {
        anchors.fill: parent; anchors.margins: 12; spacing: 12

        Controls.Label {
            Layout.preferredWidth: 20; Layout.preferredHeight: 20
            text: {
                switch(root.status) {
                    case "running": return "⏳"
                    case "done":    return "✅"
                    case "error":   return "❌"
                    default:        return "⭕"
                }
            }
            font.pixelSize: 16
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter

            RotationAnimator on rotation {
                running: root.status === "running"
                from: 0; to: 360; duration: 2000; loops: Animation.Infinite
            }
        }

        Controls.Label {
            Layout.fillWidth: true; text: root.label
            font.pixelSize: 14; font.weight: Font.Medium
            color: root.status === "error" ? root.cError : root.cFg
        }

        Rectangle {
            visible: root.status === "running"
            Layout.preferredWidth: 8; Layout.preferredHeight: 8; radius: 4
            color: root.cPrimary

            SequentialAnimation on scale {
                running: root.status === "running"; loops: Animation.Infinite
                NumberAnimation { from: 1.0; to: 1.5; duration: 750 }
                NumberAnimation { from: 1.5; to: 1.0; duration: 750 }
            }
            SequentialAnimation on opacity {
                running: root.status === "running"; loops: Animation.Infinite
                NumberAnimation { from: 1.0; to: 0.5; duration: 750 }
                NumberAnimation { from: 0.5; to: 1.0; duration: 750 }
            }
        }

        Rectangle {
            visible: root.status === "done"
            Layout.preferredWidth: 8; Layout.preferredHeight: 8; radius: 4
            color: root.cSuccess

            NumberAnimation on scale {
                id: _doneAnim; running: root.status === "done"
                from: 0.0; to: 1.0; duration: 300; easing.type: Easing.OutBack
            }
        }
    }

    // Slide-in animation
    opacity: 0; x: -20
    Component.onCompleted: _slideIn.start()
    ParallelAnimation {
        id: _slideIn
        NumberAnimation { target: root; property: "opacity"; from: 0; to: 1; duration: 300; easing.type: Easing.OutCubic }
        NumberAnimation { target: root; property: "x"; from: -20; to: 0; duration: 300; easing.type: Easing.OutBack }
    }
}
