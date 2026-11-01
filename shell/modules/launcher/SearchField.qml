import Quickshell
import QtQuick
import "../../theme"

Rectangle {
    id: root

    property alias text: input.text
    property string placeholder: "Search apps"
    signal moveSelection(int delta)
    signal removeCurrent()
    signal accepted()
    signal dismissed()

    function reset() { input.text = ""; input.forceActiveFocus() }

    implicitHeight: 46
    radius: 14
    color: Theme.pill

    property var letters: []
    property int nextId: 0

    function sync(text) {
        const old = letters;
        let start = 0;
        while (start < old.length && start < text.length && old[start].ch === text[start]) start++;
        let end = 0;
        while (end < old.length - start && end < text.length - start
               && old[old.length - 1 - end].ch === text[text.length - 1 - end]) end++;
        const fresh = [];
        for (let i = start; i < text.length - end; i++) fresh.push({ id: nextId++, ch: text[i] });
        letters = [...old.slice(0, start), ...fresh, ...old.slice(old.length - end)];
    }

    Text {
        anchors { left: parent.left; leftMargin: 18; verticalCenter: parent.verticalCenter }
        text: root.placeholder
        color: Theme.fgDim
        font { family: Theme.font; pixelSize: 15 }
        opacity: input.text.length === 0 ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Theme.animFast } }
    }

    TextInput {
        id: input
        anchors { fill: parent; leftMargin: 18; rightMargin: 18 }
        verticalAlignment: TextInput.AlignVCenter
        color: "transparent"
        selectedTextColor: "transparent"
        font { family: Theme.font; pixelSize: 15 }
        selectionColor: Qt.rgba(1, 1, 1, 0.25)
        cursorDelegate: Item {}
        clip: true
        onTextChanged: root.sync(text)

        Keys.onPressed: event => {
            const ctrl = event.modifiers & Qt.ControlModifier;
            if (event.key === Qt.Key_Down || (ctrl && event.key === Qt.Key_N)) root.moveSelection(1);
            else if (event.key === Qt.Key_Up || (ctrl && event.key === Qt.Key_P)) root.moveSelection(-1);
            else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) root.accepted();
            else if (event.key === Qt.Key_Escape) root.dismissed();
            else if (event.key === Qt.Key_Delete && (event.modifiers & Qt.ShiftModifier)) root.removeCurrent();
            else return;
            event.accepted = true;
        }

        ListView {
            id: glyphs
            x: input.cursorRectangle.x - caretOffset
            readonly property real caretOffset: {
                let w = 0;
                for (let i = 0; i < input.cursorPosition && i < count; i++) w += itemAtIndex(i)?.width ?? 0;
                return w;
            }
            width: contentWidth + 40
            height: parent.height
            orientation: ListView.Horizontal
            interactive: false
            model: ScriptModel { values: root.letters; objectProp: "id" }

            add: Transition {
                NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 170; easing.type: Easing.OutCubic }
                NumberAnimation { property: "yShift"; from: 7; to: 0; duration: 220; easing.type: Easing.OutCubic }
                NumberAnimation { property: "scale"; from: 0.7; to: 1; duration: 200; easing.type: Easing.OutBack }
            }
            remove: Transition {
                NumberAnimation { property: "opacity"; to: 0; duration: 110; easing.type: Easing.InCubic }
                NumberAnimation { property: "scale"; to: 0.7; duration: 110; easing.type: Easing.InCubic }
            }
            displaced: Transition {
                NumberAnimation { properties: "x"; duration: 140; easing.type: Easing.OutCubic }
                NumberAnimation { properties: "opacity,scale"; to: 1; duration: 140 }
            }

            delegate: Item {
                id: letter
                required property var modelData
                property real yShift: 0
                width: metrics.advanceWidth
                height: glyphs.height

                TextMetrics {
                    id: metrics
                    font: input.font
                    text: letter.modelData.ch
                }

                Text {
                    y: (parent.height - height) / 2 + letter.yShift
                    text: letter.modelData.ch
                    color: Theme.fg
                    font: input.font
                }
            }
        }

        Rectangle {
            id: caret
            width: 2
            height: input.cursorRectangle.height
            radius: 1
            color: Theme.fg
            x: input.cursorRectangle.x
            y: input.cursorRectangle.y
            visible: input.activeFocus

            Behavior on x { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }

            SequentialAnimation on opacity {
                running: input.activeFocus
                loops: Animation.Infinite
                PauseAnimation { duration: 500 }
                NumberAnimation { to: 0; duration: 120 }
                PauseAnimation { duration: 400 }
                NumberAnimation { to: 1; duration: 120 }
            }
        }
    }
}
