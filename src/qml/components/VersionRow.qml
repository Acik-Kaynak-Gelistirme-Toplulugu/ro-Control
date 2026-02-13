import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as Controls

// VersionRow — Shows a driver version with selection and compatibility status
// Used in Expert page for version selection

Rectangle {
    id: versionRow
    
    implicitHeight: 56
    radius: 6
    
    Layout.fillWidth: true
    
    property string version: ""
    property string status: "available"  // available | installed | selected | incompatible
    property string statusText: ""
    property bool selected: false
    
    color: {
        if (selected) return palette.highlight
        if (mouseArea.containsMouse) return palette.alternateBase
        return palette.base
    }
    
    Behavior on color {
        ColorAnimation { duration: 150 }
    }
    
    signal clicked()
    
    border.width: selected ? 2 : 1
    border.color: selected ? palette.highlight : palette.mid
    
    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: versionRow.clicked()
    }
    
    RowLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 12
        
        // Radio button or checkmark
        Rectangle {
            width: 20
            height: 20
            radius: 10
            color: versionRow.selected ? palette.highlight : "transparent"
            border.width: 2
            border.color: versionRow.selected ? palette.highlight : palette.mid
            
            Controls.Label {
                anchors.centerIn: parent
                text: versionRow.selected ? "✓" : ""
                color: palette.base
                font.bold: true
                font.pixelSize: 12
            }
        }
        
        // Version text
        ColumnLayout {
            spacing: 1
            Layout.fillWidth: true
            
            Controls.Label {
                text: versionRow.version
                font.bold: true
                font.pixelSize: 13
                color: versionRow.selected ? palette.base : palette.text
            }
            
            Controls.Label {
                text: versionRow.statusText
                font.pixelSize: 11
                opacity: 0.6
                color: versionRow.selected ? palette.base : palette.text
            }
        }
        
        // Status badge
        Rectangle {
            visible: versionRow.status !== "available"
            width: statusLabel.width + 8
            height: 24
            radius: 4
            
            color: {
                switch (versionRow.status) {
                    case "installed": return "#3327ae60"
                    case "selected": return "#332980b9"
                    case "incompatible": return "#33da4453"
                    default: return "transparent"
                }
            }
            
            border.width: 1
            border.color: {
                switch (versionRow.status) {
                    case "installed": return "#27ae60"
                    case "selected": return "#2980b9"
                    case "incompatible": return "#da4453"
                    default: return "transparent"
                }
            }
            
            Controls.Label {
                id: statusLabel
                anchors.centerIn: parent
                text: {
                    switch (versionRow.status) {
                        case "installed": return "✓ Installed"
                        case "selected": return "Selected"
                        case "incompatible": return "⚠ Incompatible"
                        default: return ""
                    }
                }
                font.pixelSize: 11
                color: {
                    switch (versionRow.status) {
                        case "installed": return "#27ae60"
                        case "selected": return "#2980b9"
                        case "incompatible": return "#da4453"
                        default: return palette.text
                    }
                }
            }
        }
    }
}
