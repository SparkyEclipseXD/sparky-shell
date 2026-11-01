pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    readonly property string helper: Quickshell.env("HOME") + "/.local/bin/sparky-hw"
    property var displays: []
    property var mice: []

    function refresh() {
        if (!displayReader.running) displayReader.running = true;
        if (!mouseReader.running) mouseReader.running = true;
    }

    function setMode(output, modeId) {
        modeSetter.command = ["python3", helper, "set-mode", output, modeId];
        modeSetter.running = true;
    }

    property var pendingMouse: ({})
    function setMouse(sys, key, value) {
        pendingMouse = Object.assign({}, pendingMouse, { [sys + "|" + key]: [sys, key, String(value)] });
        mouseFlush.restart();
    }

    Timer {
        id: mouseFlush
        interval: 120
        onTriggered: {
            for (const k in root.pendingMouse) {
                const [sys, key, value] = root.pendingMouse[k];
                Quickshell.execDetached(["python3", root.helper, "set-mouse", sys, key, value]);
            }
            root.pendingMouse = ({});
        }
    }

    Process {
        id: displayReader
        command: ["python3", root.helper, "displays"]
        stdout: StdioCollector {
            onStreamFinished: { try { root.displays = JSON.parse(text) } catch (e) {} }
        }
    }

    Process {
        id: mouseReader
        command: ["python3", root.helper, "mice"]
        stdout: StdioCollector {
            onStreamFinished: { try { root.mice = JSON.parse(text) } catch (e) {} }
        }
    }

    Process {
        id: modeSetter
        onExited: root.refresh()
    }
}
