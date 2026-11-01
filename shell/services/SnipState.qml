pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property bool active: false
    property string frame: ""
    property var pending: null

    property string shot: ""
    property var shotScreen: null
    property int shotSerial: 0

    function showShot(path, screen) {
        shot = path;
        shotScreen = screen;
        shotSerial++;
    }

    function dismissShot() { shot = "" }

    readonly property string framePath: Quickshell.env("XDG_RUNTIME_DIR") + "/sparky/snip-frame.png"

    signal captureRequested(int x, int y, int w, int h)

    function start() {
        if (active || grabber.running) return;
        frame = "";
        grabber.running = true;
    }

    function cancel() { active = false; pending = null }

    function capture(x, y, w, h) {
        pending = { x, y, w, h };
        start();
    }

    Process {
        id: grabber
        command: ["python3", Quickshell.env("HOME") + "/.local/bin/sparky-capture", root.framePath]
        onExited: code => {
            if (code !== 0) {
                Quickshell.execDetached(["notify-send", "-a", "Snip", "Snip failed", "Couldn't capture the screen."]);
                return;
            }
            root.frame = "file://" + root.framePath;
            root.active = true;
            if (root.pending) {
                const r = root.pending;
                root.pending = null;
                root.captureRequested(r.x, r.y, r.w, r.h);
            }
        }
    }
}
