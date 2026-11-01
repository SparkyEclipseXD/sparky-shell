import Quickshell
import Quickshell.Networking
import QtQuick
import "../../theme"
import "../../services"
import "../common"

Item {
    id: page

    readonly property var wifi: Networking.devices.values.find(d => d.type === DeviceType.Wifi) ?? null
    readonly property bool on: Networking.wifiEnabled
    readonly property var all: wifi ? wifi.networks.values : []

    readonly property var networks: all.filter(n => n.name).slice().sort((a, b) =>
        (b.connected - a.connected) || (b.known - a.known) || (b.signalStrength - a.signalStrength))
    readonly property var current: networks.find(n => n.connected) ?? null

    property var asking: null

    readonly property bool shown: visible && SettingsState.open
    onShownChanged: if (wifi) wifi.scannerEnabled = shown
    Component.onCompleted: if (wifi && shown) wifi.scannerEnabled = true

    function secured(n): bool { return n.security !== WifiSecurityType.Open && n.security !== WifiSecurityType.Owe }

    function bars(n): string {
        const s = n.signalStrength;
        return s > 0.75 ? "signal_wifi_4_bar" : s > 0.5 ? "network_wifi_3_bar"
             : s > 0.25 ? "network_wifi_2_bar" : "network_wifi_1_bar";
    }

    function status(n): string {
        if (n.state === ConnectionState.Connecting) return "Connecting…";
        if (n.state === ConnectionState.Disconnecting) return "Disconnecting…";
        if (n.connected) return "Connected" + (Networking.connectivity === NetworkConnectivity.Full ? ""
                                : Networking.connectivity === NetworkConnectivity.Portal ? "  ·  Sign-in needed"
                                : Networking.connectivity === NetworkConnectivity.Limited ? "  ·  No internet" : "");
        const lock = secured(n) ? "Secured" : "Open";
        return n.known ? "Saved  ·  " + lock : lock;
    }

    function choose(n) {
        if (n.connected) { n.disconnect(); return; }
        if (!n.known && secured(n)) { asking = asking === n ? null : n; return; }
        asking = null;
        n.connect();
    }

    component Heading: Text {
        topPadding: 10
        color: Theme.fgDim
        font { family: Theme.font; pixelSize: 14; weight: Font.Medium }
    }

    component NetworkRow: Rectangle {
        id: row
        required property var modelData
        readonly property var n: modelData
        readonly property bool busy: n.stateChanging
        readonly property bool open: page.asking === n
        property string failure: ""

        width: list.width
        height: 64 + (open ? 60 : 0)
        clip: true
        radius: 14
        color: hover.hovered && !open ? Qt.rgba(1, 1, 1, 0.08) : Theme.card
        Behavior on color { ColorAnimation { duration: Theme.animFast } }
        Behavior on height { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

        HoverHandler { id: hover }

        Connections {
            target: row.n
            function onConnectionFailed(reason) {
                row.failure = reason === ConnectionFailReason.NoSecrets ? "Wrong password" : "Couldn't connect";
                if (page.secured(row.n)) page.asking = row.n;
                shake.restart();
            }
            function onConnectedChanged() {
                if (row.n.connected) { row.failure = ""; if (page.asking === row.n) page.asking = null; }
            }
        }

        Item {
            width: parent.width
            height: 64

            MouseArea {
                anchors.fill: parent
                onClicked: page.choose(row.n)
            }

            Rectangle {
                id: iconTile
                anchors { left: parent.left; leftMargin: 12; verticalCenter: parent.verticalCenter }
                width: 40; height: 40; radius: 13
                color: row.n.connected ? Theme.fg : Theme.pill
                Behavior on color { ColorAnimation { duration: 320; easing.type: Easing.OutCubic } }

                SequentialAnimation {
                    id: pop
                    NumberAnimation { target: iconTile; property: "scale"; to: 1.12; duration: 140; easing.type: Easing.OutCubic }
                    NumberAnimation { target: iconTile; property: "scale"; to: 1; duration: 260; easing.type: Easing.OutBack }
                }
                Connections { target: row.n; function onConnectedChanged() { if (row.n.connected) pop.restart() } }

                MaterialIcon {
                    anchors.centerIn: parent
                    size: 22
                    name: page.bars(row.n)
                    fill: 1
                    color: row.n.connected ? "black" : Theme.fg
                }

                Rectangle {
                    visible: page.secured(row.n)
                    anchors { right: parent.right; bottom: parent.bottom; margins: -3 }
                    width: 17; height: 17; radius: 8.5
                    color: row.n.connected ? Theme.fg : "#2a2a2e"
                    MaterialIcon {
                        anchors.centerIn: parent
                        size: 11
                        name: "lock"
                        fill: 1
                        color: row.n.connected ? "black" : Theme.fgDim
                    }
                }
            }

            Column {
                anchors { left: iconTile.right; leftMargin: 14; right: actions.left; rightMargin: 12; verticalCenter: parent.verticalCenter }
                spacing: 2

                Text {
                    width: parent.width
                    text: row.n.name
                    elide: Text.ElideRight
                    color: Theme.fg
                    font { family: Theme.font; pixelSize: 15 }
                }
                FadeText {
                    width: parent.width
                    shown: row.failure !== "" && !row.n.connected ? row.failure : page.status(row.n)
                    elide: Text.ElideRight
                    color: row.failure !== "" && !row.n.connected ? Qt.rgba(1, 0.75, 0.75, 1) : Theme.fgDim
                    font { family: Theme.font; pixelSize: 12 }
                }
            }

            Row {
                id: actions
                anchors { right: parent.right; rightMargin: 12; verticalCenter: parent.verticalCenter }
                spacing: 6

                Item {
                    visible: row.busy
                    anchors.verticalCenter: parent.verticalCenter
                    width: 34; height: 34
                    Rectangle { anchors.centerIn: parent; width: 18; height: 18; radius: 9; color: "transparent"; border { width: 2; color: Qt.rgba(1, 1, 1, 0.18) } }
                    Rectangle { x: 14; y: 6; width: 6; height: 6; radius: 3; color: Theme.fg }
                    RotationAnimation on rotation { running: row.busy; from: 0; to: 360; duration: 800; loops: Animation.Infinite }
                }

                PillButton {
                    visible: !row.busy
                    anchors.verticalCenter: parent.verticalCenter
                    implicitHeight: 34
                    text: row.n.connected ? "Disconnect" : "Connect"
                    onClicked: page.choose(row.n)
                }

                Rectangle {
                    visible: row.n.known
                    anchors.verticalCenter: parent.verticalCenter
                    width: 34; height: 34; radius: 17
                    opacity: hover.hovered ? 1 : 0
                    color: forgetArea.containsMouse ? Qt.rgba(0.85, 0.2, 0.2, 0.9) : "transparent"
                    Behavior on opacity { NumberAnimation { duration: Theme.animFast } }
                    Behavior on color { ColorAnimation { duration: Theme.animFast } }

                    MaterialIcon { anchors.centerIn: parent; size: 18; name: "delete"; color: forgetArea.containsMouse ? "white" : Theme.fgDim }

                    MouseArea {
                        id: forgetArea
                        anchors.fill: parent
                        hoverEnabled: true
                        enabled: hover.hovered
                        onClicked: row.n.forget()
                    }
                }
            }
        }

        Rectangle {
            id: pill
            y: 64
            x: 66
            width: parent.width - 66 - 12
            height: 44
            radius: 22
            color: field.activeFocus ? Theme.pillHover : Theme.pill
            opacity: row.open ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 180 } }

            transform: Translate { id: shakeT }
            SequentialAnimation {
                id: shake
                NumberAnimation { target: shakeT; property: "x"; to: -10; duration: 50 }
                NumberAnimation { target: shakeT; property: "x"; to: 8; duration: 70 }
                NumberAnimation { target: shakeT; property: "x"; to: -4; duration: 60 }
                NumberAnimation { target: shakeT; property: "x"; to: 0; duration: 60 }
            }

            MaterialIcon {
                id: keyIcon
                anchors { left: parent.left; leftMargin: 16; verticalCenter: parent.verticalCenter }
                size: 18
                name: "key"
                color: Theme.fgDim
            }

            TextInput {
                id: field
                anchors { left: keyIcon.right; leftMargin: 10; right: eye.left; rightMargin: 8; verticalCenter: parent.verticalCenter }
                echoMode: eye.reveal ? TextInput.Normal : TextInput.Password
                passwordCharacter: "●"
                passwordMaskDelay: 0
                color: Theme.fg
                selectionColor: Qt.rgba(1, 1, 1, 0.25)
                font { family: Theme.font; pixelSize: 14; letterSpacing: echoMode === TextInput.Password ? 2 : 0 }
                clip: true
                onAccepted: if (text.length >= 8 || page.secured(row.n) === false) {
                    row.failure = "";
                    row.n.connectWithPsk(text);
                    text = "";
                }
                Keys.onEscapePressed: page.asking = null

                Text {
                    visible: field.text === ""
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Password for " + row.n.name
                    color: Qt.rgba(1, 1, 1, 0.45)
                    font { family: Theme.font; pixelSize: 14 }
                }
            }

            Rectangle {
                id: eye
                property bool reveal: false
                anchors { right: join.left; rightMargin: 4; verticalCenter: parent.verticalCenter }
                width: 32; height: 32; radius: 16
                color: eyeArea.containsMouse ? Theme.pillHover : "transparent"
                MaterialIcon { anchors.centerIn: parent; size: 18; name: eye.reveal ? "visibility_off" : "visibility"; color: Theme.fgDim }
                MouseArea { id: eyeArea; anchors.fill: parent; hoverEnabled: true; onClicked: eye.reveal = !eye.reveal }
            }

            Rectangle {
                id: join
                readonly property bool ready: field.text.length >= 8
                anchors { right: parent.right; rightMargin: 6; verticalCenter: parent.verticalCenter }
                width: joinLabel.implicitWidth + 28
                height: 32
                radius: 16
                color: ready ? Theme.fg : Theme.pill
                Behavior on color { ColorAnimation { duration: Theme.animNormal } }
                Text {
                    id: joinLabel
                    anchors.centerIn: parent
                    text: "Join"
                    color: parent.ready ? "black" : Theme.fgDim
                    font { family: Theme.font; pixelSize: 13; weight: Font.Medium }
                }
                MouseArea { anchors.fill: parent; onClicked: field.accepted() }
            }
        }

        onOpenChanged: if (open) field.forceActiveFocus()
    }

    Flickable {
        anchors.fill: parent
        contentHeight: column.implicitHeight + 32
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        Column {
            id: column
            x: 28; y: 4
            width: page.width - 56
            spacing: 10

            Text {
                bottomPadding: 6
                text: "Wi-Fi"
                color: Theme.fg
                font { family: Theme.font; pixelSize: 22; weight: Font.Medium }
            }

            Rectangle {
                width: parent.width
                height: 64
                radius: 14
                color: Theme.card

                Column {
                    anchors { left: parent.left; leftMargin: 18; verticalCenter: parent.verticalCenter }
                    spacing: 2
                    Text {
                        text: page.wifi ? "Wi-Fi" : "No Wi-Fi adapter found"
                        color: Theme.fg
                        font { family: Theme.font; pixelSize: 15 }
                    }
                    FadeText {
                        visible: page.wifi !== null
                        shown: !Networking.wifiHardwareEnabled ? "Turned off by the hardware switch"
                            : !page.on ? "Off"
                            : page.current ? "Connected to “" + page.current.name + "”" : "Not connected"
                        color: Theme.fgDim
                        font { family: Theme.font; pixelSize: 12 }
                    }
                }

                Toggle {
                    visible: page.wifi !== null
                    anchors { right: parent.right; rightMargin: 16; verticalCenter: parent.verticalCenter }
                    checked: page.on
                    onToggled: Networking.wifiEnabled = !page.on
                }
            }

            Column {
                id: list
                width: parent.width
                spacing: 8
                visible: page.on && page.wifi !== null
                opacity: visible ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: Theme.animNormal } }

                Heading { text: "Networks" }

                Text {
                    visible: page.networks.length === 0
                    text: "Looking for networks…"
                    color: Theme.fgDim
                    font { family: Theme.font; pixelSize: 13 }
                }

                move: Transition { NumberAnimation { properties: "y"; duration: 380; easing.type: Easing.OutCubic } }
                add: Transition {
                    NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 220 }
                    NumberAnimation { property: "scale"; from: 0.96; to: 1; duration: 260; easing.type: Easing.OutCubic }
                }

                Repeater {
                    model: ScriptModel { values: page.networks }
                    NetworkRow {}
                }
            }
        }
    }
}
