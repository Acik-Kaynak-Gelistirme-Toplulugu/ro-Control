// qmllint disable unresolved-type
// qmllint disable unqualified
import QtQuick
import QtQuick.Controls as Controls
import io.github.AcikKaynakGelistirmeToplulugu.rocontrol

Controls.Button {
    id: root

    property bool useGradient: false
    property color gradientStart: "#3b82f6"
    property color gradientEnd: Qt.darker("#3b82f6", 1.2)

    implicitHeight: 48

    background: Rectangle {
        radius: 16
        gradient: root.useGradient ? _grad : null
        color: root.useGradient ? "transparent" : (root.hovered ? Qt.darker(Theme.primary, 1.1) : Theme.primary)

        Gradient {
            id: _grad
            GradientStop {
                position: 0.0
                color: root.gradientStart
            }
            GradientStop {
                position: 1.0
                color: root.gradientEnd
            }
            orientation: Gradient.Horizontal
        }

        scale: root.pressed ? 0.98 : (root.hovered ? 1.02 : 1.0)
        Behavior on scale {
            NumberAnimation {
                duration: 150
                easing.type: Easing.OutCubic
            }
        }
        Behavior on color {
            ColorAnimation {
                duration: 300
            }
        }

        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            opacity: root.hovered ? 0.2 : 0
            gradient: Gradient {
                GradientStop {
                    position: _shimmer.pos - 0.3
                    color: "transparent"
                }
                GradientStop {
                    position: _shimmer.pos
                    color: "white"
                }
                GradientStop {
                    position: _shimmer.pos + 0.3
                    color: "transparent"
                }
                orientation: Gradient.Horizontal
            }
            Behavior on opacity {
                NumberAnimation {
                    duration: 300
                }
            }

            QtObject {
                id: _shimmer
                property real pos: -0.3
            }
            SequentialAnimation on _shimmer.pos {
                running: root.hovered
                loops: Animation.Infinite
                NumberAnimation {
                    from: -0.3
                    to: 1.3
                    duration: 2000
                }
            }
        }
    }

    contentItem: Controls.Label {
        text: root.text
        font.pixelSize: 16
        font.weight: Font.Bold
        color: "white"
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }
}
