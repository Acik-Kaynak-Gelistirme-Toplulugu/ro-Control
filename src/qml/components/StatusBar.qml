// qmllint disable unqualified
pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as Controls
import io.github.AcikKaynakGelistirmeToplulugu.rocontrol

Rectangle {
    id: root

    property var items: []
    property string barType: "normal"

    implicitHeight: 48
    color: {
        switch (barType) {
        case "warning":
            return Qt.rgba(Theme.warning.r, Theme.warning.g, Theme.warning.b, 0.1);
        case "error":
            return Qt.rgba(Theme.error.r, Theme.error.g, Theme.error.b, 0.1);
        case "success":
            return Qt.rgba(Theme.success.r, Theme.success.g, Theme.success.b, 0.1);
        default:
            return Theme.cardGlass;
        }
    }

    Rectangle {
        anchors.bottom: parent.bottom
        width: parent.width
        height: 1
        color: {
            switch (root.barType) {
            case "warning":
                return Qt.rgba(Theme.warning.r, Theme.warning.g, Theme.warning.b, 0.3);
            case "error":
                return Qt.rgba(Theme.error.r, Theme.error.g, Theme.error.b, 0.3);
            case "success":
                return Qt.rgba(Theme.success.r, Theme.success.g, Theme.success.b, 0.3);
            default:
                return Theme.border;
            }
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 24
        anchors.rightMargin: 24
        spacing: 20

        Controls.Label {
            visible: root.barType !== "normal"
            text: {
                switch (root.barType) {
                case "warning":
                    return "⚠️";
                case "error":
                    return "❌";
                case "success":
                    return "✅";
                default:
                    return "";
                }
            }
            font.pixelSize: 16
            SequentialAnimation on scale {
                running: root.barType === "warning" || root.barType === "error"
                loops: Animation.Infinite
                NumberAnimation {
                    from: 1.0
                    to: 1.2
                    duration: 1000
                }
                NumberAnimation {
                    from: 1.2
                    to: 1.0
                    duration: 1000
                }
            }
        }

        Repeater {
            model: root.items
            RowLayout {
                id: statusDelegate
                spacing: 12
                required property var modelData
                Controls.Label {
                    text: statusDelegate.modelData.label + ":"
                    font.pixelSize: 14
                    font.weight: Font.Medium
                    color: Theme.mutedForeground
                }
                Rectangle {
                    implicitHeight: 24
                    implicitWidth: _vLbl.width + 24
                    radius: 8
                    color: Theme.muted
                    Controls.Label {
                        id: _vLbl
                        anchors.centerIn: parent
                        text: statusDelegate.modelData.value
                        font.pixelSize: 14
                        font.weight: Font.Bold
                        color: Theme.foreground
                    }
                }
            }
        }
        Item {
            Layout.fillWidth: true
        }
    }

    opacity: 0
    y: -20
    Component.onCompleted: _slideIn.start()
    ParallelAnimation {
        id: _slideIn
        NumberAnimation {
            target: root
            property: "opacity"
            from: 0
            to: 1
            duration: 300
            easing.type: Easing.OutCubic
        }
        NumberAnimation {
            target: root
            property: "y"
            from: -20
            to: 0
            duration: 300
            easing.type: Easing.OutCubic
        }
    }
}
