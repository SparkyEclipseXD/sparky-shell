import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import "../../theme"
import "../../services"

PanelWindow {
    id: bar

    readonly property bool covered: Windows.list.some(w =>
        w.active && !w.minimized && (w.maximized || w.fullscreen) && w.output === bar.screen?.name)
    property bool peeking: false
    property bool arrived: false
    readonly property bool hidden: covered && !peeking && DockState.holds === 0

    WlrLayershell.namespace: "sparky-bar"
    anchors.bottom: true
    implicitWidth: 1100
    implicitHeight: Theme.dockHeight + Theme.dockMargin
    exclusiveZone: covered ? 0 : Theme.dockHeight + Theme.dockMargin
    color: "transparent"

    mask: Region { item: bar.hidden ? edge : dock }

    BackgroundEffect.blurRegion: dock.y === 0 ? blur : null
    property Region blur: Region { item: dock; radius: Theme.dockRadius }

    Item {
        id: edge
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
        height: 2
    }

    HoverHandler {
        id: hover
        onHoveredChanged: hovered ? (leave.stop(), reveal.restart()) : (reveal.stop(), leave.restart())
    }
    Timer { id: reveal; interval: 120; onTriggered: bar.peeking = true }
    Timer { id: leave; interval: 450; onTriggered: bar.peeking = false }

    onCoveredChanged: if (!covered) peeking = false

    Process {
        id: splashCheck
        command: ["pgrep", "-x", "ksplashqml"]
        onExited: code => {
            if (code !== 0 || ++bar.waited > 50) arrive.start();
            else recheck.start();
        }
    }
    property int waited: 0
    Timer { id: recheck; interval: 300; onTriggered: splashCheck.running = true }
    Timer { id: arrive; interval: 250; onTriggered: bar.arrived = true }
    Component.onCompleted: splashCheck.running = true

    Rectangle {
        id: dock
        x: (parent.width - width) / 2
        y: bar.hidden || !bar.arrived ? bar.height : 0
        width: row.implicitWidth + 2 * Theme.dockPadding
        height: Theme.dockHeight
        radius: Theme.dockRadius
        color: Theme.surface
        opacity: bar.hidden || !bar.arrived ? 0 : 1

        Behavior on y {
            NumberAnimation {
                duration: bar.hidden ? 220 : 300
                easing.type: bar.hidden ? Easing.InCubic : Easing.OutQuint
            }
        }
        Behavior on opacity { NumberAnimation { duration: bar.hidden ? 200 : 160 } }

        Row {
            id: row
            anchors.centerIn: parent
            spacing: 0

            StartButton {}

            Divider { open: true }

            Taskbar { source: Apps.pinnedItems; indicators: false; reorderable: true }

            Divider { open: openApps.count > 0 }

            Taskbar { id: openApps; source: Apps.openItems }

            Divider { open: tray.count > 0 }

            Tray { id: tray }
        }
    }
}
