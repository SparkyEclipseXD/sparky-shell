import QtQuick
import "../../theme"
import "../../services"

Rectangle {
    id: root

    property string keys: ""
    property bool recording: false
    signal captured(string keys)

    implicitWidth: Math.max(120, label.implicitWidth + 32)
    implicitHeight: 34
    radius: 17
    color: recording ? Qt.rgba(1, 1, 1, 0.2) : (ma.containsMouse ? Theme.pillHover : Theme.pill)
    Behavior on color { ColorAnimation { duration: Theme.animFast } }

    Text {
        id: label
        anchors.centerIn: parent
        text: root.recording ? "Press keys…" : (root.keys === "" ? "Not set" : root.keys.replace(/\+/g, "  +  "))
        color: root.recording || root.keys === "" ? Theme.fgDim : Theme.fg
        font { family: Theme.font; pixelSize: 13 }
    }

    property bool metaTap: false

    function keyName(key): string {
        const named = {};
        named[Qt.Key_Space] = "Space"; named[Qt.Key_Tab] = "Tab"; named[Qt.Key_Backtab] = "Tab";
        named[Qt.Key_Return] = "Return"; named[Qt.Key_Enter] = "Return"; named[Qt.Key_Print] = "Print";
        named[Qt.Key_Insert] = "Insert"; named[Qt.Key_Delete] = "Delete"; named[Qt.Key_Home] = "Home";
        named[Qt.Key_End] = "End"; named[Qt.Key_Left] = "Left"; named[Qt.Key_Right] = "Right";
        named[Qt.Key_Up] = "Up"; named[Qt.Key_Down] = "Down"; named[Qt.Key_PageUp] = "PgUp";
        named[Qt.Key_PageDown] = "PgDown";
        if (named[key]) return named[key];
        if (key >= Qt.Key_F1 && key <= Qt.Key_F35) return "F" + (key - Qt.Key_F1 + 1);
        if ((key >= 0x30 && key <= 0x39) || (key >= 0x41 && key <= 0x5a)) return String.fromCharCode(key);
        return "";
    }

    function isModifier(key): bool {
        return [Qt.Key_Meta, Qt.Key_Super_L, Qt.Key_Super_R, Qt.Key_Control, Qt.Key_Alt, Qt.Key_Shift, Qt.Key_AltGr].includes(key);
    }

    function isMeta(key): bool { return key === Qt.Key_Meta || key === Qt.Key_Super_L || key === Qt.Key_Super_R }

    function finish(value) {
        recording = false;
        if (value !== undefined) captured(value);
    }

    Keys.onPressed: event => {
        event.accepted = true;
        if (event.key === Qt.Key_Escape) return finish();
        if (event.key === Qt.Key_Backspace) return finish("");
        if (isMeta(event.key)) { metaTap = true; return; }
        metaTap = false;
        if (isModifier(event.key)) return;

        const name = keyName(event.key);
        if (name === "") return;
        const mods = [];
        if (event.modifiers & Qt.MetaModifier) mods.push("Meta");
        if (event.modifiers & Qt.ControlModifier) mods.push("Ctrl");
        if (event.modifiers & Qt.AltModifier) mods.push("Alt");
        if (event.modifiers & Qt.ShiftModifier) mods.push("Shift");
        finish([...mods, name].join("+"));
    }

    Keys.onReleased: event => {
        if (recording && isMeta(event.key) && metaTap) finish("Meta");
    }

    onActiveFocusChanged: if (!activeFocus) recording = false
    onRecordingChanged: Binds.pauseShortcuts(recording)
    Component.onDestruction: if (recording) Binds.pauseShortcuts(false)

    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        onClicked: { root.recording = true; root.metaTap = false; root.forceActiveFocus() }
    }
}
