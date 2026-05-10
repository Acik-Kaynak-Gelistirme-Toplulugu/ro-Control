import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../components" as Components

Item {
    id: page
    required property var nvidiaDetector
    required property var nvidiaInstaller
    required property var nvidiaUpdater
    property var systemInfo: null

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
    property bool activityFollowTail: true
    property string lastOperationText: ""
    property string lastOperationTone: "info"
    property string requestedDriverAction: ""
    property string pendingDriverStateText: ""
    property string pendingDriverStateTone: "info"
    property bool postOperationRefreshPending: false
    readonly property bool backendBusy: page.nvidiaInstaller.busy || page.nvidiaUpdater.busy
    readonly property bool operationRunning: page.operationActive || page.backendBusy
    readonly property bool remoteDriverCatalogAvailable: page.nvidiaUpdater.latestVersion.length > 0 || page.nvidiaUpdater.availableVersions.length > 0
    readonly property bool canInstallLatestRemoteDriver: page.nvidiaDetector.gpuFound && remoteDriverCatalogAvailable
    readonly property bool confirmedDriverInstalledLocally: page.nvidiaDetector.driverVersion.length > 0 || page.nvidiaDetector.driverPackageInstalled || page.nvidiaUpdater.currentVersion.length > 0
    readonly property bool driverInstalledLocally: page.confirmedDriverInstalledLocally || page.pendingDriverStateText.length > 0
    readonly property bool virtualMachine: page.systemInfo && page.systemInfo.virtualMachine
    readonly property string virtualizationType: page.virtualMachine ? page.systemInfo.virtualizationType : ""
    readonly property bool canManageDriverStack: page.nvidiaDetector.gpuFound || page.driverInstalledLocally
    readonly property string installedVersionLabel: page.nvidiaDetector.driverVersion.length > 0 ? page.nvidiaDetector.driverVersion : page.nvidiaUpdater.currentVersion
    readonly property bool catalogAvailable: page.nvidiaUpdater.latestVersion.length > 0 || page.nvidiaUpdater.availableVersions.length > 0
    readonly property color driverVersionStatusColor: page.pendingDriverStateText.length > 0
                                                      ? (page.pendingDriverStateTone === "warning"
                                                         ? (theme && theme.warning ? theme.warning : page.softTextColor)
                                                         : (theme && theme.success ? theme.success : page.softTextColor))
                                                      : page.nvidiaUpdater.updateAvailable
                                                      ? (theme && theme.warning ? theme.warning : page.softTextColor)
                                                      : page.softTextColor
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

    function recordOperationResult(source, success, message) {
        const lowered = (message || "").toLowerCase();
        const canceled = lowered.indexOf("cancel") >= 0 || lowered.indexOf("iptal") >= 0 || lowered.indexOf("abgebrochen") >= 0 || lowered.indexOf("cancelad") >= 0;
        lastOperationTone = success ? "success" : (canceled ? "warning" : "error");
        lastOperationText = success
                            ? qsTr("%1 completed: %2").arg(source).arg(message)
                            : (canceled ? qsTr("%1 canceled: %2").arg(source).arg(message)
                                        : qsTr("%1 failed: %2").arg(source).arg(message));
    }

    function requestCancelDriverOperation() {
        if (page.nvidiaInstaller.busy)
            page.nvidiaInstaller.cancelOperation();
        if (page.nvidiaUpdater.busy)
            page.nvidiaUpdater.cancelOperation();
        page.setOperationState(qsTr("System"), qsTr("Cancel requested. Waiting for the active command to stop safely..."), "warning", true);
        page.appendLog(qsTr("System"), qsTr("Cancel requested. Waiting for the active command to stop safely..."));
    }

    function requestSystemRestart() {
        if (!page.systemInfo || !page.systemInfo.requestRestart()) {
            page.appendLog(qsTr("System"), qsTr("Restart request failed. Please restart the computer manually."));
            page.setOperationState(qsTr("System"), qsTr("Restart request failed. Please restart the computer manually."), "error", false);
            return;
        }

        page.appendLog(qsTr("System"), qsTr("Restart requested."));
        page.setOperationState(qsTr("System"), qsTr("Restart requested."), "success", false);
    }

    function markDriverActionStarted(action) {
        requestedDriverAction = action || "";
        pendingDriverStateText = "";
        pendingDriverStateTone = "info";
        postOperationRefreshPending = false;
    }

    function markDriverActionFinished(success) {
        if (!success)
            return;

        if (requestedDriverAction === "closed-install" || requestedDriverAction === "closed-update") {
            const version = page.nvidiaUpdater.latestVersion.length > 0 ? page.nvidiaUpdater.latestVersion : page.installedVersionLabel;
            pendingDriverStateText = version.length > 0
                                     ? qsTr("Closed-source driver prepared: %1. Restart required.").arg(version)
                                     : qsTr("Closed-source driver prepared. Restart required.");
            pendingDriverStateTone = "success";
        } else if (requestedDriverAction === "open-install") {
            pendingDriverStateText = qsTr("Open-source graphics stack prepared. Restart required.");
            pendingDriverStateTone = "success";
        } else if (requestedDriverAction === "deep-clean") {
            pendingDriverStateText = qsTr("NVIDIA driver cleanup completed. Restart recommended.");
            pendingDriverStateTone = "warning";
        }
    }

    function refreshAfterDriverAction() {
        postOperationRefreshPending = true;
        page.appendLog(qsTr("System"), qsTr("Refreshing driver status shown on this page..."));
        page.nvidiaDetector.refresh();
        page.suppressPassiveStatus = true;
        page.nvidiaUpdater.checkForUpdate();
        page.nvidiaInstaller.refreshProprietaryAgreement();
    }

    function closedSourceDriverAlreadyCurrent() {
        return page.driverInstalledLocally && page.catalogAvailable && !page.nvidiaUpdater.updateAvailable;
    }

    function beginClosedSourceInstall() {
        if (page.closedSourceDriverAlreadyCurrent()) {
            currentDriverPopup.open();
            return;
        }

        page.continueClosedSourceInstall();
    }

    function continueClosedSourceInstall() {
        if (page.nvidiaInstaller.proprietaryAgreementRequired) {
            licensePopup.open();
        } else {
            page.markDriverActionStarted("closed-install");
            page.setOperationState(qsTr("Installer"), qsTr("Installing closed-source NVIDIA driver..."), "info", true);
            page.nvidiaInstaller.installProprietary(false);
        }
    }

    function driverVersionMainLabel() {
        if (page.pendingDriverStateText.length > 0)
            return page.pendingDriverStateText;
        if (page.installedVersionLabel.length > 0)
            return page.installedVersionLabel;
        if (page.nvidiaUpdater.latestVersion.length > 0)
            return qsTr("Latest available: %1").arg(page.nvidiaUpdater.latestVersion);
        if (page.catalogAvailable)
            return qsTr("Driver catalog loaded");
        return qsTr("Driver scan pending");
    }

    function gpuMainLabel() {
        if (page.nvidiaDetector.gpuFound)
            return page.nvidiaDetector.gpuName;
        if (page.nvidiaDetector.displayAdapterName.length > 0)
            return page.nvidiaDetector.displayAdapterName;
        return qsTr("No NVIDIA GPU");
    }

    function driverVersionStatusLabel() {
        if (!page.canManageDriverStack && page.virtualMachine)
            return qsTr("Virtual machine detected (%1). Attach or passthrough an NVIDIA GPU before installing drivers.").arg(page.virtualizationType);
        if (!page.canManageDriverStack)
            return qsTr("No NVIDIA GPU or installed NVIDIA driver detected.");
        if (page.postOperationRefreshPending)
            return qsTr("Refreshing installed driver status...");
        if (page.pendingDriverStateText.length > 0)
            return qsTr("The page has recorded the completed operation; system activation may require a restart.");
        if (page.installedVersionLabel.length > 0 && page.nvidiaUpdater.latestVersion.length > 0) {
            if (page.nvidiaUpdater.updateAvailable)
                return qsTr("New version available: %1").arg(page.nvidiaUpdater.latestVersion);
            return qsTr("Installed version is up to date.");
        }
        if (page.installedVersionLabel.length > 0)
            return qsTr("Installed version detected.");
        if (page.nvidiaUpdater.latestVersion.length > 0)
            return qsTr("Not installed. Latest available version: %1").arg(page.nvidiaUpdater.latestVersion);
        if (page.catalogAvailable)
            return qsTr("Driver catalog loaded.");
        return qsTr("Checking whether a newer driver is available...");
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
        const shouldFollow = page.activityFollowTail && activityLog.selectedText.length === 0;
        activityLog.text = activityLog.text.length > 0 ? activityLog.text + "\n" + nextLine : nextLine;
        if (shouldFollow)
            activityLog.cursorPosition = activityLog.length;
    }

    function resumeActivityFollow() {
        activityFollowTail = true;
        activityLog.deselect();
        activityLog.cursorPosition = activityLog.length;
        activityLog.forceActiveFocus();
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
                        Label { text: page.gpuMainLabel(); color: page.textColor; font.pixelSize: Math.round(18 * page.uiScale); font.weight: Font.DemiBold; elide: Text.ElideRight; width: parent.width }
                        Label {
                            width: parent.width
                            visible: !page.nvidiaDetector.gpuFound
                            text: page.virtualMachine ? qsTr("Virtual display detected. NVIDIA passthrough is required for driver management.")
                                                      : qsTr("NVIDIA hardware is required for driver management.")
                            color: page.softTextColor
                            wrapMode: Text.Wrap
                            maximumLineCount: 2
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

                        RowLayout {
                            width: parent.width
                            spacing: 8

                            Label {
                                Layout.fillWidth: true
                                text: qsTr("Driver Version")
                                color: page.softTextColor
                                font.weight: Font.DemiBold
                                font.pixelSize: Math.round(12 * page.uiScale)
                            }
                        }

                        Label {
                            text: page.driverVersionMainLabel()
                            color: page.textColor
                            font.pixelSize: Math.round(18 * page.uiScale)
                            font.weight: Font.DemiBold
                            elide: Text.ElideRight
                            width: parent.width
                        }
                        Label {
                            width: parent.width
                            text: page.driverVersionStatusLabel()
                            color: page.driverVersionStatusColor
                            wrapMode: Text.Wrap
                            maximumLineCount: 2
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
                            visible: page.nvidiaDetector.secureBootKnown
                            text: page.nvidiaDetector.secureBootEnabled
                                  ? qsTr("Kernel module signing may be required.")
                                  : qsTr("No Secure Boot signing requirement detected.")
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

                        Components.RefreshToolButton {
                            id: refreshButton
                            enabled: !page.nvidiaUpdater.busy && !page.nvidiaInstaller.busy
                            busy: page.nvidiaUpdater.busy
                            theme: page.theme
                            uiScale: page.uiScale
                            tooltip: qsTr("Rescan and check updates")
                            onClicked: page.refreshDriverState(true)
                        }
                    }

                    Label {
                        Layout.fillWidth: true
                        text: qsTr("Install, update, deep-clean, or rescan the NVIDIA driver stack. The closed-source path installs the official NVIDIA RPM Fusion driver; the open-source path switches to the community open-source graphics stack.")
                        color: page.softTextColor
                        wrapMode: Text.Wrap
                    }

                    GridLayout {
                        Layout.fillWidth: true
                        columns: width > 920 ? 4 : 1
                        columnSpacing: 8
                        rowSpacing: 8

                        Button {
                            Layout.fillWidth: true
                            text: qsTr("Install Closed Source")
                            enabled: page.canManageDriverStack && !page.nvidiaInstaller.busy && !page.nvidiaUpdater.busy
                            onClicked: page.beginClosedSourceInstall()
                        }

                        Button {
                            Layout.fillWidth: true
                            text: qsTr("Use Open Source Driver")
                            enabled: page.canManageDriverStack && !page.nvidiaUpdater.busy && !page.nvidiaInstaller.busy
                            onClicked: {
                                page.markDriverActionStarted("open-install");
                                page.setOperationState(qsTr("Installer"), qsTr("Switching to the community open-source graphics driver stack..."), "info", true);
                                page.nvidiaInstaller.installOpenSource();
                            }
                        }

                        Button {
                            Layout.fillWidth: true
                            text: qsTr("Deep Clean")
                            enabled: page.canManageDriverStack && page.driverInstalledLocally && !page.nvidiaInstaller.busy && !page.nvidiaUpdater.busy
                            onClicked: {
                                page.markDriverActionStarted("deep-clean");
                                page.setOperationState(qsTr("Installer"), qsTr("Cleaning NVIDIA artifacts..."), "info", true);
                                page.nvidiaInstaller.deepClean();
                            }
                        }

                        Button {
                            Layout.fillWidth: true
                            text: qsTr("Restart System")
                            visible: page.pendingDriverStateText.length > 0
                            enabled: visible && !page.operationRunning
                            onClicked: restartPopup.open()
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
                implicitHeight: Math.round(340 * page.uiScale)
                Layout.preferredHeight: Math.round(340 * page.uiScale)
                Layout.maximumHeight: Math.round(360 * page.uiScale)

                ColumnLayout {
                    id: activityLayout
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 8

                    RowLayout {
                        Layout.fillWidth: true

                        Label {
                            Layout.fillWidth: true
                            text: qsTr("Activity")
                            color: page.textColor
                            font.pixelSize: Math.round(18 * page.uiScale)
                            font.weight: Font.DemiBold
                        }

                        Label {
                            text: page.activityFollowTail ? qsTr("Live") : qsTr("Reading")
                            color: page.activityFollowTail ? (page.theme && page.theme.success ? page.theme.success : page.textColor)
                                                           : page.softTextColor
                            font.pixelSize: Math.round(12 * page.uiScale)
                            font.weight: Font.DemiBold
                        }
                    }

                    Components.StatusBanner {
                        Layout.fillWidth: true
                        theme: page.theme
                        tone: page.lastOperationTone
                        text: page.lastOperationText
                    }

                    ScrollView {
                        id: activityScroll
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        ScrollBar.vertical.policy: ScrollBar.AlwaysOn
                        ScrollBar.horizontal.policy: ScrollBar.AsNeeded
                        background: Rectangle {
                            radius: 10
                            color: page.bgColor
                            border.width: 1
                            border.color: page.borderColor
                        }

                        TextArea {
                            id: activityLog
                            width: activityScroll.availableWidth
                            readOnly: true
                            selectByMouse: true
                            persistentSelection: true
                            wrapMode: Text.Wrap
                            textFormat: TextEdit.PlainText
                            color: page.textColor
                            selectedTextColor: page.bgColor
                            selectionColor: page.theme && page.theme.accentA ? page.theme.accentA : "#3778c2"
                            font.family: "Noto Sans Mono"
                            font.pixelSize: Math.round(12 * page.uiScale)
                            padding: 10
                            background: null

                            Keys.onPressed: function(event) {
                                if (event.key === Qt.Key_PageUp || event.key === Qt.Key_Up || event.key === Qt.Key_Home)
                                    page.activityFollowTail = false;
                            }

                            TapHandler {
                                onTapped: page.activityFollowTail = false
                            }

                            WheelHandler {
                                onWheel: page.activityFollowTail = false
                            }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true

                        Label {
                            Layout.fillWidth: true
                            text: page.activityFollowTail ? qsTr("Following live output") : qsTr("Paused for reading")
                            color: page.softTextColor
                            font.pixelSize: Math.round(12 * page.uiScale)
                        }

                        Button {
                            text: qsTr("Follow")
                            enabled: !page.activityFollowTail
                            onClicked: page.resumeActivityFollow()
                        }

                        Button {
                            text: qsTr("Cancel")
                            enabled: page.operationRunning
                            onClicked: page.requestCancelDriverOperation()
                        }

                        Button {
                            text: qsTr("Clear")
                            onClicked: {
                                activityLog.text = "";
                                page.activityFollowTail = true;
                            }
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
            page.recordOperationResult(qsTr("Installer"), success, message);
            page.markDriverActionFinished(success);
            page.appendLog(qsTr("Installer"), message);
            page.refreshAfterDriverAction();
        }

        function onRemoveFinished(success, message) {
            page.finishOperation(qsTr("Installer"), success, message);
            page.recordOperationResult(qsTr("Installer"), success, message);
            page.markDriverActionFinished(success);
            page.appendLog(qsTr("Installer"), message);
            page.refreshAfterDriverAction();
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
            if (page.postOperationRefreshPending) {
                page.postOperationRefreshPending = false;
                page.appendLog(qsTr("System"), success ? qsTr("Driver page status refreshed.") : qsTr("Driver page status refresh failed."));
            }
            page.suppressPassiveStatus = false;
        }

        function onUpdateFinished(success, message) {
            page.finishOperation(qsTr("Updater"), success, message);
            page.recordOperationResult(qsTr("Updater"), success, message);
            if (page.requestedDriverAction.length === 0)
                page.requestedDriverAction = "closed-update";
            page.markDriverActionFinished(success);
            page.appendLog(qsTr("Updater"), message);
            page.refreshAfterDriverAction();
        }
    }

    Component.onCompleted: {
        page.refreshDriverState(false);
    }

    Popup {
        id: restartPopup
        modal: true
        focus: true
        width: Math.min(page.width - 40, Math.round(520 * page.uiScale))
        x: Math.round((page.width - width) / 2)
        y: Math.round((page.height - implicitHeight) / 2)
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

            Label {
                Layout.fillWidth: true
                text: qsTr("Restart Computer")
                color: page.textColor
                font.pixelSize: Math.round(18 * page.uiScale)
                font.weight: Font.DemiBold
            }

            Label {
                Layout.fillWidth: true
                text: qsTr("A driver operation has completed and the computer must restart before the new graphics stack is active.")
                color: page.softTextColor
                wrapMode: Text.Wrap
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Button {
                    Layout.fillWidth: true
                    text: qsTr("Cancel")
                    onClicked: restartPopup.close()
                }

                Button {
                    Layout.fillWidth: true
                    text: qsTr("Restart Now")
                    onClicked: {
                        restartPopup.close();
                        page.requestSystemRestart();
                    }
                }
            }
        }
    }

    Popup {
        id: currentDriverPopup
        modal: true
        focus: true
        width: Math.min(page.width - 40, Math.round(520 * page.uiScale))
        x: Math.round((page.width - width) / 2)
        y: Math.round((page.height - implicitHeight) / 2)
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

            Label {
                Layout.fillWidth: true
                text: qsTr("Driver Is Already Current")
                color: page.textColor
                font.pixelSize: Math.round(18 * page.uiScale)
                font.weight: Font.DemiBold
            }

            Label {
                Layout.fillWidth: true
                text: qsTr("The installed NVIDIA driver already matches the latest version available from the configured driver sources. Reinstall only if you want to rebuild the driver packages and kernel module.")
                color: page.softTextColor
                wrapMode: Text.Wrap
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Button {
                    Layout.fillWidth: true
                    text: qsTr("Cancel")
                    onClicked: currentDriverPopup.close()
                }

                Button {
                    Layout.fillWidth: true
                    text: qsTr("Reinstall Anyway")
                    onClicked: {
                        currentDriverPopup.close();
                        page.continueClosedSourceInstall();
                    }
                }
            }
        }
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
                        page.markDriverActionStarted("closed-install");
                        page.setOperationState(qsTr("Installer"), qsTr("Installing closed-source NVIDIA driver..."), "info", true);
                        page.nvidiaInstaller.installProprietary(true);
                    }
                }
            }
        }
    }
}
