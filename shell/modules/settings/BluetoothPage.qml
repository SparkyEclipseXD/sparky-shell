import Quickshell
import Quickshell.Bluetooth
import QtQuick
import "../../theme"
import "../common"
import "../../services"

Item {
    id: page

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool on: adapter?.enabled ?? false
    readonly property var all: adapter ? adapter.devices.values : []

    function sorted(list) {
        return list.slice().sort((a, b) => (b.connected - a.connected) || a.name.localeCompare(b.name));
    }
    readonly property var mine: sorted(all.filter(d => d.paired || d.bonded || d.connected))
    readonly property var nearby: sorted(all.filter(d => !d.paired && !d.bonded && !d.connected
                                                        && d.deviceName && !/^([0-9A-F]{2}[-:]){5}/i.test(d.name)
                                                        && !/^[0-9A-F]{12,}$/i.test(d.name)))

    readonly property bool shown: visible && SettingsState.open
    onShownChanged: if (!shown && adapter?.discovering) adapter.discovering = false
    Timer {
        running: page.adapter?.discovering ?? false
        interval: 60000
        onTriggered: page.adapter.discovering = false
    }

    function iconFor(d): string {
        const i = d.icon || "";
        if (i.includes("headset") || i.includes("headphone")) return "headphones";
        if (i.includes("audio")) return "speaker";
        if (i.includes("mouse")) return "mouse";
        if (i.includes("keyboard")) return "keyboard";
        if (i.includes("gaming") || i.includes("joystick")) return "sports_esports";
        if (i.includes("phone")) return "smartphone";
        if (i.includes("computer")) return "computer";
        if (i.includes("watch")) return "watch";
        if (i.includes("tablet")) return "tablet";
        return "bluetooth";
    }

    function status(d): string {
        if (d.pairing) return "Pairing…";
        if (d.state === BluetoothDeviceState.Connecting) return "Connecting…";
        if (d.state === BluetoothDeviceState.Disconnecting) return "Disconnecting…";
        const battery = d.batteryAvailable ? "  ·  " + Math.round(d.battery * 100) + "% battery" : "";
        if (d.connected) return "Connected" + battery;
        return d.paired || d.bonded ? "Not connected" : "Available to pair";
    }

    component Heading: Text {
        topPadding: 10
        color: Theme.fgDim
        font { family: Theme.font; pixelSize: 14; weight: Font.Medium }
    }

    component DeviceRow: Rectangle {
        id: row
        required property var modelData
        readonly property var d: modelData
        readonly property bool busy: d.pairing || d.state === BluetoothDeviceState.Connecting
                                     || d.state === BluetoothDeviceState.Disconnecting
        readonly property bool known: d.paired || d.bonded

        width: list.width
        height: 64
        radius: 14
        color: hover.hovered ? Qt.rgba(1, 1, 1, 0.08) : Theme.card
        Behavior on color { ColorAnimation { duration: Theme.animFast } }

        HoverHandler { id: hover }

        Rectangle {
            id: iconTile
            anchors { left: parent.left; leftMargin: 12; verticalCenter: parent.verticalCenter }
            width: 40; height: 40; radius: 13
            color: row.d.connected ? Theme.fg : Theme.pill
            Behavior on color { ColorAnimation { duration: Theme.animNormal } }

            MaterialIcon {
                anchors.centerIn: parent
                size: 22
                name: page.iconFor(row.d)
                fill: row.d.connected ? 1 : 0
                color: row.d.connected ? "black" : Theme.fg
            }
        }

        Column {
            anchors { left: iconTile.right; leftMargin: 14; right: actions.left; rightMargin: 12; verticalCenter: parent.verticalCenter }
            spacing: 2

            TextInput {
                id: nameField
                width: parent.width
                text: row.d.name
                readOnly: !activeFocus
                clip: true
                color: Theme.fg
                selectionColor: Qt.rgba(1, 1, 1, 0.25)
                font { family: Theme.font; pixelSize: 15 }
                onAccepted: { if (text.trim()) row.d.name = text.trim(); focus = false; }
                onActiveFocusChanged: if (!activeFocus) text = Qt.binding(() => row.d.name)
                Keys.onEscapePressed: focus = false

                MouseArea {
                    anchors.fill: parent
                    enabled: !nameField.activeFocus
                    onDoubleClicked: { nameField.forceActiveFocus(); nameField.selectAll(); }
                }
            }
            Text {
                width: parent.width
                text: page.status(row.d)
                elide: Text.ElideRight
                color: Theme.fgDim
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
                text: !row.known ? "Pair" : row.d.connected ? "Disconnect" : "Connect"
                onClicked: {
                    if (!row.known) {
                        row.d.trusted = true;
                        row.d.pair();
                    } else if (row.d.connected) {
                        row.d.disconnect();
                    } else {
                        row.d.connect();
                    }
                }
            }

            Rectangle {
                visible: row.known
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
                    onClicked: row.d.forget()
                }
            }
        }
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
                text: "Bluetooth"
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
                        text: page.adapter ? "Bluetooth" : "No Bluetooth adapter found"
                        color: Theme.fg
                        font { family: Theme.font; pixelSize: 15 }
                    }
                    Text {
                        visible: page.adapter !== null
                        text: page.on ? "Visible to nearby devices as “" + page.adapter.name + "”" : "Off"
                        color: Theme.fgDim
                        font { family: Theme.font; pixelSize: 12 }
                    }
                }

                Toggle {
                    visible: page.adapter !== null
                    anchors { right: parent.right; rightMargin: 16; verticalCenter: parent.verticalCenter }
                    checked: page.on
                    onToggled: page.adapter.enabled = !page.on
                }
            }

            Column {
                id: list
                width: parent.width
                spacing: 8
                visible: page.on
                opacity: page.on ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: Theme.animNormal } }

                Heading { text: "My devices"; visible: page.mine.length > 0 }

                Repeater { model: page.mine; DeviceRow {} }

                Item {
                    width: parent.width
                    height: 46

                    Heading { anchors.verticalCenter: parent.verticalCenter; topPadding: 0; text: "Nearby" }

                    PillButton {
                        anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                        implicitHeight: 34
                        icon: page.adapter?.discovering ? "" : "bluetooth_searching"
                        text: page.adapter?.discovering ? "Stop searching" : "Search for devices"
                        onClicked: page.adapter.discovering = !page.adapter.discovering
                    }
                }

                Text {
                    visible: page.nearby.length === 0
                    width: parent.width
                    wrapMode: Text.WordWrap
                    text: page.adapter?.discovering
                          ? "Looking for devices… Put the one you want to add in pairing mode."
                          : "Search to find headphones, controllers and other devices near you."
                    color: Theme.fgDim
                    font { family: Theme.font; pixelSize: 13 }
                }

                Repeater { model: page.nearby; DeviceRow {} }
            }
        }
    }
}
