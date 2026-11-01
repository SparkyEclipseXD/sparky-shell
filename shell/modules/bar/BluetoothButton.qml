import Quickshell
import Quickshell.Bluetooth
import QtQuick
import "../../theme"
import "../../services"
import "../common"

BarButton {
    id: root

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool on: adapter?.enabled ?? false
    readonly property var devices: (adapter ? adapter.devices.values : [])
        .filter(d => d.paired || d.bonded || d.connected).slice()
        .sort((a, b) => (b.connected - a.connected) || a.name.localeCompare(b.name))
    readonly property bool anyConnected: devices.some(d => d.connected)

    function iconFor(d): string {
        const i = d.icon || "";
        if (i.includes("headset") || i.includes("headphone")) return "headphones";
        if (i.includes("audio")) return "speaker";
        if (i.includes("mouse")) return "mouse";
        if (i.includes("keyboard")) return "keyboard";
        if (i.includes("gaming") || i.includes("joystick")) return "sports_esports";
        if (i.includes("phone")) return "smartphone";
        return "bluetooth";
    }

    icon: !adapter || !on ? "bluetooth_disabled" : anyConnected ? "bluetooth_connected" : "bluetooth"
    panelWidth: 300

    Column {
        width: parent.width
        spacing: 6

        Item {
            width: parent.width
            height: 34
            Text {
                anchors { left: parent.left; leftMargin: 6; verticalCenter: parent.verticalCenter }
                text: "Bluetooth"
                color: Theme.fg
                font { family: Theme.font; pixelSize: 15; weight: Font.Medium }
            }
            Toggle {
                anchors { right: parent.right; rightMargin: 4; verticalCenter: parent.verticalCenter }
                visible: root.adapter !== null
                checked: root.on
                onToggled: root.adapter.enabled = !root.on
            }
        }

        Text {
            visible: !root.adapter || !root.on || root.devices.length === 0
            leftPadding: 6
            text: !root.adapter ? "No Bluetooth adapter" : !root.on ? "Bluetooth is off" : "No paired devices yet"
            color: Theme.fgDim
            font { family: Theme.font; pixelSize: 12 }
        }

        Column {
            width: parent.width
            spacing: 2
            visible: root.on
            move: Transition { NumberAnimation { properties: "y"; duration: 300; easing.type: Easing.OutCubic } }

            Repeater {
                model: ScriptModel { values: root.devices.slice(0, 6) }

                QuickRow {
                    required property var modelData
                    readonly property var d: modelData
                    icon: root.iconFor(d)
                    active: d.connected
                    title: /^\(?BLE\)?$|^([0-9A-F]{2}[-:]){5}/i.test(d.name) ? "Bluetooth device" : d.name
                    subtitle: d.state === BluetoothDeviceState.Connecting ? "Connecting…"
                            : d.connected ? "Connected" + (d.batteryAvailable ? "  ·  " + Math.round(d.battery * 100) + "%" : "")
                            : "Not connected"
                    busy: d.state === BluetoothDeviceState.Connecting || d.state === BluetoothDeviceState.Disconnecting
                    action: d.connected ? "Disconnect" : "Connect"
                    onActionClicked: d.connected ? d.disconnect() : d.connect()
                    onClicked: actionClicked()
                }
            }
        }

        PillButton {
            width: parent.width
            implicitHeight: 34
            text: "Bluetooth settings"
            onClicked: { root.open = false; SettingsState.showTab("bluetooth"); }
        }
    }
}
