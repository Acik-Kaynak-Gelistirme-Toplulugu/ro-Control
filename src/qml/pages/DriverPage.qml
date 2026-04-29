import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: page

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
    readonly property bool backendBusy: nvidiaInstaller.busy || nvidiaUpdater.busy
    readonly property bool operationRunning: page.operationActive || page.backendBusy
    readonly property bool remoteDriverCatalogAvailable: nvidiaUpdater.availableVersions.length > 0
    readonly property bool canInstallLatestRemoteDriver: nvidiaDetector.gpuFound && remoteDriverCatalogAvailable
    readonly property bool driverInstalledLocally: nvidiaDetector.driverVersion.length > 0 || nvidiaUpdater.currentVersion.length > 0
    readonly property string installedVersionLabel: nvidiaDetector.driverVersion.length > 0 ? nvidiaDetector.driverVersion : nvidiaUpdater.currentVersion
    readonly property bool catalogAvailable: nvidiaUpdater.availableVersions.length > 0

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

    function appendLog(source, message) {
        const prefix = source && source.length > 0 ? source : qsTr("System");
        activityLog.append("[" + Qt.formatTime(new Date(), "HH:mm:ss") + "] " + prefix + ": " + message);
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
                        Label { text: nvidiaDetector.gpuFound ? nvidiaDetector.gpuName : qsTr("Not Detected"); color: page.textColor; font.pixelSize: Math.round(18 * page.uiScale); font.bold: true }
                        Label { text: nvidiaDetector.activeDriver; color: page.softTextColor; elide: Text.ElideRight; width: parent.width }
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
                        Label { text: page.installedVersionLabel.length > 0 ? page.installedVersionLabel : qsTr("None"); color: page.textColor; font.pixelSize: Math.round(18 * page.uiScale); font.bold: true }
                        Label { text: nvidiaUpdater.latestVersion.length > 0 ? qsTr("Latest: %1").arg(nvidiaUpdater.latestVersion) : qsTr("Latest: Unknown"); color: page.softTextColor }
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
                        Label { text: nvidiaDetector.sessionType.length > 0 ? nvidiaDetector.sessionType : qsTr("Unknown"); color: page.textColor; font.pixelSize: Math.round(18 * page.uiScale); font.bold: true }
                        Label { text: nvidiaDetector.secureBootEnabled ? qsTr("Secure Boot: Enabled") : qsTr("Secure Boot: Disabled / Unknown"); color: page.softTextColor }
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
                        text: nvidiaInstaller.proprietaryAgreementRequired ? nvidiaInstaller.proprietaryAgreementText : qsTr("Use safe guided operations for install, update, and cleanup.")
                        wrapMode: Text.Wrap
                        color: page.softTextColor
                    }

                    CheckBox {
                        id: eulaAccept
                        visible: nvidiaInstaller.proprietaryAgreementRequired
                        text: qsTr("I reviewed the NVIDIA license terms")
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
                            enabled: !nvidiaInstaller.busy && (!nvidiaInstaller.proprietaryAgreementRequired || eulaAccept.checked)
                            onClicked: {
                                page.setOperationState(qsTr("Installer"), qsTr("Installing proprietary NVIDIA driver..."), "info", true);
                                nvidiaInstaller.installProprietary(eulaAccept.checked);
                            }
                        }

                        Button {
                            Layout.fillWidth: true
                            text: page.driverInstalledLocally ? qsTr("Apply Latest") : qsTr("Install Latest")
                            enabled: !nvidiaUpdater.busy && !nvidiaInstaller.busy && (nvidiaUpdater.updateAvailable || page.catalogAvailable)
                            onClicked: {
                                page.setOperationState(qsTr("Updater"), qsTr("Applying latest online version..."), "info", true);
                                nvidiaUpdater.applyUpdate();
                            }
                        }

                        Button {
                            Layout.fillWidth: true
                            text: qsTr("Remove Driver")
                            enabled: !nvidiaInstaller.busy
                            onClicked: {
                                page.setOperationState(qsTr("Installer"), qsTr("Removing NVIDIA driver..."), "info", true);
                                nvidiaInstaller.remove();
                            }
                        }

                        Button {
                            Layout.fillWidth: true
                            text: qsTr("Check Updates")
                            enabled: !nvidiaUpdater.busy && !nvidiaInstaller.busy
                            onClicked: {
                                page.setOperationState(qsTr("Updater"), qsTr("Checking repository for updates..."), "info", true);
                                nvidiaUpdater.checkForUpdate();
                            }
                        }

                        Button {
                            Layout.fillWidth: true
                            text: qsTr("Rescan")
                            enabled: !nvidiaUpdater.busy && !nvidiaInstaller.busy
                            onClicked: {
                                nvidiaDetector.refresh();
                                nvidiaInstaller.refreshProprietaryAgreement();
                                nvidiaUpdater.refreshAvailableVersions();
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        visible: page.showAdvancedInfo
                        radius: 10
                        color: page.bgColor
                        border.width: 1
                        border.color: page.borderColor
                        implicitHeight: advancedLayout.implicitHeight + 20

                        ColumnLayout {
                            id: advancedLayout
                            anchors.fill: parent
                            anchors.margins: 10
                            spacing: 8

                            Label {
                                text: qsTr("Diagnostics")
                                color: page.textColor
                                font.bold: true
                            }

                            GridLayout {
                                Layout.fillWidth: true
                                columns: width > 640 ? 2 : 1
                                columnSpacing: 8
                                rowSpacing: 8

                                Button {
                                    Layout.fillWidth: true
                                    text: qsTr("Install Open Modules")
                                    enabled: !nvidiaInstaller.busy
                                    onClicked: {
                                        page.setOperationState(qsTr("Installer"), qsTr("Installing open NVIDIA kernel modules..."), "info", true);
                                        nvidiaInstaller.installOpenSource();
                                    }
                                }

                                Button {
                                    Layout.fillWidth: true
                                    text: qsTr("Deep Clean")
                                    enabled: !nvidiaInstaller.busy
                                    onClicked: {
                                        page.setOperationState(qsTr("Installer"), qsTr("Cleaning NVIDIA artifacts..."), "info", true);
                                        nvidiaInstaller.deepClean();
                                    }
                                }
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 8

                                ComboBox {
                                    id: versionPicker
                                    Layout.fillWidth: true
                                    model: nvidiaUpdater.availableVersions
                                    enabled: model.length > 0
                                    palette.text: page.textColor
                                    palette.buttonText: page.textColor
                                }

                                Button {
                                    text: qsTr("Apply Selected")
                                    enabled: !nvidiaUpdater.busy && !nvidiaInstaller.busy && versionPicker.currentIndex >= 0 && versionPicker.count > 0
                                    onClicked: {
                                        page.setOperationState(qsTr("Updater"), qsTr("Applying selected version..."), "info", true);
                                        nvidiaUpdater.applyVersion(versionPicker.currentText);
                                    }
                                }
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
                        background: Rectangle {
                            radius: 10
                            color: page.bgColor
                            border.width: 1
                            border.color: page.borderColor
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true

                        Label {
                            Layout.fillWidth: true
                            visible: page.showAdvancedInfo
                            text: nvidiaDetector.verificationReport
                            color: page.softTextColor
                            elide: Text.ElideRight
                        }

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
        target: nvidiaInstaller

        function onProgressMessage(message) {
            page.setOperationState(qsTr("Installer"), message, "info", true);
            page.appendLog(qsTr("Installer"), message);
        }

        function onInstallFinished(success, message) {
            page.finishOperation(qsTr("Installer"), success, message);
            page.appendLog(qsTr("Installer"), message);
            nvidiaDetector.refresh();
            nvidiaUpdater.checkForUpdate();
            nvidiaInstaller.refreshProprietaryAgreement();
        }

        function onRemoveFinished(success, message) {
            page.finishOperation(qsTr("Installer"), success, message);
            page.appendLog(qsTr("Installer"), message);
            nvidiaDetector.refresh();
            nvidiaUpdater.checkForUpdate();
            nvidiaInstaller.refreshProprietaryAgreement();
        }
    }

    Connections {
        target: nvidiaUpdater

        function onProgressMessage(message) {
            page.setOperationState(qsTr("Updater"), message, "info", true);
            page.appendLog(qsTr("Updater"), message);
        }

        function onUpdateFinished(success, message) {
            page.finishOperation(qsTr("Updater"), success, message);
            page.appendLog(qsTr("Updater"), message);
            nvidiaDetector.refresh();
            nvidiaUpdater.checkForUpdate();
        }
    }

    Component.onCompleted: {
        nvidiaDetector.refresh();
        nvidiaUpdater.checkForUpdate();
        nvidiaUpdater.refreshAvailableVersions();
        nvidiaInstaller.refreshProprietaryAgreement();
    }
}
