import QtQuick
import "../../services"

TopBarChipFace {
    id: chip

    required property string modelData
    required property Item editor
    property bool dimmed: false
    chipId: modelData
    compact: !dimmed && editor && editor.crowded
    opacity: editor && editor.dragId === chipId ? 0.25 : (dimmed ? 0.6 : 1)
    Behavior on opacity { NumberAnimation { duration: 120 } }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        preventStealing: true
        cursorShape: Qt.OpenHandCursor
        onPressed: mouse => {
            if (!chip.editor) return;
            chip.editor.dragId = chip.chipId;
            chip.editor.dragPos = mapToItem(chip.editor, mouse.x, mouse.y);
        }
        onPositionChanged: mouse => {
            if (!pressed || !chip.editor) return;
            const p = mapToItem(chip.editor, mouse.x, mouse.y);
            chip.editor.dragPos = p;
            chip.editor.hoverZone = chip.editor.zoneAt(p.x, p.y);
            chip.editor.hoverIndex = chip.editor.indexAt(chip.editor.hoverZone, p.x);
        }
        onReleased: {
            const e = chip.editor;
            if (!e) return;
            const id = e.dragId, zone = e.hoverZone, index = e.hoverIndex;
            e.dragId = "";
            e.hoverZone = "";
            e.hoverIndex = -1;
            if (zone !== "") TopBarConfig.place(id, zone, index);
        }
    }
}
