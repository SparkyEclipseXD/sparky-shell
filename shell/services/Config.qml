pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    readonly property var defaults: ["zen", "kitty", "org.gnome.Nautilus", "discord", "spotify", "steam"]

    property var pinned: defaults

    function isPinned(id): bool {
        return pinned.some(p => p.toLowerCase() === (id || "").toLowerCase());
    }

    function pin(id) {
        if (id && !isPinned(id))
            save([...pinned, id]);
    }

    function unpin(id) {
        const key = (id || "").toLowerCase();
        save(pinned.filter(p => p.toLowerCase() !== key));
    }

    function movePinned(id, to) {
        const key = (id || "").toLowerCase();
        const from = pinned.findIndex(p => p.toLowerCase() === key);
        if (from < 0) return;
        const list = pinned.slice();
        list.splice(Math.max(0, Math.min(list.length - 1, to)), 0, list.splice(from, 1)[0]);
        pinned = list;
    }

    function save(list) {
        pinned = list;
        file.setText(JSON.stringify(list, null, 2) + "\n");
    }

    FileView {
        id: file
        path: Quickshell.env("HOME") + "/.config/sparky/pinned.json"
        watchChanges: true
        atomicWrites: true

        onFileChanged: reload()
        onLoaded: {
            try {
                const list = JSON.parse(text());
                if (Array.isArray(list)) root.pinned = list;
            } catch (e) {
                console.warn("sparky: bad pinned.json:", e);
            }
        }
        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound)
                root.save(root.defaults);
        }
    }
}
