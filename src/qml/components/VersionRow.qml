import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as Controls

Rectangle {
    id: vr

    implicitHeight: 50
    radius: 8
    Layout.fillWidth: true

    property string version: ""
    property string status: "available"
    property string statusText: ""
    property string source: "repo"
    property bool installable: true
    property bool selected: false
    property bool darkMode: false

    color: {
        if (selected) return darkMode ? "#1a3a52" : "#deeffe";
        if (mouseArea.containsMouse) return darkMode ? "#2c3440" : "#eef1f5";
        return "transparent";
    }
    border.width: selected ? 1 : 0
    border.color: selected ? "#3daee9" : "transparent"

    Behavior on color { ColorAnimation { duration: 120 } }

    signal clicked

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: vr.clicked()
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        spacing: 10

        Rectangle {
            Layout.preferredWidth: 16
            Layout.preferredHeight: 16
            radius: 8
            color: "transparent"
            border.width: 2
            border.color: vr.selected ? "#3daee9" : (darkMode ? "#6e7681" : "#8c959f")

            Rectangle {
                anchors.centerIn: parent
                width: 8; height: 8; radius: 4
                color: "#3daee9"
                visible: vr.selected
                scale: vr.selected ? 1.0 : 0.0
                Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }
            }
        }

        ColumnLayout {
            spacing: 1
            Layout.fillWidth: true

            RowLayout {
                spacing: 6

                Controls.Label {
                    text: vr.version
                    font.pixelSize: 14
                    font.weight: Font.DemiBold
                    color: darkMode ? "#e6edf3" : "#1f2328"
                }

                Rectangle {
                    visible: vr.source === "nvidia-official"
                    implicitWidth: nvBadge.implicitWidth + 10
                    implicitHeight: 16; radius: 8
                    color: darkMode ? "#162d1f" : "#dafbe1"
                    Controls.Label {
                        id: nvBadge; anchors.centerIn: parent
                        text: "NVIDIA"; font.pixelSize: 9; font.weight: Font.Bold
                        color: darkMode ? "#3fb950" : "#1a7f37"
                    }
                }

                Rectangle {
                    visible: !vr.installable && vr.source !== "repo"
                    implicitWidth: naBadge.implicitWidth + 10
                    implicitHeight: 16; radius: 8
                    color: darkMode ? "#2d2310" : "#fff8c5"
                    Controls.Label {
                        id: naBadge; anchors.centerIn: parent
                        text: qsTr("Repo N/A"); font.pixelSize: 9; font.weight: Font.Bold
                        color: darkMode ? "#d29922" : "#bf8700"
                    }
                }
            }

            Controls.Label {
                visible: vr.statusText.length > 0
                text: vr.statusText
                font.pixelSize: 12
                color: darkMode ? "#6e7681" : "#8c959f"
                elide: Text.ElideRight
                Layout.fillWidth: true
            }
        }

        Rectangle {
            visible: vr.status === "installed"
            implicitWidth: instLabel.implicitWidth + 14
            implicitHeight: 20; radius: 10
            color: darkMode ? "#162d1f" : "#dafbe1"
            Controls.Label {
                id: instLabel; anchors.centerIn: parent
                text: qsTr("Installed"); font.pixelSize: 10; font.weight: Font.DemiBold
                color: darkMode ? "#3fb950" : "#1a7f37"
            }
        }

        Controls.Label {
            visible: vr.status !== "installed"
            text: vr.installable ? "\u25CF" : "\u25CB"
            color: vr.installable
                ? (darkMode ? "#3fb950" : "#1a7f37")
                : (darkMode ? "#d29922" : "#bf8700")
            font.pixelSize: 12
        }
    }
}
