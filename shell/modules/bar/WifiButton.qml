import Quickshell
import Quickshell.Networking
import QtQuick
import "../../theme"
import "../../services"
import "../common"

BarButton {
    id: root

    readonly property var wifi: Networking.devices.values.find(d => d.type === DeviceType.Wifi) ?? null
    readonly property bool on: Networking.wifiEnabled
    readonly property var networks: (wifi ? wifi.networks.values : []).filter(n => n.name).slice()
        .sort((a, b) => (b.connected - a.connected) || (b.known - a.known) || (b.signalStrength - a.signalStrength))
    readonly property var current: networks.find(n => n.connected) ?? null

    function bars(s): string {
        return s > 0.75 ? "signal_wifi_4_bar" : s > 0.5 ? "network_wifi_3_bar" : s > 0.25 ? "network_wifi_2_bar" : "network_wifi_1_bar";
    }
    function secured(n): bool { return n.security !== WifiSecurityType.Open && n.security !== WifiSecurityType.Owe }

    icon: !wifi || !on ? "signal_wifi_off" : current ? bars(current.signalStrength) : "signal_wifi_0_bar"
    panelWidth: 300

    onOpenChanged: if (wifi) wifi.scannerEnabled = open

    Column {
        width: parent.width
        spacing: 6

        Item {
            width: parent.width
            height: 34
            Text {
                anchors { left: parent.left; leftMargin: 6; verticalCenter: parent.verticalCenter }
                text: "Wi-Fi"
                color: Theme.fg
                font { family: Theme.font; pixelSize: 15; weight: Font.Medium }
            }
            Toggle {
                anchors { right: parent.right; rightMargin: 4; verticalCenter: parent.verticalCenter }
                visible: root.wifi !== null
                checked: root.on
                onToggled: Networking.wifiEnabled = !root.on
            }
        }

        Text {
            visible: !root.wifi || !root.on || root.networks.length === 0
            leftPadding: 6
            text: !root.wifi ? "No Wi-Fi adapter" : !root.on ? "Wi-Fi is off" : "Looking for networks…"
            color: Theme.fgDim
            font { family: Theme.font; pixelSize: 12 }
        }

        Column {
            width: parent.width
            spacing: 2
            visible: root.on
            move: Transition { NumberAnimation { properties: "y"; duration: 300; easing.type: Easing.OutCubic } }

            Repeater {
                model: ScriptModel { values: root.networks.slice(0, 6) }

                QuickRow {
                    required property var modelData
                    readonly property var n: modelData
                    icon: root.bars(n.signalStrength)
                    active: n.connected
                    title: n.name
                    subtitle: n.state === ConnectionState.Connecting ? "Connecting…" : n.connected ? "Connected"
                            : n.known ? "Saved" : (root.secured(n) ? "Secured" : "Open")
                    busy: n.stateChanging
                    action: n.connected ? "Disconnect" : "Connect"
                    onActionClicked: {
                        if (n.connected) n.disconnect();
                        else if (!n.known && root.secured(n)) { root.open = false; SettingsState.showTab("wifi"); }
                        else n.connect();
                    }
                    onClicked: actionClicked()
                }
            }
        }

        PillButton {
            width: parent.width
            implicitHeight: 34
            text: "Wi-Fi settings"
            onClicked: { root.open = false; SettingsState.showTab("wifi"); }
        }
    }
}
