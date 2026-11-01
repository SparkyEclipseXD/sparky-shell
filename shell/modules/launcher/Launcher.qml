import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import "../../theme"
import "../../services"

PanelWindow {
    id: win

    readonly property bool shown: LauncherState.open

    WlrLayershell.namespace: "sparky-launcher"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: shown ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    visible: shown || panel.progress > 0

    BackgroundEffect.blurRegion: panel.opacity >= 1 ? blur : null
    property Region blur: Region { item: blurArea; radius: Theme.launcherRadius * panel.scale }

    Item {
        id: blurArea
        x: panel.x + panel.width * (1 - panel.scale) / 2
        y: panel.y
        width: panel.width * panel.scale
        height: panel.height * panel.scale
    }

    onShownChanged: if (shown) {
        search.reset();
        results.currentIndex = 0;
    }

    IpcHandler {
        target: "launcher"
        function toggle(): void { LauncherState.toggle() }
        function open(): void { LauncherState.open = true }
        function close(): void { LauncherState.close() }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: LauncherState.close()
    }

    Rectangle {
        id: panel

        property real progress: win.shown ? 1 : 0
        Behavior on progress {
            NumberAnimation {
                duration: win.shown ? 260 : 160
                easing.type: win.shown ? Easing.OutQuint : Easing.InCubic
            }
        }

        width: Theme.launcherWidth
        height: content.implicitHeight + 2 * Theme.launcherPadding
        x: (parent.width - width) / 2
        y: Theme.launcherTop - (1 - progress) * 28
        radius: Theme.launcherRadius
        color: Theme.surface
        opacity: Math.min(1, progress * 1.8)
        scale: 0.94 + 0.06 * progress
        transformOrigin: Item.Top

        Behavior on height { NumberAnimation { duration: Theme.animNormal; easing.type: Easing.OutCubic } }

        MouseArea { anchors.fill: parent }

        Column {
            id: content
            anchors { fill: parent; margins: Theme.launcherPadding }
            spacing: results.count > 0 ? 8 : 0

            SearchField {
                id: search
                width: parent.width
                onTextChanged: {
                    results.results = Search.query(text);
                    results.currentIndex = 0;
                }
                onMoveSelection: delta => results.currentIndex =
                    Math.max(0, Math.min(results.count - 1, results.currentIndex + delta))
                onAccepted: results.launchCurrent()
                onDismissed: LauncherState.close()
            }

            ResultList {
                id: results
                width: parent.width
                onLaunched: entry => {
                    entry.execute();
                    LauncherState.close();
                }
            }
        }
    }
}
