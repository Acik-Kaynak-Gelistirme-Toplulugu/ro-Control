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
    readonly property string unixDriverUrl: "https://www.nvidia.com/en-us/drivers/unix/"
    readonly property string fedoraGuideUrl: "https://docs.nvidia.com/datacenter/tesla/driver-installation-guide/fedora.html"

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
        const latest = page.nvidiaUpdater.latestVersion;
        if (driverInstalledLocally)
            return latest.length > 0 ? qsTr("Apply Latest (%1)").arg(latest) : qsTr("Apply Latest");
        return latest.length > 0 ? qsTr("Install Latest (%1)").arg(latest) : qsTr("Install Latest");
    }

    function appendLog(source, message) {
        const prefix = source && source.length > 0 ? source : qsTr("System");
        const nextLine = "[" + Qt.formatTime(new Date(), "HH:mm:ss") + "] " + prefix + ": " + message;
        activityLog.text = activityLog.text.length > 0 ? activityLog.text + "\n" + nextLine : nextLine;
        activityLog.cursorPosition = activityLog.length;
    }

    ScrollView {
        id: pageScroll
        anchors.fill: parent
        clip: true
        contentWidth: availableWidth

        ColumnLayout {
            width: pageScroll.availableWidth
            spacing: 10

            Rectangle {
                Layout.fillWidth: true
                radius: 14
                color: page.bannerTone === "error" ? page.dangerBg
                                                   : (page.bannerTone === "success" ? page.successBg : page.infoBg)
                border.width: 1
                border.color: page.borderColor
                implicitHeight: 54

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 10

                    Label { text: page.operationRunning ? qsTr("Working") : qsTr("Status"); color: page.textColor; font.bold: true }

                    Label { Layout.fillWidth: true; text: page.bannerText; color: page.softTextColor; elide: Text.ElideRight }
                }
            }

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

                        Label { text: qsTr("GPU"); color: page.softTextColor; font.bold: true }
                        Label { text: page.nvidiaDetector.gpuFound ? page.nvidiaDetector.gpuName : qsTr("No NVIDIA GPU"); color: page.textColor; font.pixelSize: Math.round(18 * page.uiScale); font.bold: true }
                        Label { text: page.nvidiaDetector.activeDriver; color: page.softTextColor; elide: Text.ElideRight; width: parent.width }
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

                        Label { text: qsTr("Installed Version"); color: page.softTextColor; font.bold: true }
                        Label { text: page.installedVersionLabel.length > 0 ? page.installedVersionLabel : qsTr("Not Installed"); color: page.textColor; font.pixelSize: Math.round(18 * page.uiScale); font.bold: true }
                        Label { text: page.nvidiaUpdater.latestVersion.length > 0 ? qsTr("Official latest: %1").arg(page.nvidiaUpdater.latestVersion) : qsTr("Official latest: Unavailable"); color: page.softTextColor }
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

                        Label { text: qsTr("Session & Security"); color: page.softTextColor; font.bold: true }
                        Label { text: page.nvidiaDetector.sessionType.length > 0 ? page.nvidiaDetector.sessionType : qsTr("Unknown"); color: page.textColor; font.pixelSize: Math.round(18 * page.uiScale); font.bold: true }
                        Label {
                            text: page.nvidiaDetector.secureBootKnown
                                  ? (page.nvidiaDetector.secureBootEnabled ? qsTr("Secure Boot: Enabled")
                                                                           : qsTr("Secure Boot: Disabled"))
                                  : qsTr("Secure Boot: Unknown")
                            color: page.softTextColor
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

                    Label {
                        text: qsTr("Driver Actions")
                        color: page.textColor
                        font.pixelSize: Math.round(18 * page.uiScale)
                        font.bold: true
                    }

                    Label {
                        Layout.fillWidth: true
                        text: page.nvidiaInstaller.proprietaryAgreementRequired ? page.nvidiaInstaller.proprietaryAgreementText : qsTr("Latest version information is resolved from the official NVIDIA Unix driver page. Fedora workflow guidance follows the official NVIDIA Fedora installation guide.")
                        wrapMode: Text.Wrap
                        color: page.softTextColor
                    }

                    Text {
                        Layout.fillWidth: true
                        textFormat: Text.RichText
                        color: page.softTextColor
                        linkColor: page.textColor
                        text: "<a href=\"" + page.unixDriverUrl + "\">" + page.unixDriverUrl + "</a><br><a href=\"" + page.fedoraGuideUrl + "\">" + page.fedoraGuideUrl + "</a>"
                        onLinkActivated: function(link) { Qt.openUrlExternally(link) }
                    }

                    CheckBox {
                        id: eulaAccept
                        visible: page.nvidiaInstaller.proprietaryAgreementRequired
                        text: qsTr("I reviewed the official NVIDIA license outside ro-Control")
                        palette.text: page.textColor
                    }

                    GridLayout {
                        Layout.fillWidth: true
                        columns: width > 920 ? 3 : 1
                        columnSpacing: 8
                        rowSpacing: 8

                        Button {
                            Layout.fillWidth: true
                            text: qsTr("Install Proprietary")
                            enabled: !page.nvidiaInstaller.busy && (!page.nvidiaInstaller.proprietaryAgreementRequired || eulaAccept.checked)
                            onClicked: {
                                page.setOperationState(qsTr("Installer"), qsTr("Installing proprietary NVIDIA driver..."), "info", true);
                                page.nvidiaInstaller.installProprietary(eulaAccept.checked);
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
                            text: qsTr("Remove Driver")
                            enabled: !page.nvidiaInstaller.busy
                            onClicked: {
                                page.setOperationState(qsTr("Installer"), qsTr("Removing NVIDIA driver..."), "info", true);
                                page.nvidiaInstaller.remove();
                            }
                        }

                        Button {
                            Layout.fillWidth: true
                            text: qsTr("Check Updates")
                            enabled: !page.nvidiaUpdater.busy && !page.nvidiaInstaller.busy
                            onClicked: {
                                page.setOperationState(qsTr("Updater"), qsTr("Checking official NVIDIA driver sources..."), "info", true);
                                page.suppressPassiveStatus = true;
                                page.nvidiaUpdater.checkForUpdate();
                            }
                        }

                        Button {
                            Layout.fillWidth: true
                            text: qsTr("Rescan")
                            enabled: !page.nvidiaUpdater.busy && !page.nvidiaInstaller.busy
                            onClicked: {
                                page.nvidiaDetector.refresh();
                                page.nvidiaInstaller.refreshProprietaryAgreement();
                                page.suppressPassiveStatus = true;
                                page.nvidiaUpdater.checkForUpdate();
                            }
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                visible: page.nvidiaUpdater.availableVersions.length > 0
                radius: 14
                color: page.cardColor
                border.width: 1
                border.color: page.borderColor
                implicitHeight: versionLayout.implicitHeight + 24

                ColumnLayout {
                    id: versionLayout
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 10

                    Label {
                        text: qsTr("Version Selection")
                        color: page.textColor
                        font.pixelSize: Math.round(18 * page.uiScale)
                        font.bold: true
                    }

                    Label {
                        Layout.fillWidth: true
                        text: qsTr("Use this area to test or switch to an older repository version.")
                        wrapMode: Text.Wrap
                        color: page.softTextColor
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        ComboBox {
                            id: versionPicker
                            Layout.fillWidth: true
                            model: page.nvidiaUpdater.availableVersions
                            enabled: model.length > 0
                            palette.text: page.textColor
                            palette.buttonText: page.textColor
                        }

                        Button {
                            text: qsTr("Apply Selected")
                            enabled: !page.nvidiaUpdater.busy && !page.nvidiaInstaller.busy && versionPicker.currentIndex >= 0 && versionPicker.count > 0
                            onClicked: {
                                page.setOperationState(qsTr("Updater"), qsTr("Applying selected version..."), "info", true);
                                page.nvidiaUpdater.applyVersion(versionPicker.currentText);
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
                        font.bold: true
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

                        Button {
                            text: qsTr("Deep Clean")
                            enabled: !page.nvidiaInstaller.busy
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
                        font.bold: true
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
        page.nvidiaDetector.refresh();
        page.suppressPassiveStatus = true;
        page.nvidiaUpdater.checkForUpdate();
        page.nvidiaInstaller.refreshProprietaryAgreement();
    }
}
