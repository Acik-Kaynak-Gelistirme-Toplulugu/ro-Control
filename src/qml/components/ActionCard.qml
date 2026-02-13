import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as Controls

// ActionCard — Clickable card with icon, title, description
// Used in Install page for Express/Custom options

Rectangle {
    id: card
    
    implicitHeight: 80
    implicitWidth: 400
    
    radius: 8
    border.width: 1
    border.color: palette.mid
    color: if (mouseArea.containsMouse) palette.alternateBase; else palette.base
    
    // Visual feedback on hover/press
    Behavior on color {
        ColorAnimation { duration: 150 }
    }
    
    property string title: ""
    property string description: ""
    property string icon: "✓"
    property color accentColor: palette.highlight
    property bool enabled: true
    
    signal clicked()
    
    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: parent.enabled
        cursorShape: parent.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: {
            if (parent.enabled) card.clicked()
        }
    }
    
    RowLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 16
        
        // Icon box
        Rectangle {
            width: 48
            height: 48
            radius: 8
            color: card.accentColor
            opacity: card.enabled ? 0.15 : 0.05
            
            Controls.Label {
                anchors.centerIn: parent
                text: card.icon
                font.pixelSize: 20
                color: card.accentColor
                opacity: card.enabled ? 1.0 : 0.5
            }
        }
        
        // Content
        ColumnLayout {
            spacing: 2
            Layout.fillWidth: true
            
            Controls.Label {
                text: card.title
                font.bold: true
                font.pixelSize: 15
                color: palette.text
                opacity: card.enabled ? 1.0 : 0.5
            }
            
            Controls.Label {
                text: card.description
                opacity: card.enabled ? 0.6 : 0.3
                font.pixelSize: 12
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
            }
        }
        
        // Arrow
        Controls.Label {
            text: "›"
            font.pixelSize: 20
            opacity: card.enabled ? 0.3 : 0.1
        }
    }
}
