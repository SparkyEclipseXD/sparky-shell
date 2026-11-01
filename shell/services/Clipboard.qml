pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    readonly property string helper: Quickshell.env("HOME") + "/.local/bin/sparky-clipboard"
    readonly property string dir: Quickshell.env("HOME") + "/.local/share/sparky/clipboard"

    property bool open: false
    property var entries: []

    function toggle() { open = !open }
    function close() { open = false }

    function fileUrl(entry): string { return "file://" + dir + "/" + entry.file }

    function copy(entry) { Quickshell.execDetached(["python3", helper, "copy", entry.id]) }
    function remove(entry) { Quickshell.execDetached(["python3", helper, "delete", entry.id]) }
    function clear() { Quickshell.execDetached(["python3", helper, "clear"]) }

    function search(text): var {
        const q = text.trim().toLowerCase();
        if (q === "") return entries;
        if ("images".startsWith(q) || q === "img") return entries.filter(e => e.kind === "image");
        return entries.filter(e => e.kind === "text" && e.text.toLowerCase().includes(q));
    }

    Process {
        running: true
        command: ["sh", "-c", 'pkill -f "^wl-paste --watch python3 $1"; mkdir -p "$2"; ' +
                  'exec wl-paste --watch python3 "$1" store', "sh", root.helper, root.dir]
    }

    FileView {
        id: file
        path: root.dir + "/index.json"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            try { root.entries = JSON.parse(text()) }
            catch (e) { console.warn("sparky: bad clipboard index:", e) }
        }
        onLoadFailed: retry.start()
    }

    Timer { id: retry; interval: 2000; onTriggered: file.reload() }
}
