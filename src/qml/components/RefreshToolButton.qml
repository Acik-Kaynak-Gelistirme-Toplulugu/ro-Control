import QtQuick
import QtQuick.Controls

ToolButton {
    id: control

    required property var theme
    property real uiScale: 1.0
    property bool busy: false
    property string tooltip: qsTr("Refresh")

    implicitWidth: Math.round(40 * uiScale)
    implicitHeight: Math.round(40 * uiScale)
    display: AbstractButton.IconOnly
    opacity: enabled ? 1.0 : 0.55

    ToolTip.visible: hovered
    ToolTip.text: tooltip

    contentItem: Item {
        implicitWidth: Math.round(22 * control.uiScale)
        implicitHeight: Math.round(22 * control.uiScale)

        Image {
            id: refreshIcon
            anchors.centerIn: parent
            width: Math.round(20 * control.uiScale)
            height: Math.round(20 * control.uiScale)
            source: "qrc:/qt/qml/rocontrol/assets/icon-refresh.svg"
            fillMode: Image.PreserveAspectFit
            smooth: true
            antialiasing: true
            opacity: control.enabled ? 1.0 : 0.65
            scale: control.down ? 0.92 : control.hovered && control.enabled ? 1.06 : 1.0

            Behavior on scale {
                NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
            }

            RotationAnimator on rotation {
                running: control.busy
                from: 0
                to: 360
                duration: 900
                loops: Animation.Infinite
            }

            NumberAnimation on rotation {
                id: clickSpin
                from: refreshIcon.rotation
                to: refreshIcon.rotation + 180
                duration: 260
                easing.type: Easing.OutCubic
            }
        }
    }

    background: Rectangle {
        radius: width / 2
        color: !control.enabled ? "transparent"
              : control.down ? Qt.tint(control.theme.infoBg, "#18ffffff")
              : control.hovered ? Qt.tint(control.theme.infoBg, "#22ffffff")
              : control.theme.card
        border.width: 1
        border.color: control.hovered && control.enabled ? control.theme.accentA
                                                         : control.theme.border

        Behavior on color {
            ColorAnimation { duration: 140 }
        }

        Behavior on border.color {
            ColorAnimation { duration: 140 }
        }
    }

    onClicked: {
        if (!busy)
            clickSpin.restart();
    }
}
