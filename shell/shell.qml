import Quickshell
import Quickshell.Io
import QtQuick
import "services"
import "modules/bar"
import "modules/launcher"
import "modules/snip"
import "modules/settings"
import "modules/clipboard"
import "modules/notifications"
import "modules/power"
import "modules/workspaces"
import "modules/polkit"
import "modules/screenshare"
import "modules/appchooser"

ShellRoot {
    IpcHandler {
        target: "settings"
        function toggle(): void { SettingsState.toggle() }
        function open(): void { SettingsState.open = true }
        function close(): void { SettingsState.open = false }
    }

    IpcHandler {
        target: "snip"
        function start(): void { SnipState.start() }
        function cancel(): void { SnipState.cancel() }
        function capture(x: int, y: int, w: int, h: int): void { SnipState.capture(x, y, w, h) }
    }

    IpcHandler {
        target: "notifications"
        function test(): void { Notifs.test() }
        function toggleDnd(): void { Notifs.set("dnd", !Notifs.prefs.dnd) }
        function closeAll(): void { Notifs.closeAll() }
    }

    FontLoader { source: Qt.resolvedUrl("assets/fonts/MaterialSymbolsRounded.ttf") }

    Process { id: lockWeather; command: ["python3", Quickshell.env("HOME") + "/.local/bin/sparky-lockinfo", "--refresh"] }
    Timer { interval: 30 * 60 * 1000; repeat: true; running: true; triggeredOnStart: true; onTriggered: lockWeather.running = true }

    Launcher {}
    ClipboardPanel {}
    Settings {}
    NotificationPopups {}
    PowerMenu {}
    WorkspaceSwitcher {}
    PolkitDialog {}
    ScreenSharePicker {}
    AppChooser {}

    Variants {
        model: Quickshell.screens
        Snip { required property var modelData; screen: modelData }
    }

    Variants {
        model: Quickshell.screens
        SnipPreview { required property var modelData; screen: modelData }
    }

    Variants {
        model: Quickshell.screens
        Bar { required property var modelData; screen: modelData }
    }

    Variants {
        model: Quickshell.screens
        TopBar { required property var modelData; screen: modelData }
    }
}
