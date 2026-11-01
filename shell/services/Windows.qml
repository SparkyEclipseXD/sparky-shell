pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property var list: []

    function activate(id) {
        Quickshell.execDetached(["qdbus6", "org.sparky.Windows", "/", "org.sparky.Windows.Activate", id]);
    }

    function close(id) {
        Quickshell.execDetached(["qdbus6", "org.sparky.Windows", "/", "org.sparky.Windows.Close", id]);
    }

    Process {
        running: true
        command: ["python3", Quickshell.env("HOME") + "/.local/bin/sparky-windows"]
    }

    FileView {
        id: file
        path: Quickshell.env("XDG_RUNTIME_DIR") + "/sparky/windows.json"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            try { root.list = JSON.parse(text()) }
            catch (e) { console.warn("sparky: bad windows.json:", e) }
        }
        onLoadFailed: retry.start()
    }

    Timer { id: retry; interval: 800; onTriggered: file.reload() }

    property var desktops: []
    property string currentDesktop: ""

    function onDesktop(id): var {
        return list.filter(w => !w.desktops || w.desktops.length === 0 || w.desktops.includes(id));
    }

    function switchDesktop(id) { call("SwitchDesktop", id) }
    function addDesktop() { call("AddDesktop", "Desktop " + (desktops.length + 1)) }
    function removeDesktop(id) { call("RemoveDesktop", id) }
    function moveToDesktop(windowId, desktopId) {
        Quickshell.execDetached(["qdbus6", "org.sparky.Windows", "/", "org.sparky.Windows.MoveToDesktop", windowId, desktopId]);
    }
    function renameDesktop(id, name) {
        Quickshell.execDetached(["qdbus6", "org.sparky.Windows", "/", "org.sparky.Windows.RenameDesktop", id, name]);
    }

    function call(method, arg) {
        Quickshell.execDetached(["qdbus6", "org.sparky.Windows", "/", "org.sparky.Windows." + method, arg]);
    }

    FileView {
        id: desktopFile
        path: Quickshell.env("XDG_RUNTIME_DIR") + "/sparky/desktops.json"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            try {
                const d = JSON.parse(text());
                root.desktops = d.desktops;
                root.currentDesktop = d.current;
            } catch (e) { console.warn("sparky: bad desktops.json:", e) }
        }
        onLoadFailed: desktopRetry.start()
    }

    Timer { id: desktopRetry; interval: 800; onTriggered: desktopFile.reload() }
}
