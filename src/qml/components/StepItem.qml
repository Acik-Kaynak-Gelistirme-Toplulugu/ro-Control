// qmllint disable unqualified
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as Controls
import io.github.AcikKaynakGelistirmeToplulugu.rocontrol

Rectangle {
    id: root

    property string status: "pending"  // pending, running, done, error
    property string label: ""

    implicitHeight: 44
    implicitWidth: parent ? parent.width : 300
    radius: 12
    color: {
        switch (status) {
        case "running":
            return Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.1);
        case "done":
            return Qt.rgba(Theme.success.r, Theme.success.g, Theme.success.b, 0.1);
        case "error":
            return Qt.rgba(Theme.error.r, Theme.error.g, Theme.error.b, 0.1);
        default:
            return Qt.rgba(Theme.muted.r, Theme.muted.g, Theme.muted.b, 0.3);
        }
    }
    Behavior on color {
        ColorAnimation {
            duration: 300
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 12

        Controls.Label {
            Layout.preferredWidth: 20
            Layout.preferredHeight: 20
            text: {
                switch (root.status) {
                case "running":
                    return "⏳";
                case "done":
                    return "✅";
                case "error":
                    return "❌";
                default:
                    return "⭕";
                }
            }
            font.pixelSize: 16
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter

            RotationAnimator on rotation {
                running: root.status === "running"
                from: 0
                to: 360
                duration: 2000
                loops: Animation.Infinite
            }
        }

        Controls.Label {
            Layout.fillWidth: true
            text: root.label
            font.pixelSize: 14
            font.weight: Font.Medium
            color: root.status === "error" ? Theme.error : Theme.foreground
        }

        Rectangle {
            visible: root.status === "running"
            Layout.preferredWidth: 8
            Layout.preferredHeight: 8
            radius: 4
            color: Theme.primary

            SequentialAnimation on scale {
                running: root.status === "running"
                loops: Animation.Infinite
                NumberAnimation {
                    from: 1.0
                    to: 1.5
                    duration: 750
                }
                NumberAnimation {
                    from: 1.5
                    to: 1.0
                    duration: 750
                }
            }
            SequentialAnimation on opacity {
                running: root.status === "running"
                loops: Animation.Infinite
                NumberAnimation {
                    from: 1.0
                    to: 0.5
                    duration: 750
                }
                NumberAnimation {
                    from: 0.5
                    to: 1.0
                    duration: 750
                }
            }
        }

        Rectangle {
            visible: root.status === "done"
            Layout.preferredWidth: 8
            Layout.preferredHeight: 8
            radius: 4
            color: Theme.success

            NumberAnimation on scale {
                id: _doneAnim
                running: root.status === "done"
                from: 0.0
                to: 1.0
                duration: 300
                easing.type: Easing.OutBack
            }
        }
    }

    // Slide-in animation
    opacity: 0
    x: -20
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
            property: "x"
            from: -20
            to: 0
            duration: 300
            easing.type: Easing.OutBack
        }
    }
}
