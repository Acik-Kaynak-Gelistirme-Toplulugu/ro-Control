import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as Controls

Rectangle {
    id: root

    property var items: []
    property string barType: "normal"
    property bool darkMode: false

    readonly property color cCard:    darkMode ? "#1e293b" : "#fcfcfc"
    readonly property color cBorder:  darkMode ? "#334155" : "#e5e7eb"
    readonly property color cFg:      darkMode ? "#e2e8f0" : "#1a1d23"
    readonly property color cMutedFg: darkMode ? "#94a3b8" : "#64748b"
    readonly property color cMuted:   darkMode ? "#1e293b" : "#f1f5f9"
    readonly property color cSuccess: darkMode ? "#34d399" : "#10b981"
    readonly property color cWarning: darkMode ? "#fbbf24" : "#f59e0b"
    readonly property color cError:   darkMode ? "#f87171" : "#ef4444"

    implicitHeight: 48
    color: {
        switch(barType) {
            case "warning": return Qt.rgba(cWarning.r, cWarning.g, cWarning.b, 0.1)
            case "error":   return Qt.rgba(cError.r, cError.g, cError.b, 0.1)
            case "success": return Qt.rgba(cSuccess.r, cSuccess.g, cSuccess.b, 0.1)
            default:        return darkMode ? Qt.rgba(0.117, 0.16, 0.23, 0.8) : Qt.rgba(1, 1, 1, 0.9)
        }
    }

    Rectangle {
        anchors.bottom: parent.bottom; width: parent.width; height: 1
        color: {
            switch(root.barType) {
                case "warning": return Qt.rgba(root.cWarning.r, root.cWarning.g, root.cWarning.b, 0.3)
                case "error":   return Qt.rgba(root.cError.r, root.cError.g, root.cError.b, 0.3)
                case "success": return Qt.rgba(root.cSuccess.r, root.cSuccess.g, root.cSuccess.b, 0.3)
                default:        return root.cBorder
            }
        }
    }

    RowLayout {
        anchors.fill: parent; anchors.leftMargin: 24; anchors.rightMargin: 24; spacing: 20

        Controls.Label {
            visible: root.barType !== "normal"
            text: { switch(root.barType) { case "warning": return "⚠️"; case "error": return "❌"; case "success": return "✅"; default: return "" } }
            font.pixelSize: 16
            SequentialAnimation on scale {
                running: root.barType === "warning" || root.barType === "error"
                loops: Animation.Infinite
                NumberAnimation { from: 1.0; to: 1.2; duration: 1000 }
                NumberAnimation { from: 1.2; to: 1.0; duration: 1000 }
            }
        }

        Repeater {
            model: root.items
            RowLayout {
                spacing: 12
                required property var modelData
                Controls.Label {
                    text: modelData.label + ":"
                    font.pixelSize: 14; font.weight: Font.Medium; color: root.cMutedFg
                }
                Rectangle {
                    implicitHeight: 24; implicitWidth: _vLbl.width + 24
                    radius: 8; color: root.cMuted
                    Controls.Label {
                        id: _vLbl; anchors.centerIn: parent
                        text: modelData.value
                        font.pixelSize: 14; font.weight: Font.Bold; color: root.cFg
                    }
                }
            }
        }
        Item { Layout.fillWidth: true }
    }

    opacity: 0; y: -20
    Component.onCompleted: _slideIn.start()
    ParallelAnimation {
        id: _slideIn
        NumberAnimation { target: root; property: "opacity"; from: 0; to: 1; duration: 300; easing.type: Easing.OutCubic }
        NumberAnimation { target: root; property: "y"; from: -20; to: 0; duration: 300; easing.type: Easing.OutCubic }
    }
}
