import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import "../../theme"
import "../../services"
import "../common"

PanelWindow {
    id: win

    readonly property bool shown: Power.open
    property int current: 0

    WlrLayershell.namespace: "sparky-power"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: shown ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    visible: shown || progress > 0

    property real progress: shown ? 1 : 0
    Behavior on progress {
        NumberAnimation {
            duration: win.shown ? 320 : 180
            easing.type: win.shown ? Easing.OutQuint : Easing.InCubic
        }
    }

    BackgroundEffect.blurRegion: progress >= 1 ? blur : null
    property Region blur: Region { item: card; radius: card.radius }

    onShownChanged: if (shown) {
        current = 0;
        keys.forceActiveFocus();
    }

    IpcHandler {
        target: "power"
        function toggle(): void { Power.toggle() }
        function open(): void { Power.open = true }
        function close(): void { Power.close() }
    }

    Rectangle {
        anchors.fill: parent
        color: "black"
        opacity: 0.38 * win.progress

        MouseArea { anchors.fill: parent; onClicked: Power.close() }
    }

    Item {
        id: keys
        focus: true
        Keys.onPressed: event => {
            const n = Power.actions.length;
            if (event.key === Qt.Key_Escape) Power.pending ? Power.cancel() : Power.close();
            else if (event.key === Qt.Key_Left || event.key === Qt.Key_Backtab) win.current = (win.current + n - 1) % n;
            else if (event.key === Qt.Key_Right || event.key === Qt.Key_Tab) win.current = (win.current + 1) % n;
            else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space)
                Power.choose(Power.actions[win.current]);
            else if (event.key >= Qt.Key_1 && event.key < Qt.Key_1 + n) {
                win.current = event.key - Qt.Key_1;
                Power.choose(Power.actions[win.current]);
            } else return;
            event.accepted = true;
        }
    }

    Rectangle {
        id: card

        readonly property int tile: 112
        readonly property int pad: 14

        anchors.centerIn: parent
        anchors.verticalCenterOffset: (1 - win.progress) * 24
        width: row.implicitWidth + 2 * pad
        height: tile + 2 * pad
        radius: 30
        color: Theme.surface
        opacity: Math.min(1, win.progress * 1.6)
        scale: 0.92 + 0.08 * win.progress

        Rectangle {
            x: card.pad + win.current * (card.tile + row.spacing)
            y: card.pad
            width: card.tile
            height: card.tile
            radius: 22
            color: Theme.pillHover
            Behavior on x { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
        }

        Row {
            id: row
            x: card.pad
            y: card.pad
            spacing: 8

            Repeater {
                model: Power.actions

                Item {
                    id: tile
                    required property var modelData
                    required property int index
                    readonly property bool counting: Power.pending?.id === modelData.id
                    readonly property real t: Math.max(0, Math.min(1, win.progress * 1.5 - index * 0.1))

                    width: card.tile
                    height: card.tile
                    opacity: t * (Power.pending && !counting ? 0.35 : 1)
                    scale: (0.8 + 0.2 * t) * (area.pressed ? 0.94 : 1)
                    Behavior on opacity { NumberAnimation { duration: Theme.animNormal } }
                    Behavior on scale { NumberAnimation { duration: Theme.animFast; easing.type: Easing.OutCubic } }

                    Rectangle {
                        anchors.fill: parent
                        radius: 22
                        color: "transparent"
                        border { width: 2; color: Theme.fg }
                        visible: tile.counting
                        opacity: 0.25 + 0.75 * (1 - Power.remaining / Power.countdownFrom)
                        Behavior on opacity { NumberAnimation { duration: 900 } }
                    }

                    MaterialIcon {
                        anchors { horizontalCenter: parent.horizontalCenter; top: parent.top; topMargin: 22 }
                        size: 36
                        name: tile.modelData.icon
                        fill: tile.index === win.current || tile.counting ? 1 : 0
                        color: tile.index === win.current ? Theme.fg : Qt.rgba(1, 1, 1, 0.8)
                    }

                    Text {
                        anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: 22 }
                        text: tile.counting ? Power.remaining + "s" : tile.modelData.label
                        color: tile.index === win.current ? Theme.fg : Theme.fgDim
                        font { family: Theme.font; pixelSize: 14; weight: Font.Medium }
                    }

                    MouseArea {
                        id: area
                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered: win.current = tile.index
                        onClicked: Power.choose(tile.modelData)
                    }
                }
            }
        }
    }

    Rectangle {
        anchors { horizontalCenter: parent.horizontalCenter; top: card.bottom; topMargin: 16 }
        width: notice.implicitWidth + 16
        height: 44
        radius: 22
        color: Theme.surface
        opacity: Power.pending ? 1 : 0
        visible: opacity > 0
        scale: Power.pending ? 1 : 0.94
        Behavior on opacity { NumberAnimation { duration: Theme.animNormal } }
        Behavior on scale { NumberAnimation { duration: Theme.animNormal; easing.type: Easing.OutCubic } }

        Row {
            id: notice
            anchors.centerIn: parent
            spacing: 12
            leftPadding: 10

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: (Power.pending?.doing ?? "") + " in " + Power.remaining + "s"
                color: Theme.fg
                font { family: Theme.font; pixelSize: 14 }
            }

            PillButton {
                anchors.verticalCenter: parent.verticalCenter
                implicitHeight: 32
                text: "Cancel"
                onClicked: { Power.cancel(); keys.forceActiveFocus(); }
            }
        }
    }
}
