pragma Singleton
import Quickshell
import QtQuick

Singleton {
    id: root

    property bool open: false

    readonly property var actions: [
        { id: "lock", label: "Lock", icon: "lock", delayed: false,
          command: ["loginctl", "lock-session"] },
        { id: "sleep", label: "Sleep", icon: "bedtime", delayed: false,
          command: ["systemctl", "suspend"] },
        { id: "logout", label: "Log out", icon: "logout", delayed: true, doing: "Logging out",
          command: ["qdbus6", "org.kde.Shutdown", "/Shutdown", "org.kde.Shutdown.logout"] },
        { id: "reboot", label: "Restart", icon: "restart_alt", delayed: true, doing: "Restarting",
          command: ["qdbus6", "org.kde.Shutdown", "/Shutdown", "org.kde.Shutdown.logoutAndReboot"] },
        { id: "shutdown", label: "Shut down", icon: "power_settings_new", delayed: true, doing: "Shutting down",
          command: ["qdbus6", "org.kde.Shutdown", "/Shutdown", "org.kde.Shutdown.logoutAndShutdown"] }
    ]

    readonly property int countdownFrom: 5
    property var pending: null
    property int remaining: 0

    function toggle() { open ? close() : (open = true) }

    function close() {
        cancel();
        open = false;
    }

    function choose(action) {
        if (!action.delayed) {
            open = false;
            Qt.callLater(() => Quickshell.execDetached(action.command));
            return;
        }
        if (pending?.id === action.id) { run(); return; }
        pending = action;
        remaining = countdownFrom;
        tick.restart();
    }

    function cancel() {
        tick.stop();
        pending = null;
    }

    function run() {
        tick.stop();
        const action = pending;
        pending = null;
        open = false;
        if (action) Quickshell.execDetached(action.command);
    }

    Timer {
        id: tick
        interval: 1000
        repeat: true
        onTriggered: if (--root.remaining <= 0) root.run()
    }
}
