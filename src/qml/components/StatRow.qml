import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as Controls

RowLayout {
    id: statRow
    spacing: 12
    Layout.fillWidth: true

    property string label: ""
    property string value: ""
    property real fraction: 0.0
    property bool darkMode: false

    readonly property color barColor: {
        if (fraction > 0.85) return darkMode ? "#f85149" : "#cf222e";
        if (fraction > 0.65) return darkMode ? "#d29922" : "#bf8700";
        return "#3daee9";
    }

    Controls.Label {
        text: statRow.label
        color: statRow.darkMode ? "#8b949e" : "#656d76"
        font.pixelSize: 13
        Layout.preferredWidth: 100
    }

    Item {
        Layout.fillWidth: true
        implicitHeight: 6

        Rectangle {
            anchors.fill: parent
            radius: 3
            color: statRow.darkMode ? "#1b2028" : "#e8ebef"
        }

        Rectangle {
            width: Math.max(0, Math.min(1, statRow.fraction)) * parent.width
            height: parent.height
            radius: 3
            color: statRow.barColor

            Behavior on width {
                NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
            }
            Behavior on color {
                ColorAnimation { duration: 300 }
            }
        }
    }

    Controls.Label {
        text: statRow.value
        font.pixelSize: 13
        font.weight: Font.Medium
        color: statRow.darkMode ? "#e6edf3" : "#1f2328"
        Layout.preferredWidth: 100
        horizontalAlignment: Text.AlignRight
    }
}
