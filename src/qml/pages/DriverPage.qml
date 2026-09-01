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
    readonly property string installedDriverSource: page.nvidiaDetector.installedDriverSource || "none"
    readonly property bool driverInstalledLocally: page.confirmedDriverInstalledLocally || page.pendingDriverStateText.length > 0 || page.installedDriverSource !== "none"
    readonly property bool virtualMachine: page.systemInfo && page.systemInfo.virtualMachine
    readonly property string virtualizationType: page.virtualMachine ? page.systemInfo.virtualizationType : ""
    readonly property bool canManageDriverStack: page.nvidiaDetector.gpuFound || page.driverInstalledLocally
    readonly property bool closedSourceDriverDetected: page.installedDriverSource === "closed-source" || page.installedDriverSource === "mixed"
    readonly property bool openSourceDriverDetected: page.installedDriverSource === "open-source" || page.installedDriverSource === "mixed"
    readonly property string installedVersionLabel: page.nvidiaDetector.driverVersion.length > 0 ? page.nvidiaDetector.driverVersion : page.nvidiaUpdater.currentVersion
    readonly property bool catalogAvailable: page.nvidiaUpdater.latestVersion.length > 0 || page.nvidiaUpdater.availableVersions.length > 0
    readonly property color driverVersionStatusColor: page.pendingDriverStateText.length > 0
                                                      ? (page.pendingDriverStateTone === "warning"
                                                         ? (theme && theme.warning ? theme.warning : page.softTextColor)
                                                         : (theme && theme.success ? theme.success : page.softTextColor))
                                                      : page.nvidiaUpdater.updateAvailable
                                                      ? (theme && theme.warning ? theme.warning : page.softTextColor)
                                                      : page.softTextColor
    readonly property color bgColor: theme && theme.card ? theme.card : (page.darkMode ? "#29233B" : "#FFFFFF")
    readonly property color cardColor: theme && theme.cardStrong ? theme.cardStrong : (page.darkMode ? "#342D4A" : "#F1F5F9")
    readonly property color borderColor: theme && theme.border ? theme.border : (page.darkMode ? "#4D436B" : "#CBD5E1")
    readonly property color textColor: theme && theme.text ? theme.text : (page.darkMode ? "#F8FAFC" : "#0F172A")
    readonly property color softTextColor: theme && theme.textSoft ? theme.textSoft : (page.darkMode ? "#94A3B8" : "#64748B")
    readonly property color infoBg: theme && theme.infoBg ? theme.infoBg : (page.darkMode ? "#1E2548" : "#EFF6FF")
    readonly property color successBg: theme && theme.successBg ? theme.successBg : (page.darkMode ? "#143828" : "#ECFDF5")
    readonly property color warningBg: theme && theme.warningBg ? theme.warningBg : (page.darkMode ? "#3A2E12" : "#FFFBEB")
    readonly property color dangerBg: theme && theme.dangerBg ? theme.dangerBg : (page.darkMode ? "#3D171E" : "#FEF2F2")
    readonly property color accentColor: theme && theme.accentA ? theme.accentA : (page.darkMode ? "#818CF8" : "#4F46E5")

    component DriverActionTile: AbstractButton {
        id: tile
        property string title: ""
        property string subtitle: ""
        property color accentColor: "#10B981"
        property bool activeBadge: false
        property string badgeText: ""
        property string tooltipText: ""

        Layout.fillWidth: true
        implicitHeight: Math.round(68 * page.uiScale)
        hoverEnabled: true

        scale: !enabled ? 1.0 : (down ? 0.98 : (hovered ? 1.012 : 1.0))
        opacity: enabled ? 1.0 : 0.45

        Behavior on scale {
            NumberAnimation { duration: 120; easing.type: Easing.OutQuad }
        }
        Behavior on opacity {
            NumberAnimation { duration: 150 }
        }

        ToolTip.visible: tooltipText.length > 0 && hovered
        ToolTip.text: tooltipText
        ToolTip.delay: 300

        background: Rectangle {
            radius: 10
            color: !tile.enabled ? page.cardColor
                   : tile.down ? Qt.darker(page.bgColor, 1.05)
                   : tile.hovered ? (page.darkMode ? Qt.tint(page.bgColor, Qt.rgba(tile.accentColor.r, tile.accentColor.g, tile.accentColor.b, 0.14))
                                                   : Qt.tint(page.bgColor, Qt.rgba(tile.accentColor.r, tile.accentColor.g, tile.accentColor.b, 0.08)))
                   : page.bgColor
            border.width: tile.hovered && tile.enabled ? 1.5 : 1
            border.color: tile.hovered && tile.enabled ? tile.accentColor : page.borderColor

            Behavior on border.color {
                ColorAnimation { duration: 150 }
            }
            Behavior on color {
                ColorAnimation { duration: 150 }
            }

            Rectangle {
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.margins: 10
                width: 4
                radius: 2
                color: tile.accentColor
                visible: tile.enabled
                opacity: tile.hovered ? 1.0 : 0.7
            }
        }

        contentItem: ColumnLayout {
            anchors.fill: parent
            anchors.leftMargin: 20
            anchors.rightMargin: 16
            anchors.topMargin: 12
            anchors.bottomMargin: 12
            spacing: 3

            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                Label {
                    Layout.fillWidth: true
                    text: tile.title
                    color: page.textColor
                    font.pixelSize: Math.round(13 * page.uiScale)
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                }

                Rectangle {
                    visible: tile.activeBadge
                    Layout.preferredHeight: Math.round(18 * page.uiScale)
                    Layout.preferredWidth: badgeLabel.implicitWidth + 10
                    radius: 4
                    color: page.darkMode ? "#064E3B" : "#ECFDF5"
                    border.width: 1
                    border.color: "#10B981"

                    Label {
                        id: badgeLabel
                        anchors.centerIn: parent
                        text: tile.badgeText.length > 0 ? tile.badgeText : qsTr("ACTIVE")
                        color: "#10B981"
                        font.pixelSize: Math.round(9 * page.uiScale)
                        font.weight: Font.Bold
                    }
                }
            }

            Label {
                Layout.fillWidth: true
                text: tile.subtitle
                color: page.softTextColor
                font.pixelSize: Math.round(11 * page.uiScale)
                elide: Text.ElideRight
            }
        }
    }

    component ModernMiniButton: Button {
        id: miniBtn
        property string tone: "neutral"
        property real uiScale: page.uiScale

        implicitHeight: Math.round(32 * uiScale)
        leftPadding: Math.round(14 * uiScale)
        rightPadding: Math.round(14 * uiScale)

        scale: !enabled ? 1.0 : (down ? 0.96 : (hovered ? 1.02 : 1.0))
        Behavior on scale { NumberAnimation { duration: 100 } }

        contentItem: Label {
            text: miniBtn.text
            font.pixelSize: Math.round(11 * miniBtn.uiScale)
            font.weight: Font.DemiBold
            color: !miniBtn.enabled ? page.softTextColor
                   : tone === "danger" ? (miniBtn.hovered ? "#FFFFFF" : "#EF4444")
                   : tone === "primary" ? "#FFFFFF"
                   : tone === "success" ? "#FFFFFF"
                   : page.textColor
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }

        background: Rectangle {
            radius: 6
            color: !miniBtn.enabled ? Qt.rgba(0,0,0,0)
                   : tone === "primary" ? (miniBtn.down ? Qt.darker(page.accentColor, 1.1) : (miniBtn.hovered ? Qt.lighter(page.accentColor, 1.1) : page.accentColor))
                   : tone === "danger" ? (miniBtn.down ? "#DC2626" : (miniBtn.hovered ? "#EF4444" : (page.darkMode ? "#3D171E" : "#FEE2E2")))
                   : tone === "success" ? (miniBtn.down ? "#16A34A" : (miniBtn.hovered ? "#22C55E" : (page.darkMode ? "#143828" : "#DCFCE7")))
                   : (miniBtn.down ? Qt.darker(page.bgColor, 1.1) : (miniBtn.hovered ? page.cardColor : page.bgColor))
            border.width: 1
            border.color: !miniBtn.enabled ? page.borderColor
                         : tone === "danger" ? "#EF4444"
                         : tone === "primary" ? page.accentColor
                         : tone === "success" ? "#22C55E"
                         : page.borderColor
            opacity: miniBtn.enabled ? 1.0 : 0.5
        }
    }

    component ModernDialogButton: Button {
        id: dlgBtn
        property string tone: "neutral"
        property real uiScale: page.uiScale

        Layout.fillWidth: true
        implicitHeight: Math.round(38 * uiScale)

        scale: !enabled ? 1.0 : (down ? 0.97 : (hovered ? 1.015 : 1.0))
        Behavior on scale { NumberAnimation { duration: 100 } }

        contentItem: Label {
            text: dlgBtn.text
            font.pixelSize: Math.round(13 * dlgBtn.uiScale)
            font.weight: Font.DemiBold
            color: !dlgBtn.enabled ? page.softTextColor
                   : tone === "primary" || tone === "danger" || tone === "success" ? "#FFFFFF"
                   : page.textColor
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }

        background: Rectangle {
            radius: 8
            color: !dlgBtn.enabled ? page.cardColor
                   : tone === "primary" ? (dlgBtn.down ? Qt.darker(page.accentColor, 1.1) : (dlgBtn.hovered ? Qt.lighter(page.accentColor, 1.08) : page.accentColor))
                   : tone === "danger" ? (dlgBtn.down ? "#DC2626" : (dlgBtn.hovered ? "#EF4444" : "#DC2626"))
                   : tone === "success" ? (dlgBtn.down ? "#16A34A" : (dlgBtn.hovered ? "#22C55E" : "#16A34A"))
                   : (dlgBtn.down ? Qt.darker(page.bgColor, 1.08) : (dlgBtn.hovered ? page.cardColor : page.bgColor))
            border.width: 1
            border.color: !dlgBtn.enabled ? page.borderColor
                         : tone === "primary" ? Qt.tint(page.accentColor, "#33FFFFFF")
                         : tone === "danger" ? Qt.tint("#EF4444", "#33FFFFFF")
                         : tone === "success" ? Qt.tint("#22C55E", "#33FFFFFF")
                         : page.borderColor
        }
    }

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
        lastOperationTone = success ? "success" : "error";
        lastOperationText = success
                            ? qsTr("%1 completed: %2").arg(source).arg(message)
                            : qsTr("%1 failed: %2").arg(source).arg(message);
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
        if (page.openSourceDriverDetected) {
            sourceSwitchBlockedPopup.requestedTarget = "closed";
            sourceSwitchBlockedPopup.open();
            return;
        }

        if (page.closedSourceDriverAlreadyCurrent()) {
            currentDriverPopup.open();
            return;
        }

        page.continueClosedSourceInstall();
    }

    function beginOpenSourceInstall() {
        if (page.closedSourceDriverDetected) {
            sourceSwitchBlockedPopup.requestedTarget = "open";
            sourceSwitchBlockedPopup.open();
            return;
        }

        page.markDriverActionStarted("open-install");
        page.setOperationState(qsTr("Installer"), qsTr("Switching to the open-source NVIDIA driver stack..."), "info", true);
        page.nvidiaInstaller.installOpenSource();
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
            return qsTr("VM detected. NVIDIA passthrough required.");
        if (!page.canManageDriverStack)
            return qsTr("No NVIDIA GPU or driver.");
        if (page.postOperationRefreshPending)
            return qsTr("Refreshing status...");
        if (page.pendingDriverStateText.length > 0)
            return qsTr("Restart may be required.");
        if (page.installedVersionLabel.length > 0 && page.nvidiaUpdater.latestVersion.length > 0) {
            if (page.nvidiaUpdater.updateAvailable)
                return qsTr("New version available: %1").arg(page.nvidiaUpdater.latestVersion);
            return qsTr("Up to date.");
        }
        if (page.installedVersionLabel.length > 0)
            return qsTr("Installed.");
        if (page.nvidiaUpdater.latestVersion.length > 0)
            return qsTr("Latest: %1").arg(page.nvidiaUpdater.latestVersion);
        if (page.catalogAvailable)
            return qsTr("Catalog loaded.");
        return qsTr("Checking updates...");
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

    function driverSourceLabel() {
        if (page.installedDriverSource === "closed-source")
            return qsTr("Closed-source");
        if (page.installedDriverSource === "open-source")
            return qsTr("Open-source");
        if (page.installedDriverSource === "mixed")
            return qsTr("Mixed driver state");
        return qsTr("Not detected");
    }

    function secureBootStatusDetail() {
        if (!page.nvidiaDetector.secureBootKnown)
            return qsTr("State unreadable.");
        return page.nvidiaDetector.secureBootEnabled
               ? qsTr("Signing may be required.")
               : qsTr("No signing required.");
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
                    implicitHeight: Math.round(128 * page.uiScale)
                    radius: 14
                    color: page.cardColor
                    border.width: 1
                    border.color: page.borderColor

                    Column {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 6

                        Label { text: qsTr("GPU"); color: page.softTextColor; font.weight: Font.DemiBold; font.pixelSize: Math.round(11 * page.uiScale) }
                        Label { text: page.gpuMainLabel(); color: page.textColor; font.pixelSize: Math.round(17 * page.uiScale); font.weight: Font.DemiBold; elide: Text.ElideRight; width: parent.width }
                        Label {
                            width: parent.width
                            visible: !page.nvidiaDetector.gpuFound
                            text: page.virtualMachine ? qsTr("VM display. Use NVIDIA passthrough.")
                                                      : qsTr("NVIDIA hardware required.")
                            color: page.softTextColor
                            wrapMode: Text.Wrap
                            maximumLineCount: 2
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: Math.round(128 * page.uiScale)
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
                                text: qsTr("Driver")
                                color: page.softTextColor
                                font.weight: Font.DemiBold
                                font.pixelSize: Math.round(11 * page.uiScale)
                            }
                        }

                        Label {
                            text: page.driverVersionMainLabel()
                            color: page.textColor
                            font.pixelSize: Math.round(17 * page.uiScale)
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
                        Label {
                            width: parent.width
                            text: qsTr("Stack: %1").arg(page.driverSourceLabel())
                            color: page.softTextColor
                            wrapMode: Text.Wrap
                            maximumLineCount: 2
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: Math.round(128 * page.uiScale)
                    radius: 14
                    color: page.cardColor
                    border.width: 1
                    border.color: page.borderColor

                    Column {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 6

                        Label { text: qsTr("Secure Boot"); color: page.softTextColor; font.weight: Font.DemiBold; font.pixelSize: Math.round(11 * page.uiScale) }
                        Label {
                            text: page.nvidiaDetector.secureBootKnown
                                  ? (page.nvidiaDetector.secureBootEnabled ? qsTr("Enabled")
                                                                           : qsTr("Disabled"))
                                  : qsTr("Unknown")
                            color: page.textColor
                            font.weight: Font.DemiBold
                            font.pixelSize: Math.round(20 * page.uiScale)
                        }
                        Label {
                            width: parent.width
                            text: page.secureBootStatusDetail()
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
                            text: qsTr("Driver Stack")
                            color: page.textColor
                            font.pixelSize: Math.round(18 * page.uiScale)
                            font.weight: Font.DemiBold
                        }

                        Components.RefreshToolButton {
                            id: refreshButton
                            enabled: !page.nvidiaUpdater.busy && !page.nvidiaInstaller.busy
                            busy: page.nvidiaUpdater.busy
                            theme: page.theme
                            darkMode: page.darkMode
                            uiScale: page.uiScale
                            tooltip: qsTr("Rescan and check updates")
                            onClicked: page.refreshDriverState(true)
                        }
                    }

                    Label {
                        Layout.fillWidth: true
                        text: qsTr("Manage closed-source and open-source NVIDIA stacks. Switching stacks requires Deep Clean first.")
                        color: page.softTextColor
                        wrapMode: Text.Wrap
                    }

                    GridLayout {
                        Layout.fillWidth: true
                        columns: width > 920 ? (page.pendingDriverStateText.length > 0 ? 5 : 4) : (width > 560 ? 2 : 1)
                        columnSpacing: 10
                        rowSpacing: 10

                        DriverActionTile {
                            title: qsTr("Closed Source")
                            subtitle: qsTr("NVIDIA Official Release • Proprietary")
                            accentColor: "#10B981"
                            activeBadge: page.closedSourceDriverDetected
                            badgeText: qsTr("INSTALLED")
                            enabled: page.canManageDriverStack && !page.openSourceDriverDetected && !page.nvidiaInstaller.busy && !page.nvidiaUpdater.busy
                            tooltipText: page.openSourceDriverDetected ? qsTr("Deep Clean is required before switching from open-source to closed-source.") : qsTr("Install official proprietary NVIDIA driver release (akmod-nvidia).")
                            onClicked: page.beginClosedSourceInstall()
                        }

                        DriverActionTile {
                            title: qsTr("Open Source")
                            subtitle: qsTr("Community Release • akmod-open")
                            accentColor: "#0EA5E9"
                            activeBadge: page.openSourceDriverDetected
                            badgeText: qsTr("INSTALLED")
                            enabled: page.canManageDriverStack && !page.closedSourceDriverDetected && !page.nvidiaUpdater.busy && !page.nvidiaInstaller.busy
                            tooltipText: page.closedSourceDriverDetected ? qsTr("Deep Clean is required before switching from closed-source to open-source.") : qsTr("Install community open-source kernel driver package (akmod-nvidia-open).")
                            onClicked: page.beginOpenSourceInstall()
                        }

                        DriverActionTile {
                            title: qsTr("Deep Clean")
                            subtitle: qsTr("Purge artifacts & stale DKMS")
                            accentColor: "#F59E0B"
                            enabled: page.canManageDriverStack && page.driverInstalledLocally && !page.nvidiaInstaller.busy && !page.nvidiaUpdater.busy
                            tooltipText: qsTr("Remove leftover configurations and prepare system for clean driver installation.")
                            onClicked: {
                                page.markDriverActionStarted("deep-clean");
                                page.setOperationState(qsTr("Installer"), qsTr("Cleaning NVIDIA artifacts..."), "info", true);
                                page.nvidiaInstaller.deepClean();
                            }
                        }

                        DriverActionTile {
                            title: qsTr("Rebuild Modules")
                            subtitle: qsTr("Akmods & initramfs regeneration")
                            accentColor: "#8B5CF6"
                            enabled: page.canManageDriverStack && page.driverInstalledLocally && !page.nvidiaInstaller.busy && !page.nvidiaUpdater.busy
                            tooltipText: qsTr("Force-rebuilds akmod kernel modules and regenerates initramfs after kernel updates.")
                            onClicked: {
                                page.markDriverActionStarted("rebuild-modules");
                                page.setOperationState(qsTr("Installer"), qsTr("Rebuilding kernel modules & initramfs..."), "info", true);
                                page.nvidiaInstaller.rebuildKernelModules();
                            }
                        }

                        DriverActionTile {
                            visible: page.pendingDriverStateText.length > 0
                            title: qsTr("Restart System")
                            subtitle: qsTr("Reboot to activate new driver")
                            accentColor: "#EF4444"
                            enabled: visible && !page.operationRunning
                            tooltipText: qsTr("System restart required to load newly installed kernel driver.")
                            onClicked: restartPopup.open()
                        }

                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                radius: 10
                color: page.cardColor
                border.width: 1
                border.color: page.borderColor
                implicitHeight: Math.round(320 * page.uiScale)
                Layout.preferredHeight: Math.round(320 * page.uiScale)
                Layout.maximumHeight: Math.round(340 * page.uiScale)

                ColumnLayout {
                    id: activityLayout
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 7

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        Label {
                            Layout.fillWidth: true
                            text: qsTr("Activity")
                            color: page.textColor
                            font.pixelSize: Math.round(16 * page.uiScale)
                            font.weight: Font.DemiBold
                        }

                        Rectangle {
                            Layout.preferredWidth: Math.round(92 * page.uiScale)
                            Layout.preferredHeight: Math.round(26 * page.uiScale)
                            radius: 7
                            color: page.activityFollowTail ? page.successBg : page.bgColor
                            border.width: 1
                            border.color: page.activityFollowTail ? (page.theme && page.theme.success ? page.theme.success : page.borderColor)
                                                                  : page.borderColor

                            Label {
                                anchors.centerIn: parent
                                text: page.activityFollowTail ? qsTr("Live") : qsTr("Reading")
                                color: page.activityFollowTail ? (page.theme && page.theme.success ? page.theme.success : page.textColor)
                                                               : page.softTextColor
                                font.pixelSize: Math.round(11 * page.uiScale)
                                font.weight: Font.DemiBold
                            }
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
                            radius: 8
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
                            font.family: (Qt.platform.os === "osx") ? "Menlo" : "Monospace"
                            font.pixelSize: Math.round(11 * page.uiScale)
                            padding: 8
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
                        spacing: 8

                        Label {
                            Layout.fillWidth: true
                            text: page.operationRunning
                                  ? qsTr("Command output is being captured.")
                                  : (page.activityFollowTail ? qsTr("Following output") : qsTr("Paused for reading"))
                            color: page.softTextColor
                            font.pixelSize: Math.round(11 * page.uiScale)
                        }

                        ModernMiniButton {
                            text: qsTr("Follow")
                            enabled: !page.activityFollowTail
                            tone: "neutral"
                            onClicked: page.resumeActivityFollow()
                        }

                        ModernMiniButton {
                            text: qsTr("Cancel")
                            enabled: page.operationRunning
                            tone: "danger"
                            onClicked: page.requestCancelDriverOperation()
                        }

                        ModernMiniButton {
                            text: qsTr("Clear")
                            tone: "neutral"
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
            if (success && !page.nvidiaUpdater.updateAvailable && page.installedVersionLabel.length > 0)
                page.appendLog(qsTr("Updater"), qsTr("Driver is already up to date."));
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

                ModernDialogButton {
                    text: qsTr("Cancel")
                    tone: "neutral"
                    onClicked: restartPopup.close()
                }

                ModernDialogButton {
                    text: qsTr("Restart Now")
                    tone: "danger"
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

                ModernDialogButton {
                    text: qsTr("Cancel")
                    tone: "neutral"
                    onClicked: currentDriverPopup.close()
                }

                ModernDialogButton {
                    text: qsTr("Reinstall Anyway")
                    tone: "primary"
                    onClicked: {
                        currentDriverPopup.close();
                        page.continueClosedSourceInstall();
                    }
                }
            }
        }
    }

    Popup {
        id: sourceSwitchBlockedPopup
        property string requestedTarget: "closed"
        modal: true
        focus: true
        width: Math.min(page.width - 40, Math.round(540 * page.uiScale))
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
                text: qsTr("Deep Clean Required")
                color: page.textColor
                font.pixelSize: Math.round(18 * page.uiScale)
                font.weight: Font.DemiBold
            }

            Label {
                Layout.fillWidth: true
                text: sourceSwitchBlockedPopup.requestedTarget === "closed"
                      ? qsTr("An open-source driver stack is currently detected. Run Deep Clean before installing the closed-source driver.")
                      : qsTr("A closed-source driver stack is currently detected. Run Deep Clean before installing the open-source driver.")
                color: page.softTextColor
                wrapMode: Text.Wrap
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                ModernDialogButton {
                    text: qsTr("Cancel")
                    tone: "neutral"
                    onClicked: sourceSwitchBlockedPopup.close()
                }

                ModernDialogButton {
                    text: qsTr("Deep Clean")
                    tone: "primary"
                    enabled: page.canManageDriverStack && page.driverInstalledLocally && !page.operationRunning
                    onClicked: {
                        sourceSwitchBlockedPopup.close();
                        page.markDriverActionStarted("deep-clean");
                        page.setOperationState(qsTr("Installer"), qsTr("Cleaning NVIDIA artifacts..."), "info", true);
                        page.nvidiaInstaller.deepClean();
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

                ModernDialogButton {
                    text: qsTr("Reject")
                    tone: "neutral"
                    onClicked: {
                        licensePopup.close();
                    }
                }

                ModernDialogButton {
                    text: qsTr("Accept")
                    tone: "success"
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
