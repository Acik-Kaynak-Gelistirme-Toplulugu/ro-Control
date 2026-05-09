import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: page
    required property var nvidiaDetector
    required property var nvidiaInstaller
    required property var nvidiaUpdater

    property var theme: ({})
    property bool darkMode: false
    property bool showAdvancedInfo: true
    property real uiScale: 1.0

    property string bannerText: qsTr("Ready")
    property string bannerTone: "info"
    property string operationSource: ""
    property string operationPhase: ""
    property string operationDetail: ""
    property bool operationActive: false
    property bool suppressPassiveStatus: true
    readonly property bool backendBusy: page.nvidiaInstaller.busy || page.nvidiaUpdater.busy
    readonly property bool operationRunning: page.operationActive || page.backendBusy
    readonly property bool remoteDriverCatalogAvailable: page.nvidiaUpdater.latestVersion.length > 0 || page.nvidiaUpdater.availableVersions.length > 0
    readonly property bool canInstallLatestRemoteDriver: page.nvidiaDetector.gpuFound && remoteDriverCatalogAvailable
    readonly property bool driverInstalledLocally: page.nvidiaDetector.driverVersion.length > 0 || page.nvidiaUpdater.currentVersion.length > 0
    readonly property string installedVersionLabel: page.nvidiaDetector.driverVersion.length > 0 ? page.nvidiaDetector.driverVersion : page.nvidiaUpdater.currentVersion
    readonly property bool catalogAvailable: page.nvidiaUpdater.latestVersion.length > 0 || page.nvidiaUpdater.availableVersions.length > 0
    readonly property color bgColor: theme && theme.card ? theme.card : "#ffffff"
    readonly property color cardColor: theme && theme.cardStrong ? theme.cardStrong : "#f5f8ff"
    readonly property color borderColor: theme && theme.border ? theme.border : "#d9e1f0"
    readonly property color textColor: theme && theme.text ? theme.text : "#12213a"
    readonly property color softTextColor: theme && theme.textSoft ? theme.textSoft : "#6f829e"
    readonly property color infoBg: theme && theme.infoBg ? theme.infoBg : "#e9f2ff"
    readonly property color successBg: theme && theme.successBg ? theme.successBg : "#e6f7ee"
    readonly property color warningBg: theme && theme.warningBg ? theme.warningBg : "#fff4de"
    readonly property color dangerBg: theme && theme.dangerBg ? theme.dangerBg : "#fdecef"

    function classifyOperationPhase(message) {
        const lowered = (message || "").toLowerCase();
        if (lowered.indexOf("update") >= 0 || lowered.indexOf("version") >= 0)
            return qsTr("Update");
        if (lowered.indexOf("install") >= 0 || lowered.indexOf("remove") >= 0)
            return qsTr("Package");
        if (lowered.indexOf("kernel") >= 0 || lowered.indexOf("akmods") >= 0)
            return qsTr("Kernel");
        return qsTr("General");
    }

    function setOperationState(source, message, tone, running) {
        operationSource = source || "";
        operationDetail = message || "";
        operationPhase = classifyOperationPhase(operationDetail);
        bannerText = operationDetail.length > 0 ? operationDetail : qsTr("Ready");
        bannerTone = tone || "info";
        operationActive = !!running;
    }

    function finishOperation(source, success, message) {
        setOperationState(source, message, success ? "success" : "error", false);
    }

    function latestActionLabel() {
        return page.driverInstalledLocally ? qsTr("Apply Latest Open Source") : qsTr("Install Open Source");
    }

    function driverVersionMainLabel() {
        if (page.installedVersionLabel.length > 0)
            return page.installedVersionLabel;
        if (page.nvidiaUpdater.latestVersion.length > 0)
            return qsTr("Latest available: %1").arg(page.nvidiaUpdater.latestVersion);
        if (page.catalogAvailable)
            return qsTr("Driver catalog loaded");
        return qsTr("Driver scan pending");
    }

    function closedLicenseText() {
        const agreement = page.nvidiaInstaller.proprietaryAgreementText || "";
        if (agreement.length > 0)
            return agreement;
        return qsTr("Closed-source NVIDIA driver installation requires reviewing and accepting the NVIDIA license terms before ro-Control can start the closed-source install workflow.");
    }

    function appendLog(source, message) {
        const prefix = source && source.length > 0 ? source : qsTr("System");
        const nextLine = "[" + Qt.formatTime(new Date(), "HH:mm:ss") + "] " + prefix + ": " + message;
        activityLog.text = activityLog.text.length > 0 ? activityLog.text + "\n" + nextLine : nextLine;
        if (activityLog.cursorPosition >= activityLog.length - nextLine.length - 1)
            activityLog.cursorPosition = activityLog.length;
    }

    function refreshDriverState(showProgress) {
        if (showProgress !== false)
            page.setOperationState(qsTr("Updater"), qsTr("Checking official NVIDIA driver sources..."), "info", true);
        page.nvidiaDetector.refresh();
        page.nvidiaInstaller.refreshProprietaryAgreement();
        page.suppressPassiveStatus = true;
        page.nvidiaUpdater.checkForUpdate();
    }

    ScrollView {
        id: pageScroll
        anchors.fill: parent
        clip: true
        contentWidth: availableWidth

        ColumnLayout {
            width: pageScroll.availableWidth
            spacing: 10

            GridLayout {
                Layout.fillWidth: true
                columns: width > 900 ? 3 : 1
                columnSpacing: 10
                rowSpacing: 10

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 118
                    radius: 14
                    color: page.cardColor
                    border.width: 1
                    border.color: page.borderColor

                    Column {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 6

                        Label { text: qsTr("GPU"); color: page.softTextColor; font.weight: Font.DemiBold; font.pixelSize: Math.round(12 * page.uiScale) }
                        Label { text: page.nvidiaDetector.gpuFound ? page.nvidiaDetector.gpuName : qsTr("No NVIDIA GPU"); color: page.textColor; font.pixelSize: Math.round(18 * page.uiScale); font.weight: Font.DemiBold; elide: Text.ElideRight; width: parent.width }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 118
                    radius: 14
                    color: page.cardColor
                    border.width: 1
                    border.color: page.borderColor

                    Column {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 6

                        Label { text: qsTr("Driver Version"); color: page.softTextColor; font.weight: Font.DemiBold; font.pixelSize: Math.round(12 * page.uiScale) }
                        Label {
                            text: page.driverVersionMainLabel()
                            color: page.textColor
                            font.pixelSize: Math.round(18 * page.uiScale)
                            font.weight: Font.DemiBold
                            elide: Text.ElideRight
                            width: parent.width
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 118
                    radius: 14
                    color: page.cardColor
                    border.width: 1
                    border.color: page.borderColor

                    Column {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 6

                        Label { text: qsTr("Secure Boot"); color: page.softTextColor; font.weight: Font.DemiBold; font.pixelSize: Math.round(12 * page.uiScale) }
                        Label {
                            text: page.nvidiaDetector.secureBootKnown
                                  ? (page.nvidiaDetector.secureBootEnabled ? qsTr("Enabled")
                                                                           : qsTr("Disabled"))
                                  : qsTr("Unknown")
                            color: page.textColor
                            font.weight: Font.DemiBold
                            font.pixelSize: Math.round(22 * page.uiScale)
                        }
                        Label {
                            width: parent.width
                            text: page.nvidiaDetector.secureBootKnown
                                  ? (page.nvidiaDetector.secureBootEnabled
                                     ? qsTr("Kernel module signing may be required.")
                                     : qsTr("No Secure Boot signing requirement detected."))
                                  : qsTr("Secure Boot state could not be verified.")
                            color: page.softTextColor
                            wrapMode: Text.Wrap
                            maximumLineCount: 2
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                radius: 14
                color: page.cardColor
                border.width: 1
                border.color: page.borderColor
                implicitHeight: actionLayout.implicitHeight + 24

                ColumnLayout {
                    id: actionLayout
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 10

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Label {
                            Layout.fillWidth: true
                            text: qsTr("Driver Actions")
                            color: page.textColor
                            font.pixelSize: Math.round(18 * page.uiScale)
                            font.weight: Font.DemiBold
                        }

                        ToolButton {
                            id: refreshButton
                            implicitWidth: Math.round(38 * page.uiScale)
                            implicitHeight: Math.round(38 * page.uiScale)
                            enabled: !page.nvidiaUpdater.busy && !page.nvidiaInstaller.busy
                            icon.name: "view-refresh"
                            icon.width: Math.round(18 * page.uiScale)
                            icon.height: Math.round(18 * page.uiScale)
                            icon.color: page.textColor
                            display: AbstractButton.IconOnly
                            ToolTip.visible: hovered
                            ToolTip.text: qsTr("Rescan and check updates")
                            onClicked: page.refreshDriverState(true)

                            background: Rectangle {
                                radius: width / 2
                                color: refreshButton.down ? page.infoBg : page.bgColor
                                border.width: 1
                                border.color: page.borderColor
                            }
                        }
                    }

                    Label {
                        Layout.fillWidth: true
                        text: qsTr("Install, update, deep-clean, or rescan the NVIDIA driver stack. The refresh button also checks available driver updates.")
                        color: page.softTextColor
                        wrapMode: Text.Wrap
                    }

                    GridLayout {
                        Layout.fillWidth: true
                        columns: width > 920 ? 3 : 1
                        columnSpacing: 8
                        rowSpacing: 8

                        Button {
                            Layout.fillWidth: true
                            text: qsTr("Install Closed Source")
                            enabled: !page.nvidiaInstaller.busy
                            onClicked: {
                                if (page.nvidiaInstaller.proprietaryAgreementRequired) {
                                    licensePopup.open();
                                } else {
                                    page.setOperationState(qsTr("Installer"), qsTr("Installing closed-source NVIDIA driver..."), "info", true);
                                    page.nvidiaInstaller.installProprietary(false);
                                }
                            }
                        }

                        Button {
                            Layout.fillWidth: true
                            text: page.latestActionLabel()
                            enabled: !page.nvidiaUpdater.busy && !page.nvidiaInstaller.busy && (page.nvidiaUpdater.updateAvailable || page.catalogAvailable)
                            onClicked: {
                                page.setOperationState(qsTr("Updater"), qsTr("Applying latest available driver..."), "info", true);
                                page.suppressPassiveStatus = false;
                                page.nvidiaUpdater.applyUpdate();
                            }
                        }

                        Button {
                            Layout.fillWidth: true
                            text: qsTr("Deep Clean")
                            enabled: page.driverInstalledLocally && !page.nvidiaInstaller.busy && !page.nvidiaUpdater.busy
                            onClicked: {
                                page.setOperationState(qsTr("Installer"), qsTr("Cleaning NVIDIA artifacts..."), "info", true);
                                page.nvidiaInstaller.deepClean();
                            }
                        }

                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                visible: page.showAdvancedInfo
                radius: 14
                color: page.cardColor
                border.width: 1
                border.color: page.borderColor
                implicitHeight: maintenanceLayout.implicitHeight + 24

                ColumnLayout {
                    id: maintenanceLayout
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 10

                    Label {
                        text: qsTr("Maintenance")
                        color: page.textColor
                        font.pixelSize: Math.round(18 * page.uiScale)
                        font.weight: Font.DemiBold
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Button {
                            text: qsTr("Install Open Modules")
                            enabled: !page.nvidiaInstaller.busy
                            onClicked: {
                                page.setOperationState(qsTr("Installer"), qsTr("Installing open NVIDIA kernel modules..."), "info", true);
                                page.nvidiaInstaller.installOpenSource();
                            }
                        }

                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                radius: 14
                color: page.cardColor
                border.width: 1
                border.color: page.borderColor
                implicitHeight: 240

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 8

                    Label {
                        text: qsTr("Activity")
                        color: page.textColor
                        font.pixelSize: Math.round(18 * page.uiScale)
                            font.weight: Font.DemiBold
                    }

                    TextArea {
                        id: activityLog
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        readOnly: true
                        wrapMode: Text.Wrap
                        color: page.textColor
                        font.family: "Noto Sans Mono"
                        background: Rectangle {
                            radius: 10
                            color: page.bgColor
                            border.width: 1
                            border.color: page.borderColor
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Item { Layout.fillWidth: true }

                        Button {
                            text: qsTr("Clear")
                            onClicked: activityLog.text = ""
                        }
                    }
                }
            }
        }
    }

    Connections {
        target: page.nvidiaInstaller

        function onProgressMessage(message) {
            page.setOperationState(qsTr("Installer"), message, "info", true);
            page.appendLog(qsTr("Installer"), message);
        }

        function onInstallFinished(success, message) {
            page.finishOperation(qsTr("Installer"), success, message);
            page.appendLog(qsTr("Installer"), message);
            page.nvidiaDetector.refresh();
            page.nvidiaUpdater.checkForUpdate();
            page.nvidiaInstaller.refreshProprietaryAgreement();
        }

        function onRemoveFinished(success, message) {
            page.finishOperation(qsTr("Installer"), success, message);
            page.appendLog(qsTr("Installer"), message);
            page.nvidiaDetector.refresh();
            page.nvidiaUpdater.checkForUpdate();
            page.nvidiaInstaller.refreshProprietaryAgreement();
        }
    }

    Connections {
        target: page.nvidiaUpdater

        function onProgressMessage(message) {
            page.setOperationState(qsTr("Updater"), message, "info", true);
            page.appendLog(qsTr("Updater"), message);
        }

        function onCheckFinished(success, message) {
            if (success && page.suppressPassiveStatus && !page.nvidiaUpdater.updateAvailable)
                page.setOperationState(qsTr("Updater"), qsTr("Ready"), "info", false);
            else
                page.finishOperation(qsTr("Updater"), success, message);
            page.appendLog(qsTr("Updater"), message);
            page.suppressPassiveStatus = false;
        }

        function onUpdateFinished(success, message) {
            page.finishOperation(qsTr("Updater"), success, message);
            page.appendLog(qsTr("Updater"), message);
            page.nvidiaDetector.refresh();
            page.nvidiaUpdater.checkForUpdate();
        }
    }

    Component.onCompleted: {
        page.refreshDriverState(false);
    }

    Popup {
        id: licensePopup
        modal: true
        focus: true
        width: Math.min(page.width - 40, Math.round(640 * page.uiScale))
        height: Math.min(page.height - 80, Math.round(500 * page.uiScale))
        x: Math.round((page.width - width) / 2)
        y: Math.round((page.height - height) / 2)
        padding: 14
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

        background: Rectangle {
            radius: 12
            color: page.bgColor
            border.width: 1
            border.color: page.borderColor
        }

        contentItem: ColumnLayout {
            spacing: 10

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Label {
                    Layout.fillWidth: true
                    text: qsTr("NVIDIA License Review")
                    color: page.textColor
                    font.pixelSize: Math.round(18 * page.uiScale)
                    font.weight: Font.DemiBold
                }

                ToolButton {
                    id: closeLicenseButton
                    implicitWidth: Math.round(34 * page.uiScale)
                    implicitHeight: Math.round(34 * page.uiScale)
                    icon.name: "window-close"
                    icon.width: Math.round(16 * page.uiScale)
                    icon.height: Math.round(16 * page.uiScale)
                    icon.color: page.textColor
                    display: AbstractButton.IconOnly
                    ToolTip.visible: hovered
                    ToolTip.text: qsTr("Close")
                    onClicked: licensePopup.close()

                    background: Rectangle {
                        radius: width / 2
                        color: closeLicenseButton.down ? page.infoBg : page.bgColor
                        border.width: 1
                        border.color: page.borderColor
                    }
                }
            }

            TextArea {
                Layout.fillWidth: true
                Layout.fillHeight: true
                readOnly: true
                wrapMode: Text.Wrap
                text: page.closedLicenseText()
                color: page.textColor
                background: Rectangle {
                    radius: 8
                    color: page.cardColor
                    border.width: 1
                    border.color: page.borderColor
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Button {
                    Layout.fillWidth: true
                    text: qsTr("Reject")
                    onClicked: {
                        licensePopup.close();
                    }
                }

                Button {
                    Layout.fillWidth: true
                    text: qsTr("Accept")
                    onClicked: {
                        licensePopup.close();
                        page.setOperationState(qsTr("Installer"), qsTr("Installing closed-source NVIDIA driver..."), "info", true);
                        page.nvidiaInstaller.installProprietary(true);
                    }
                }
            }
        }
    }
}
