import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as Controls

// WarningBanner — Alert/warning message with colored background
// Types: warning | error | info | success

Rectangle {
    id: banner
    
    implicitHeight: 48
    radius: 8
    
    Layout.fillWidth: true
    
    property string type: "warning"  // warning | error | info | success
    property string text: ""
    
    readonly property color bgColor: {
        switch (type) {
            case "error": return "#33da4453"
            case "success": return "#3327ae60"
            case "info": return "#332980b9"
            default: return "#33f39c12"
        }
    }
    
    readonly property color borderColor: {
        switch (type) {
            case "error": return "#da4453"
            case "success": return "#27ae60"
            case "info": return "#2980b9"
            default: return "#f39c12"
        }
    }
    
    readonly property string icon: {
        switch (type) {
            case "error": return "✗"
            case "success": return "✓"
            case "info": return "ℹ"
            default: return "⚠"
        }
    }
    
    color: bgColor
    border.width: 1
    border.color: borderColor
    
    RowLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 12
        
        Controls.Label {
            text: banner.icon
            font.pixelSize: 18
            color: banner.borderColor
        }
        
        Controls.Label {
            text: banner.text
            color: banner.borderColor
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
        }
    }
}
