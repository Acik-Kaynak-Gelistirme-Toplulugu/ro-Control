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
    property string generatedReport: ""

    readonly property color bgColor: theme && theme.card ? theme.card : (page.darkMode ? "#29233B" : "#FFFFFF")
    readonly property color cardColor: theme && theme.cardStrong ? theme.cardStrong : (page.darkMode ? "#342D4A" : "#F1F5F9")
    readonly property color borderColor: theme && theme.border ? theme.border : (page.darkMode ? "#4D436B" : "#CBD5E1")
    readonly property color textColor: theme && theme.text ? theme.text : (page.darkMode ? "#F8FAFC" : "#0F172A")
    readonly property color softTextColor: theme && theme.textSoft ? theme.textSoft : (page.darkMode ? "#94A3B8" : "#64748B")
    readonly property color accentColor: theme && theme.accentA ? theme.accentA : (page.darkMode ? "#818CF8" : "#4F46E5")
    readonly property color infoBg: theme && theme.infoBg ? theme.infoBg : (page.darkMode ? "#1E2548" : "#EFF6FF")
    readonly property color successColor: theme && theme.success ? theme.success : (page.darkMode ? "#4ADE80" : "#059669")
    readonly property color warningColor: theme && theme.warning ? theme.warning : (page.darkMode ? "#FBBF24" : "#D97706")

    function deviceAndPowerSummary() {
        const dev = page.systemInfo && page.systemInfo.deviceType ? page.systemInfo.deviceType : "";
        const pwr = page.systemInfo && page.systemInfo.powerSource ? page.systemInfo.powerSource : "";
        return dev.length > 0 && pwr.length > 0 ? (dev + " • " + pwr) : (dev || pwr);
    }

    function nvidiaDriverSummary() {
        const ver = page.nvidiaDetector && page.nvidiaDetector.driverVersion ? page.nvidiaDetector.driverVersion : "";
        if (ver.length === 0)
            return "";
        const src = page.nvidiaDetector ? page.nvidiaDetector.installedDriverSourceLabel : "";
        return (src.length > 0 && src !== "None") ? (ver + " (" + src + ")") : ver;
    }

    function systemHealthSummary() {
        const items = [];
        if (page.nvidiaDetector && page.nvidiaDetector.driverVersion)
            items.push(qsTr("Driver: %1").arg(page.nvidiaDetector.driverVersion));
        if (page.gpuMonitor && page.gpuMonitor.available)
            items.push(qsTr("GPU telemetry: Available"));
        if (page.nvidiaDetector && page.nvidiaDetector.secureBootKnown)
            items.push(page.nvidiaDetector.secureBootEnabled ? qsTr("Secure Boot: On") : qsTr("Secure Boot: Off"));
        return items.length > 0 ? items.join(" • ") : qsTr("Live system information");
    }

    function platformSecuritySummary() {
        const virt = (page.systemInfo && page.systemInfo.virtualMachine) ? page.systemInfo.virtualizationType : qsTr("Bare Metal");
        const sb = (page.nvidiaDetector && page.nvidiaDetector.secureBootKnown)
                 ? (page.nvidiaDetector.secureBootEnabled ? qsTr("Secure Boot: On") : qsTr("Secure Boot: Off"))
                 : "";
        return sb.length > 0 ? (virt + " • " + sb) : virt;
    }

    function diagnosticGpuName() {
        if (!page.nvidiaDetector)
            return "";
        return page.nvidiaDetector.gpuFound ? page.nvidiaDetector.gpuName : page.nvidiaDetector.displayAdapterName;
    }

    function hardwareCards() {
        const cards = [];
        function add(title, value) {
            if (value && value.toString().trim().length > 0)
                cards.push({ title: title, value: value });
        }
        add(qsTr("Graphics Card (GPU)"), page.diagnosticGpuName());
        add(qsTr("Processor (CPU)"), page.systemInfo ? page.systemInfo.cpuModel : "");
        add(qsTr("Motherboard"), page.systemInfo ? page.systemInfo.motherboardModel : "");
        add(qsTr("UEFI / BIOS"), page.systemInfo ? page.systemInfo.biosVersion : "");
        if (page.ramMonitor && page.ramMonitor.totalMiB > 0)
            add(qsTr("System Memory (RAM)"), (page.ramMonitor.totalMiB / 1024.0).toFixed(1) + " GB (" + page.ramMonitor.totalMiB + " MiB)");
        if (page.gpuMonitor && page.gpuMonitor.memoryTotalMiB > 0)
            add(qsTr("Video Memory (VRAM)"), (page.gpuMonitor.memoryTotalMiB / 1024.0).toFixed(1) + " GB (" + page.gpuMonitor.memoryTotalMiB + " MiB)");
        if (page.systemInfo && page.systemInfo.integratedGpuName && page.systemInfo.integratedGpuMemory)
            add(qsTr("Integrated Graphics Memory"), page.systemInfo.integratedGpuName + " • " + page.systemInfo.integratedGpuMemory);
        add(qsTr("PCIe Link Interface"), page.gpuMonitor ? page.gpuMonitor.pcieLinkStatus : "");
        add(qsTr("Device & Power"), page.deviceAndPowerSummary());
        return cards;
    }

    function softwareCards() {
        const cards = [];
        function add(title, value) {
            if (value && value.toString().trim().length > 0)
                cards.push({ title: title, value: value });
        }
        add(qsTr("Operating System"), page.systemInfo ? page.systemInfo.osName : "");
        add(qsTr("Desktop Environment"), page.systemInfo ? page.systemInfo.desktopEnvironment : "");
        add(qsTr("Linux Kernel"), page.systemInfo ? page.systemInfo.kernelVersion : "");
        if (page.nvidiaDetector && page.nvidiaDetector.sessionType)
            add(qsTr("Display Server / Session"), page.nvidiaDetector.sessionType.charAt(0).toUpperCase() + page.nvidiaDetector.sessionType.slice(1));
        if (page.nvidiaDetector && page.nvidiaDetector.gpuFound && page.nvidiaDetector.driverVersion)
            add(qsTr("NVIDIA Driver"), page.nvidiaDriverSummary());
        add(qsTr("Graphics & Compute APIs"), page.systemInfo ? page.systemInfo.graphicsApiSummary : "");
        add(qsTr("Platform & Security"), page.platformSecuritySummary());
        return cards;
    }

    function openDiagnosticReport() {
        if (!page.systemInfo)
            return;

        const gpu = page.diagnosticGpuName();
        const drv = page.nvidiaDriverSummary();
        const vram = (page.gpuMonitor && page.gpuMonitor.memoryTotalMiB > 0)
                   ? ((page.gpuMonitor.memoryTotalMiB / 1024.0).toFixed(1) + " GB (" + page.gpuMonitor.memoryTotalMiB + " MiB)")
                   : "";
        const ram = (page.ramMonitor && page.ramMonitor.totalMiB > 0)
                  ? ((page.ramMonitor.totalMiB / 1024.0).toFixed(1) + " GB (" + page.ramMonitor.totalMiB + " MiB)")
                  : "";
        const pcie = page.gpuMonitor ? page.gpuMonitor.pcieLinkStatus : "";
        const sec = page.platformSecuritySummary();

        page.generatedReport = page.systemInfo.generateSystemReport(gpu, drv, vram, ram, pcie, sec, page.systemInfo.diagnosticReportFormat);
        if (page.systemInfo.diagnosticReportDestination === "clipboard") {
            page.reportCopied = page.systemInfo.copyToClipboard(page.generatedReport);
            if (page.reportCopied)
                copiedFeedbackTimer.restart();
        }
        diagnosticReportDialog.open();
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

            Rectangle { Layout.fillWidth: true; implicitHeight: 52; radius: 12; color: page.cardColor; border.width: 1; border.color: page.borderColor
                RowLayout { anchors.fill: parent; anchors.margins: 12; spacing: 18
                    Label { text: qsTr("System health"); color: page.textColor; font.weight: Font.DemiBold }
                    Label { Layout.fillWidth: true; text: page.systemHealthSummary(); color: page.softTextColor; elide: Text.ElideRight }
                }
            }

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
                            model: page.hardwareCards()

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
                            model: page.softwareCards()

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
                            text: qsTr("Open Diagnostic Report")
                            implicitHeight: Math.round(36 * page.uiScale)

                            background: Rectangle {
                                radius: 8
                                color: copyReportBtn.hovered ? (page.darkMode ? "#3B3156" : "#E2E8F0") : page.bgColor
                                border.width: 1
                                border.color: copyReportBtn.hovered ? page.accentColor : page.borderColor
                            }

                            contentItem: Text {
                                text: copyReportBtn.text
                                color: page.textColor
                                font.pixelSize: Math.round(12 * page.uiScale)
                                font.weight: Font.DemiBold
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }

                            onClicked: page.openDiagnosticReport()
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
        id: diagnosticReportDialog
        title: qsTr("Diagnostic Report")
        modal: true
        anchors.centerIn: parent
        width: Math.min(page.width * 0.9, Math.round(760 * page.uiScale))
        height: Math.min(page.height * 0.85, Math.round(620 * page.uiScale))
        standardButtons: Dialog.Close

        background: Rectangle {
            radius: 12
            color: page.cardColor
            border.width: 1
            border.color: page.borderColor
        }

        contentItem: ColumnLayout {
            spacing: 10

            Label {
                Layout.fillWidth: true
                text: qsTr("Choose how the report is generated. These preferences are saved for future reports.")
                color: page.softTextColor
                wrapMode: Text.WordWrap
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Label { text: qsTr("Format"); color: page.textColor; font.weight: Font.DemiBold }
                ComboBox {
                    id: reportFormatCombo
                    model: ["markdown", "plain", "json"]
                    currentIndex: Math.max(0, model.indexOf(page.systemInfo ? page.systemInfo.diagnosticReportFormat : "markdown"))
                    textRole: ""
                    onActivated: function(index) {
                        if (page.systemInfo) {
                            page.systemInfo.setDiagnosticReportFormat(model[index]);
                            page.openDiagnosticReport();
                        }
                    }
                }

                Item { Layout.fillWidth: true }
                Label { text: qsTr("Default action"); color: page.textColor; font.weight: Font.DemiBold }
                ComboBox {
                    model: ["preview", "clipboard"]
                    currentIndex: Math.max(0, model.indexOf(page.systemInfo ? page.systemInfo.diagnosticReportDestination : "preview"))
                    onActivated: function(index) {
                        if (page.systemInfo)
                            page.systemInfo.setDiagnosticReportDestination(model[index]);
                    }
                }
            }

            TextArea {
                id: diagnosticReportText
                Layout.fillWidth: true
                Layout.fillHeight: true
                text: page.generatedReport
                readOnly: true
                selectByMouse: true
                wrapMode: TextEdit.WrapAnywhere
                color: page.textColor
                font.family: "monospace"
                font.pixelSize: Math.round(12 * page.uiScale)
                background: Rectangle {
                    color: page.bgColor
                    radius: 8
                    border.width: 1
                    border.color: page.borderColor
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Item { Layout.fillWidth: true }
                Label {
                    visible: page.reportCopied
                    text: qsTr("Copied to clipboard")
                    color: page.successColor
                    font.weight: Font.DemiBold
                }
                Button {
                    text: qsTr("Copy to Clipboard")
                    onClicked: {
                        page.reportCopied = page.systemInfo && page.systemInfo.copyToClipboard(page.generatedReport);
                        if (page.reportCopied)
                            copiedFeedbackTimer.restart();
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
