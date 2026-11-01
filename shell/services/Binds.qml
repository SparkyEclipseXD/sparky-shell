pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    readonly property string home: Quickshell.env("HOME")

    readonly property var defaults: [
        { id: "launcher", label: "Open launcher", keys: "Meta", command: "qs -c sparky ipc call launcher toggle" },
        { id: "snip", label: "Screen snip", keys: "Meta+Shift+S", command: "qs -c sparky ipc call snip start" },
        { id: "settings", label: "Open settings", keys: "Meta+I", command: "qs -c sparky ipc call settings toggle" },
        { id: "clipboard", label: "Clipboard history", keys: "Meta+V", command: "qs -c sparky ipc call clipboard toggle" },
        { id: "workspaces", label: "Switch desktops", keys: "Meta+Tab", command: "qs -c sparky ipc call workspaces next" },
        { id: "workspaces-reverse", label: "Switch desktops (backwards)", keys: "Meta+Shift+Tab", command: "qs -c sparky ipc call workspaces prev" },
        { id: "power", label: "Power menu", keys: "Ctrl+Alt+Delete", command: "qs -c sparky ipc call power toggle" },
        { id: "alttab", label: "Switch windows", keys: "Alt+Tab", kwin: "Walk Through Windows" },
        { id: "alttab-reverse", label: "Switch windows (backwards)", keys: "Alt+Shift+Tab", kwin: "Walk Through Windows (Reverse)" },
        { id: "fullscreen", label: "Toggle fullscreen", keys: "Ctrl+B", kwin: "Window Fullscreen" }
    ]

    property var binds: defaults

    function isCustom(bind): bool { return bind.id.startsWith("custom-") }
    function isKwin(bind): bool { return !!bind.kwin }

    function pauseShortcuts(paused) {
        Quickshell.execDetached(["qdbus6", "org.kde.kglobalaccel", "/kglobalaccel",
                                 "org.kde.KGlobalAccel.blockGlobalShortcuts", paused ? "true" : "false"]);
    }

    function update(id, patch) {
        save(binds.map(b => b.id === id ? Object.assign({}, b, patch) : b));
    }

    function addCustom() {
        save([...binds, { id: "custom-" + Date.now(), label: "Custom bind", keys: "", command: "" }]);
    }

    function remove(id) { save(binds.filter(b => b.id !== id)) }

    function reset() { save(defaults) }

    function save(list) {
        binds = list;
        file.setText(JSON.stringify({ binds: list }, null, 2) + "\n");
    }

    Process {
        running: true
        command: ["python3", root.home + "/.local/bin/sparky-keys"]
    }

    FileView {
        id: file
        path: root.home + "/.config/sparky/binds.json"
        atomicWrites: true
        onLoaded: {
            try {
                const d = JSON.parse(text());
                if (!Array.isArray(d.binds)) return;
                const missing = root.defaults.filter(b => !d.binds.some(x => x.id === b.id));
                if (missing.length > 0) root.save([...d.binds, ...missing]);
                else root.binds = d.binds;
            } catch (e) { console.warn("sparky: bad binds.json:", e) }
        }
        onLoadFailed: root.save(root.defaults)
    }
}
