import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../components" as Components

Item {
    id: page
    required property var systemInfo
    property var cpuMonitor: null
    property var gpuMonitor: null
    property var ramMonitor: null
    property var nvidiaDetector: null
    property var powerController: null

    property var theme: ({})
    property bool darkMode: false
    property bool showAdvancedInfo: true
    property real uiScale: 1.0
    property bool reportCopied: false

    readonly property color bgColor: theme && theme.card ? theme.card : (page.darkMode ? "#29233B" : "#FFFFFF")
    readonly property color cardColor: theme && theme.cardStrong ? theme.cardStrong : (page.darkMode ? "#342D4A" : "#F1F5F9")
    readonly property color borderColor: theme && theme.border ? theme.border : (page.darkMode ? "#4D436B" : "#CBD5E1")
    readonly property color textColor: theme && theme.text ? theme.text : (page.darkMode ? "#F8FAFC" : "#0F172A")
    readonly property color softTextColor: theme && theme.textSoft ? theme.textSoft : (page.darkMode ? "#94A3B8" : "#64748B")
    readonly property color accentColor: theme && theme.accentA ? theme.accentA : (page.darkMode ? "#818CF8" : "#4F46E5")
    readonly property color infoBg: theme && theme.infoBg ? theme.infoBg : (page.darkMode ? "#1E2548" : "#EFF6FF")
    readonly property color successColor: theme && theme.success ? theme.success : (page.darkMode ? "#4ADE80" : "#059669")
    readonly property color warningColor: theme && theme.warning ? theme.warning : (page.darkMode ? "#FBBF24" : "#D97706")

    function safeText(value) {
        return value && value.length > 0 ? value : qsTr("Unavailable");
    }

    function deviceAndPowerSummary() {
        const dev = page.safeText(page.systemInfo ? page.systemInfo.deviceType : "");
        const pwr = page.systemInfo && page.systemInfo.powerSource ? page.systemInfo.powerSource : "";
        return pwr.length > 0 ? (dev + " • " + pwr) : dev;
    }

    function nvidiaDriverSummary() {
        const ver = page.safeText(page.nvidiaDetector ? page.nvidiaDetector.driverVersion : "");
        const src = page.nvidiaDetector ? page.nvidiaDetector.installedDriverSourceLabel : "";
        return (src.length > 0 && src !== "None") ? (ver + " (" + src + ")") : ver;
    }

    function platformSecuritySummary() {
        const virt = (page.systemInfo && page.systemInfo.virtualMachine) ? page.systemInfo.virtualizationType : qsTr("Bare Metal");
        const sb = (page.nvidiaDetector && page.nvidiaDetector.secureBootKnown)
                 ? (page.nvidiaDetector.secureBootEnabled ? qsTr("Secure Boot: On") : qsTr("Secure Boot: Off"))
                 : "";
        return sb.length > 0 ? (virt + " • " + sb) : virt;
    }

    function copyDiagnosticReport() {
        if (!page.systemInfo)
            return;

        const gpu = page.nvidiaDetector
                  ? (page.nvidiaDetector.gpuFound ? page.nvidiaDetector.gpuName : page.safeText(page.nvidiaDetector.displayAdapterName))
                  : "";
        const drv = page.nvidiaDriverSummary();
        const vram = (page.gpuMonitor && page.gpuMonitor.memoryTotalMiB > 0)
                   ? ((page.gpuMonitor.memoryTotalMiB / 1024.0).toFixed(1) + " GB (" + page.gpuMonitor.memoryTotalMiB + " MiB)")
                   : "";
        const ram = (page.ramMonitor && page.ramMonitor.totalMiB > 0)
                  ? ((page.ramMonitor.totalMiB / 1024.0).toFixed(1) + " GB (" + page.ramMonitor.totalMiB + " MiB)")
                  : "";
        const pcie = page.gpuMonitor ? page.gpuMonitor.pcieLinkStatus : "";
        const sec = page.platformSecuritySummary();

        const report = page.systemInfo.generateSystemReport(gpu, drv, vram, ram, pcie, sec);
        page.systemInfo.copyToClipboard(report);
        page.reportCopied = true;
        copiedFeedbackTimer.restart();
    }

    Timer {
        id: copiedFeedbackTimer
        interval: 3000
        repeat: false
        onTriggered: page.reportCopied = false
    }

    ScrollView {
        id: pageScroll
        anchors.fill: parent
        clip: true
        contentWidth: availableWidth

        ColumnLayout {
            width: pageScroll.availableWidth
            spacing: Math.round(14 * page.uiScale)

            // Section 1: Hardware Specifications
            Rectangle {
                Layout.fillWidth: true
                radius: 14
                color: page.cardColor
                border.width: 1
                border.color: page.borderColor
                implicitHeight: hwSectionLayout.implicitHeight + Math.round(24 * page.uiScale)

                ColumnLayout {
                    id: hwSectionLayout
                    anchors.fill: parent
                    anchors.margins: Math.round(14 * page.uiScale)
                    spacing: Math.round(12 * page.uiScale)

                    Label {
                        text: qsTr("Hardware Specifications")
                        color: page.textColor
                        font.pixelSize: Math.round(16 * page.uiScale)
                        font.weight: Font.DemiBold
                        Layout.fillWidth: true
                    }

                    GridLayout {
                        Layout.fillWidth: true
                        columns: width > 920 ? 3 : (width > 560 ? 2 : 1)
                        columnSpacing: Math.round(8 * page.uiScale)
                        rowSpacing: Math.round(8 * page.uiScale)

                        Repeater {
                            model: [
                                {
                                    title: qsTr("Graphics Card (GPU)"),
                                    value: page.nvidiaDetector
                                           ? (page.nvidiaDetector.gpuFound ? page.nvidiaDetector.gpuName : page.safeText(page.nvidiaDetector.displayAdapterName))
                                           : qsTr("Unavailable")
                                },
                                {
                                    title: qsTr("Processor (CPU)"),
                                    value: page.safeText(page.systemInfo ? page.systemInfo.cpuModel : "")
                                },
                                {
                                    title: qsTr("Motherboard"),
                                    value: page.safeText(page.systemInfo ? page.systemInfo.motherboardModel : "")
                                },
                                {
                                    title: qsTr("UEFI / BIOS"),
                                    value: page.safeText(page.systemInfo ? page.systemInfo.biosVersion : "")
                                },
                                {
                                    title: qsTr("System Memory (RAM)"),
                                    value: (page.ramMonitor && page.ramMonitor.totalMiB > 0)
                                           ? ((page.ramMonitor.totalMiB / 1024.0).toFixed(1) + " GB (" + page.ramMonitor.totalMiB + " MiB)")
                                           : qsTr("Unavailable")
                                },
                                {
                                    title: qsTr("Video Memory (VRAM)"),
                                    value: (page.gpuMonitor && page.gpuMonitor.memoryTotalMiB > 0)
                                           ? ((page.gpuMonitor.memoryTotalMiB / 1024.0).toFixed(1) + " GB (" + page.gpuMonitor.memoryTotalMiB + " MiB)")
                                           : qsTr("Unavailable")
                                },
                                {
                                    title: qsTr("PCIe Link Interface"),
                                    value: (page.gpuMonitor && page.gpuMonitor.pcieLinkStatus.length > 0)
                                           ? page.gpuMonitor.pcieLinkStatus
                                           : qsTr("PCIe Auto")
                                },
                                {
                                    title: qsTr("Device & Power"),
                                    value: page.deviceAndPowerSummary()
                                }
                            ]

                            delegate: Rectangle {
                                required property var modelData
                                Layout.fillWidth: true
                                implicitHeight: Math.round(64 * page.uiScale)
                                radius: 10
                                color: page.bgColor
                                border.width: 1
                                border.color: page.borderColor

                                Column {
                                    anchors.fill: parent
                                    anchors.margins: Math.round(8 * page.uiScale)
                                    spacing: Math.round(3 * page.uiScale)

                                    Label {
                                        width: parent.width
                                        text: modelData.title
                                        color: page.softTextColor
                                        font.pixelSize: Math.round(11 * page.uiScale)
                                        font.weight: Font.DemiBold
                                        elide: Text.ElideRight
                                    }

                                    Label {
                                        width: parent.width
                                        text: modelData.value
                                        color: page.textColor
                                        font.pixelSize: Math.round(13 * page.uiScale)
                                        font.weight: Font.DemiBold
                                        elide: Text.ElideRight
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // Section 2: Operating System & Software Stack
            Rectangle {
                Layout.fillWidth: true
                radius: 14
                color: page.cardColor
                border.width: 1
                border.color: page.borderColor
                implicitHeight: osSectionLayout.implicitHeight + Math.round(24 * page.uiScale)

                ColumnLayout {
                    id: osSectionLayout
                    anchors.fill: parent
                    anchors.margins: Math.round(14 * page.uiScale)
                    spacing: Math.round(12 * page.uiScale)

                    Label {
                        text: qsTr("Operating System & Software Stack")
                        color: page.textColor
                        font.pixelSize: Math.round(16 * page.uiScale)
                        font.weight: Font.DemiBold
                    }

                    GridLayout {
                        Layout.fillWidth: true
                        columns: width > 920 ? 3 : (width > 560 ? 2 : 1)
                        columnSpacing: Math.round(8 * page.uiScale)
                        rowSpacing: Math.round(8 * page.uiScale)

                        Repeater {
                            model: [
                                {
                                    title: qsTr("Operating System"),
                                    value: page.safeText(page.systemInfo ? page.systemInfo.osName : "")
                                },
                                {
                                    title: qsTr("Desktop Environment"),
                                    value: page.safeText(page.systemInfo ? page.systemInfo.desktopEnvironment : "")
                                },
                                {
                                    title: qsTr("Linux Kernel"),
                                    value: page.safeText(page.systemInfo ? page.systemInfo.kernelVersion : "")
                                },
                                {
                                    title: qsTr("Display Server / Session"),
                                    value: page.nvidiaDetector && page.nvidiaDetector.sessionType.length > 0
                                           ? (page.nvidiaDetector.sessionType.charAt(0).toUpperCase() + page.nvidiaDetector.sessionType.slice(1))
                                           : qsTr("Wayland")
                                },
                                {
                                    title: qsTr("NVIDIA Driver"),
                                    value: page.nvidiaDriverSummary()
                                },
                                {
                                    title: qsTr("Graphics & Compute APIs"),
                                    value: page.safeText(page.systemInfo ? page.systemInfo.graphicsApiSummary : "")
                                },
                                {
                                    title: qsTr("Platform & Security"),
                                    value: page.platformSecuritySummary()
                                }
                            ]

                            delegate: Rectangle {
                                required property var modelData
                                Layout.fillWidth: true
                                implicitHeight: Math.round(64 * page.uiScale)
                                radius: 10
                                color: page.bgColor
                                border.width: 1
                                border.color: page.borderColor

                                Column {
                                    anchors.fill: parent
                                    anchors.margins: Math.round(8 * page.uiScale)
                                    spacing: Math.round(3 * page.uiScale)

                                    Label {
                                        width: parent.width
                                        text: modelData.title
                                        color: page.softTextColor
                                        font.pixelSize: Math.round(11 * page.uiScale)
                                        font.weight: Font.DemiBold
                                        elide: Text.ElideRight
                                    }

                                    Label {
                                        width: parent.width
                                        text: modelData.value
                                        color: page.textColor
                                        font.pixelSize: Math.round(13 * page.uiScale)
                                        font.weight: Font.DemiBold
                                        elide: Text.ElideRight
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // Section 3: Diagnostic Actions & Firmware Control
            Rectangle {
                Layout.fillWidth: true
                radius: 14
                color: page.cardColor
                border.width: 1
                border.color: page.borderColor
                implicitHeight: actionsSectionLayout.implicitHeight + Math.round(24 * page.uiScale)

                ColumnLayout {
                    id: actionsSectionLayout
                    anchors.fill: parent
                    anchors.margins: Math.round(14 * page.uiScale)
                    spacing: Math.round(12 * page.uiScale)

                    Label {
                        text: qsTr("Diagnostics & System Controls")
                        color: page.textColor
                        font.pixelSize: Math.round(16 * page.uiScale)
                        font.weight: Font.DemiBold
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Math.round(10 * page.uiScale)

                        Button {
                            id: copyReportBtn
                            text: page.reportCopied ? qsTr("Report Copied to Clipboard!") : qsTr("Copy Diagnostic Report")
                            implicitHeight: Math.round(36 * page.uiScale)

                            background: Rectangle {
                                radius: 8
                                color: page.reportCopied
                                       ? page.successColor
                                       : (copyReportBtn.hovered ? (page.darkMode ? "#3B3156" : "#E2E8F0") : page.bgColor)
                                border.width: 1
                                border.color: page.reportCopied ? page.successColor : page.borderColor
                            }

                            contentItem: Text {
                                text: copyReportBtn.text
                                color: page.reportCopied ? "#FFFFFF" : page.textColor
                                font.pixelSize: Math.round(12 * page.uiScale)
                                font.weight: Font.DemiBold
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }

                            onClicked: page.copyDiagnosticReport()
                        }

                        Button {
                            id: rebootFirmwareBtn
                            text: qsTr("Reboot to UEFI / BIOS Firmware")
                            implicitHeight: Math.round(36 * page.uiScale)

                            background: Rectangle {
                                radius: 8
                                color: rebootFirmwareBtn.hovered ? (page.darkMode ? "#3B3156" : "#E2E8F0") : page.bgColor
                                border.width: 1
                                border.color: rebootFirmwareBtn.hovered ? page.warningColor : page.borderColor
                            }

                            contentItem: Text {
                                text: rebootFirmwareBtn.text
                                color: rebootFirmwareBtn.hovered ? page.warningColor : page.textColor
                                font.pixelSize: Math.round(12 * page.uiScale)
                                font.weight: Font.DemiBold
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }

                            onClicked: rebootConfirmDialog.open()
                        }

                        Item {
                            Layout.fillWidth: true
                        }
                    }
                }
            }
        }
    }

    Dialog {
        id: rebootConfirmDialog
        title: qsTr("Reboot to UEFI / BIOS Firmware")
        modal: true
        anchors.centerIn: parent
        width: Math.min(page.width * 0.85, 420)
        standardButtons: Dialog.Ok | Dialog.Cancel

        background: Rectangle {
            radius: 12
            color: page.cardColor
            border.width: 1
            border.color: page.borderColor
        }

        contentItem: ColumnLayout {
            spacing: 12

            Label {
                text: qsTr("Your system will restart immediately and boot directly into the UEFI / BIOS firmware setup utility.")
                color: page.textColor
                font.pixelSize: Math.round(13 * page.uiScale)
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }

            Label {
                text: qsTr("Make sure any unsaved work in other applications is saved.")
                color: page.warningColor
                font.pixelSize: Math.round(12 * page.uiScale)
                font.weight: Font.DemiBold
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }
        }

        onAccepted: {
            if (page.systemInfo)
                page.systemInfo.requestRebootToFirmware();
        }
    }

    Component.onCompleted: {
        if (page.systemInfo)
            page.systemInfo.refresh();
    }
}
