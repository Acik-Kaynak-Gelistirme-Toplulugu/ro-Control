import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as Controls

Rectangle {
    id: card

    implicitHeight: 72
    radius: 10
    border.width: 1

    property string title: ""
    property string description: ""
    property string icon: "\u2713"
    property color accentColor: "#3daee9"
    property bool enabled: true
    property bool darkMode: false

    color: mouseArea.containsMouse && card.enabled
        ? (darkMode ? "#2c3440" : "#eef1f5")
        : (darkMode ? "#242b35" : "#ffffff")
    border.color: darkMode ? "#313840" : "#d0d7de"
    opacity: card.enabled ? 1.0 : 0.5

    Behavior on color { ColorAnimation { duration: 120 } }

    signal clicked

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: card.enabled
        cursorShape: card.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: if (card.enabled) card.clicked()
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 14

        Rectangle {
            Layout.preferredWidth: 42
            Layout.preferredHeight: 42
            radius: 10
            color: Qt.rgba(card.accentColor.r, card.accentColor.g, card.accentColor.b,
                           darkMode ? 0.15 : 0.1)

            Controls.Label {
                anchors.centerIn: parent
                text: card.icon
                font.pixelSize: 18
                color: card.accentColor
            }
        }

        ColumnLayout {
            spacing: 2
            Layout.fillWidth: true

            Controls.Label {
                text: card.title
                font.pixelSize: 14
                font.weight: Font.DemiBold
                color: darkMode ? "#e6edf3" : "#1f2328"
            }

            Controls.Label {
                text: card.description
                font.pixelSize: 12
                color: darkMode ? "#8b949e" : "#656d76"
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
            }
        }

        Controls.Label {
            text: "\u203A"
            font.pixelSize: 18
            color: darkMode ? "#6e7681" : "#8c959f"
        }
    }
}
