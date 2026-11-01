pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    readonly property string name: Quickshell.env("USER")
    property string realName: name
    readonly property string initial: (realName || "?")[0].toUpperCase()

    readonly property var candidates: ["/var/lib/AccountsService/icons/" + name, Quickshell.env("HOME") + "/.face"]
    property int found: 0
    property int revision: 0
    readonly property string avatar: "file://" + candidates[found] + "?" + revision

    function edit() { Quickshell.execDetached(["systemsettings", "kcm_users"]) }

    Process {
        running: true
        command: ["getent", "passwd", root.name]
        stdout: StdioCollector {
            onStreamFinished: {
                const gecos = (text.split(":")[4] || "").split(",")[0].trim();
                if (gecos) root.realName = gecos;
            }
        }
    }

    FileView {
        id: watcher
        path: root.candidates[root.found]
        watchChanges: true
        printErrors: false
        onFileChanged: root.revision++
        onLoadFailed: if (root.found + 1 < root.candidates.length) root.found++
    }
}
