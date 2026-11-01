import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import "../../theme"
import "../../services"
import "../common"

PanelWindow {
    id: bar

    readonly property int thickness: Theme.topBarHeight

    WlrLayershell.namespace: "sparky-topbar"
    anchors { top: true; left: true; right: true }
    margins { top: 10; left: Theme.dockMargin; right: Theme.dockMargin }
    implicitHeight: thickness
    exclusiveZone: TopBarConfig.enabled ? thickness : 0
    color: "transparent"
    visible: TopBarConfig.enabled || strip.opacity > 0

    BackgroundEffect.blurRegion: Region { item: strip; radius: strip.radius }

    IpcHandler {
        target: "topbar"
        function toggle(): void { TopBarConfig.setEnabled(!TopBarConfig.enabled) }
        function show(): void { TopBarConfig.setEnabled(true) }
        function hide(): void { TopBarConfig.setEnabled(false) }
    }

    property bool started: false
    Timer { running: true; interval: 200; onTriggered: bar.started = true }
    readonly property bool arrived: started && TopBarConfig.enabled

    SystemClock { id: clock; precision: SystemClock.Minutes }

    Component {
        id: desktopsC

        Grid {
            columns: 100
            spacing: 8
            horizontalItemAlignment: Grid.AlignHCenter
            verticalItemAlignment: Grid.AlignVCenter

            Repeater {
                model: ScriptModel { values: Windows.desktops; objectProp: "id" }

                Rectangle {
                    id: pill
                    required property var modelData
                    readonly property bool current: modelData.id === Windows.currentDesktop
                    readonly property bool busy: Windows.list.some(w => w.desktops && w.desktops.includes(pill.modelData.id))

                    height: 14
                    width: current ? 36 : 14
                    radius: height / 2
                    color: current ? Theme.fg : (area.containsMouse ? Qt.rgba(1, 1, 1, 0.6) : (busy ? Qt.rgba(1, 1, 1, 0.38) : Qt.rgba(1, 1, 1, 0.18)))
                    Behavior on width { NumberAnimation { duration: 260; easing.type: Easing.OutBack; easing.overshoot: 1.2 } }
                    Behavior on height { NumberAnimation { duration: 260; easing.type: Easing.OutBack; easing.overshoot: 1.2 } }
                    Behavior on color { ColorAnimation { duration: 200 } }

                    MouseArea {
                        id: area
                        anchors.fill: parent
                        anchors.margins: -7
                        hoverEnabled: true
                        onClicked: if (!pill.current) Windows.switchDesktop(pill.modelData.id)
                    }
                }
            }

            Rectangle {
                height: 22; width: 22; radius: 11
                color: addArea.containsMouse ? Theme.pillHover : "transparent"
                opacity: addArea.containsMouse || hover.hovered ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: Theme.animFast } }
                Behavior on color { ColorAnimation { duration: Theme.animFast } }
                MaterialIcon { anchors.centerIn: parent; size: 16; name: "add"; color: Theme.fgDim }
                MouseArea { id: addArea; anchors.fill: parent; hoverEnabled: true; onClicked: Windows.addDesktop() }
            }

            HoverHandler { id: hover }
            WheelHandler {
                onWheel: event => {
                    const list = Windows.desktops;
                    const i = list.findIndex(d => d.id === Windows.currentDesktop);
                    const next = i + (event.angleDelta.y < 0 ? 1 : -1);
                    if (i >= 0 && next >= 0 && next < list.length) Windows.switchDesktop(list[next].id);
                }
            }
        }
    }

    Component {
        id: clockC
        Text {
            text: Qt.formatTime(clock.date, "h:mm AP")
            horizontalAlignment: Text.AlignHCenter
            lineHeight: 0.95
            color: Theme.fg
            font { family: Theme.font; pixelSize: 14; weight: Font.Medium }
        }
    }

    Component {
        id: dateC
        Text {
            text: Qt.formatDate(clock.date, "ddd, MMM d")
            horizontalAlignment: Text.AlignHCenter
            color: Theme.fgDim
            font { family: Theme.font; pixelSize: 13 }
        }
    }

    Component {
        id: wifiC
        WifiButton {}
    }

    Component {
        id: bluetoothC
        BluetoothButton {}
    }

    Component {
        id: notificationsC
        NotifButton {}
    }

    function squeeze(ideal, lo, hi): real {
        return lo <= hi ? Math.max(lo, Math.min(hi, ideal)) : (lo + hi) / 2;
    }

    readonly property var components: ({ desktops: desktopsC, clock: clockC, date: dateC, wifi: wifiC, bluetooth: bluetoothC, notifications: notificationsC })

    Rectangle {
        id: strip
        width: parent.width
        height: parent.height
        radius: Theme.dockRadius - 4
        color: Theme.surface
        y: bar.arrived ? 0 : -height - 12
        opacity: bar.arrived ? 1 : 0
        Behavior on y { NumberAnimation { duration: 420; easing.type: Easing.OutQuint } }
        Behavior on opacity { NumberAnimation { duration: 260 } }

        TopBarZone {
            id: startZone
            zone: "left"; components: bar.components
            x: 16
            y: (parent.height - height) / 2
        }
        TopBarZone {
            zone: "center"; components: bar.components
            readonly property real gap: 14
            x: bar.squeeze((parent.width - width) / 2, startZone.width ? startZone.x + startZone.width + gap : 0,
                           endZone.width ? endZone.x - gap - width : parent.width - width)
            y: (parent.height - height) / 2
        }
        TopBarZone {
            id: endZone
            zone: "right"; components: bar.components
            x: parent.width - width - 16
            y: (parent.height - height) / 2
        }
    }
}
