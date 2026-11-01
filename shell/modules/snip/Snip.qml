import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import "../../theme"
import "../../services"

PanelWindow {
    id: win

    readonly property bool shown: SnipState.active
    readonly property string dir: Quickshell.env("HOME") + "/Pictures/Screenshots"

    property real sx: 0
    property real sy: 0
    property real sw: 0
    property real sh: 0
    property bool dragging: false
    property string pendingPath: ""

    WlrLayershell.namespace: "sparky-snip"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: shown ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    visible: shown

    onShownChanged: {
        sw = 0; sh = 0; dragging = false;
        if (shown) keys.forceActiveFocus();
    }

    function snipRegion(x, y, w, h) {
        sx = x; sy = y; sw = w; sh = h;
        grabTimer.restart();
    }

    Process { running: true; command: ["mkdir", "-p", win.dir] }

    Timer {
        id: grabTimer
        interval: 80
        onTriggered: picked.grabToImage(result => {
            win.pendingPath = win.dir + "/snip-" + Qt.formatDateTime(new Date(), "yyyy-MM-dd_HH.mm.ss") + ".png";
            result.saveToFile(win.pendingPath);
            Quickshell.execDetached(["sh", "-c",
                'wl-copy --type image/png < "$1"; notify-send -a Snip -i "$1" "Snip copied" "Saved to $1"',
                "sh", win.pendingPath]);
            SnipState.showShot(win.pendingPath, win.screen);
            SnipState.cancel();
        })
    }

    Connections {
        target: SnipState
        function onCaptureRequested(x, y, w, h) {
            if (win.screen === Quickshell.screens[0]) win.snipRegion(x, y, w, h);
        }
    }

    Image {
        id: frozen
        readonly property real dpr: win.screen?.devicePixelRatio ?? 1
        anchors.fill: parent
        source: SnipState.frame
        sourceClipRect: Qt.rect(win.screen.x * dpr, win.screen.y * dpr, win.width * dpr, win.height * dpr)
        cache: false
        smooth: true
    }

    Rectangle {
        anchors.fill: parent
        color: "black"
        opacity: frozen.status === Image.Ready ? 0.45 : 0
        Behavior on opacity { NumberAnimation { duration: 140 } }
    }

    ShaderEffectSource {
        id: picked
        x: win.sx; y: win.sy
        width: win.sw; height: win.sh
        visible: win.sw > 0 && win.sh > 0
        sourceItem: frozen
        sourceRect: Qt.rect(win.sx, win.sy, win.sw, win.sh)
    }

    Rectangle {
        visible: win.dragging && win.sw > 0
        x: win.sx
        y: Math.min(win.sy + win.sh + 8, win.height - height - 8)
        width: label.implicitWidth + 20
        height: 26
        radius: 13
        color: Theme.surface
        Text {
            id: label
            anchors.centerIn: parent
            text: Math.round(win.sw) + " × " + Math.round(win.sh)
            color: Theme.fg
            font { family: Theme.font; pixelSize: 12 }
        }
    }

    Item {
        id: keys
        focus: true
        Keys.onEscapePressed: SnipState.cancel()
    }

    MouseArea {
        id: drag
        anchors.fill: parent
        cursorShape: Qt.CrossCursor
        property real ox: 0
        property real oy: 0

        onPressed: mouse => {
            ox = mouse.x; oy = mouse.y;
            win.sx = ox; win.sy = oy; win.sw = 0; win.sh = 0;
            win.dragging = true;
        }
        onPositionChanged: mouse => {
            if (!win.dragging) return;
            const x = Math.max(0, Math.min(mouse.x, win.width));
            const y = Math.max(0, Math.min(mouse.y, win.height));
            win.sx = Math.min(ox, x); win.sy = Math.min(oy, y);
            win.sw = Math.abs(x - ox); win.sh = Math.abs(y - oy);
        }
        onReleased: {
            win.dragging = false;
            if (win.sw > 4 && win.sh > 4) grabTimer.restart();
            else { win.sw = 0; win.sh = 0; }
        }
        onCanceled: SnipState.cancel()
    }
}
