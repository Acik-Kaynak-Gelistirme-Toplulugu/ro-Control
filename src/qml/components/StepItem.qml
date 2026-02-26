import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as Controls

RowLayout {
    id: stepItem
    Layout.fillWidth: true
    spacing: 10

    property string text: ""
    property string status: "pending"
    property bool darkMode: false

    readonly property color statusColor: {
        switch (status) {
        case "done":    return darkMode ? "#3fb950" : "#1a7f37";
        case "running": return "#3daee9";
        case "error":   return darkMode ? "#f85149" : "#cf222e";
        default:        return darkMode ? "#6e7681" : "#8c959f";
        }
    }

    readonly property string statusIcon: {
        switch (status) {
        case "done":    return "\u2713";
        case "running": return "\u25CF";
        case "error":   return "\u2715";
        default:        return "\u25CB";
        }
    }

    Controls.Label {
        text: stepItem.statusIcon
        color: stepItem.statusColor
        font.pixelSize: 14
        font.weight: Font.DemiBold
        Layout.preferredWidth: 20
        horizontalAlignment: Text.AlignHCenter

        SequentialAnimation on opacity {
            running: stepItem.status === "running"
            loops: Animation.Infinite
            NumberAnimation { to: 0.3; duration: 600; easing.type: Easing.InOutSine }
            NumberAnimation { to: 1.0; duration: 600; easing.type: Easing.InOutSine }
        }
    }

    Controls.Label {
        text: stepItem.text
        font.pixelSize: 13
        font.family: "monospace"
        color: stepItem.status === "done"
            ? (darkMode ? "#8b949e" : "#656d76")
            : stepItem.status === "error"
                ? stepItem.statusColor
                : (darkMode ? "#e6edf3" : "#1f2328")
        opacity: stepItem.status === "pending" ? 0.5 : 1.0
        Layout.fillWidth: true
    }
}
