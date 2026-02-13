import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as Controls

// StepItem — Single step in progress display
// Shows status: pending (○), running (⏳), done (✓), error (✗)

RowLayout {
    id: stepItem
    
    Layout.fillWidth: true
    spacing: 12
    
    property string text: ""
    property string status: "pending"  // pending | running | done | error
    
    readonly property color statusColor: {
        switch (status) {
            case "done": return "#27ae60"
            case "running": return "#2980b9"
            case "error": return "#da4453"
            default: return palette.mid
        }
    }
    
    readonly property string statusIcon: {
        switch (status) {
            case "done": return "✓"
            case "running": return "⏳"
            case "error": return "✗"
            default: return "○"
        }
    }
    
    // Status circle
    Rectangle {
        width: 24
        height: 24
        radius: 12
        color: stepItem.statusColor
        opacity: stepItem.status === "pending" ? 0.2 : 0.15
        border.width: 2
        border.color: stepItem.statusColor
        
        Controls.Label {
            anchors.centerIn: parent
            text: stepItem.statusIcon
            color: stepItem.statusColor
            font.pixelSize: 12
            font.bold: true
        }
    }
    
    // Text
    Controls.Label {
        text: stepItem.text
        opacity: stepItem.status === "done" ? 0.7 : 
                stepItem.status === "error" ? 1.0 : 0.6
        color: stepItem.status === "error" ? stepItem.statusColor : palette.text
        Layout.fillWidth: true
    }
    
    Item { Layout.fillWidth: true }
}
