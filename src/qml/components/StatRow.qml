import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as Controls

// StatRow — Reusable metric row with label, progress bar, and value

RowLayout {
    id: statRow
    spacing: 12
    Layout.fillWidth: true

    property string label: ""
    property string value: ""
    property real fraction: 0.0  // 0.0 to 1.0

    // Color based on value: green < 60%, yellow < 85%, red >= 85%
    readonly property color barColor: {
        if (fraction < 0.6) return "#27ae60"
        if (fraction < 0.85) return "#f39c12"
        return "#da4453"
    }

    Controls.Label {
        text: statRow.label
        opacity: 0.7
        Layout.preferredWidth: 90
    }

    Controls.ProgressBar {
        Layout.fillWidth: true
        from: 0.0
        to: 1.0
        value: statRow.fraction

        background: Rectangle {
            implicitHeight: 8
            radius: 4
            color: palette.alternateBase
        }

        contentItem: Item {
            implicitHeight: 8

            Rectangle {
                width: statRow.fraction * parent.width
                height: parent.height
                radius: 4
                color: statRow.barColor
            }
        }
    }

    Controls.Label {
        text: statRow.value
        font.pixelSize: 12
        opacity: 0.6
        Layout.preferredWidth: 80
        horizontalAlignment: Text.AlignRight
    }
}
