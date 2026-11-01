pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    readonly property string helper: Quickshell.env("HOME") + "/.local/bin/sparky-icons"
    property var apps: ({})

    function find(entry, ...ids): string {
        const keys = [];
        if (entry) {
            keys.push(entry.id, (entry.id || "").split(".").pop(), entry.icon);
            if (entry.icon && entry.icon.startsWith("/")) return "file://" + entry.icon;
        }
        keys.push(...ids);
        for (const k of keys) {
            const p = k ? apps[String(k).toLowerCase()] : undefined;
            if (p) return "file://" + p;
        }
        const name = entry?.icon || ids.find(i => i) || "";
        return Quickshell.iconPath(name, "application-x-executable");
    }

    function rebuild() { if (!builder.running) builder.running = true }

    Process {
        id: builder
        running: true
        command: ["python3", root.helper]
        onExited: file.reload()
    }

    Connections {
        target: DesktopEntries.applications
        function onValuesChanged() { debounce.restart() }
    }
    Timer { id: debounce; interval: 1500; onTriggered: root.rebuild() }

    FileView {
        id: file
        path: Quickshell.env("HOME") + "/.cache/sparky/icons.json"
        onLoaded: {
            try { root.apps = JSON.parse(text()).apps || {} }
            catch (e) { console.warn("sparky: bad icons.json:", e) }
        }
    }
}
