import Quickshell
import QtQuick
import "../../theme"
import "../../services"
import "../common"

Item {
    id: editorRoot

    implicitHeight: 176

    property string dragId: ""
    property point dragPos
    property string hoverZone: ""
    property int hoverIndex: -1

    FontMetrics { id: fm; font { family: Theme.font; pixelSize: 13; weight: Font.Medium } }
    readonly property bool crowded: {
        let need = 24 + 2 * 14;
        for (const z of ["left", "center", "right"]) {
            const ids = TopBarConfig.layout[z] ?? [];
            for (const id of ids) need += fm.advanceWidth(TopBarConfig.items[id]?.label ?? id) + 16 + 6 + 22 + 8;
        }
        return need > bar.width;
    }

    function squeeze(ideal, lo, hi): real {
        return lo <= hi ? Math.max(lo, Math.min(hi, ideal)) : (lo + hi) / 2;
    }

    readonly property var zoneNames: ({ left: "Left", center: "Centre", right: "Right" })

    function rowFor(zone): Item {
        return zone === "left" ? left : zone === "center" ? center : zone === "right" ? right : shelfRow;
    }

    function zoneAt(x, y): string {
        if (y > bar.y + bar.height + 10) return "hidden";
        const rel = x - bar.x, third = bar.width / 3;
        return rel < third ? "left" : rel < 2 * third ? "center" : "right";
    }

    function indexAt(zone, x): int {
        let i = 0;
        for (const c of rowFor(zone).children) {
            if (!c.chipId || c.chipId === dragId) continue;
            if (x > c.mapToItem(editorRoot, c.width / 2, 0).x) i++;
        }
        return i;
    }

    Rectangle {
        anchors.fill: parent
        radius: 16
        color: Qt.rgba(1, 1, 1, 0.04)
    }

    Rectangle {
        id: bar
        x: 14; y: 14
        width: parent.width - 28
        height: 52
        radius: 14
        color: Qt.rgba(0.02, 0.02, 0.03, 0.9)

        Repeater {
            model: ["left", "center", "right"]
            Rectangle {
                required property string modelData
                required property int index
                x: index * bar.width / 3 + 4
                y: 4
                width: bar.width / 3 - 8
                height: bar.height - 8
                radius: 10
                color: editorRoot.hoverZone === modelData ? Qt.rgba(1, 1, 1, 0.1) : "transparent"
                border { width: editorRoot.dragId ? 1 : 0; color: Qt.rgba(1, 1, 1, editorRoot.hoverZone === modelData ? 0.35 : 0.1) }
                Behavior on color { ColorAnimation { duration: 140 } }
                Text {
                    anchors.centerIn: parent
                    visible: editorRoot.dragId !== "" && (TopBarConfig.layout[parent.modelData] ?? []).filter(x => x !== editorRoot.dragId).length === 0
                    text: editorRoot.zoneNames[parent.modelData]
                    color: Qt.rgba(1, 1, 1, 0.3)
                    font { family: Theme.font; pixelSize: 12 }
                }
            }
        }

        Row {
            id: left
            anchors { left: parent.left; leftMargin: 12; verticalCenter: parent.verticalCenter }
            spacing: 8
            move: Transition { NumberAnimation { properties: "x"; duration: 260; easing.type: Easing.OutCubic } }
            add: Transition { NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 200 } }
            Repeater {
                model: ScriptModel { values: TopBarConfig.layout.left }
                TopBarChip { editor: editorRoot }
            }
        }
        Row {
            id: center
            anchors.verticalCenter: parent.verticalCenter
            x: editorRoot.squeeze((bar.width - width) / 2,
                                  left.width ? left.x + left.width + 14 : 12,
                                  right.width ? right.x - 14 - width : bar.width - 12 - width)
            Behavior on x { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
            spacing: 8
            move: Transition { NumberAnimation { properties: "x"; duration: 260; easing.type: Easing.OutCubic } }
            add: Transition { NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 200 } }
            Repeater {
                model: ScriptModel { values: TopBarConfig.layout.center }
                TopBarChip { editor: editorRoot }
            }
        }
        Row {
            id: right
            anchors { right: parent.right; rightMargin: 12; verticalCenter: parent.verticalCenter }
            spacing: 8
            move: Transition { NumberAnimation { properties: "x"; duration: 260; easing.type: Easing.OutCubic } }
            add: Transition { NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 200 } }
            Repeater {
                model: ScriptModel { values: TopBarConfig.layout.right }
                TopBarChip { editor: editorRoot }
            }
        }
    }

    Rectangle {
        id: shelf
        x: 14
        y: bar.y + bar.height + 12
        width: parent.width - 28
        height: parent.height - y - 14
        radius: 14
        color: editorRoot.hoverZone === "hidden" ? Qt.rgba(1, 1, 1, 0.08) : "transparent"
        border { width: 1; color: Qt.rgba(1, 1, 1, editorRoot.hoverZone === "hidden" ? 0.35 : (editorRoot.dragId ? 0.14 : 0.06)) }
        Behavior on color { ColorAnimation { duration: 140 } }

        Text {
            anchors.centerIn: parent
            visible: (TopBarConfig.layout.hidden ?? []).filter(x => x !== editorRoot.dragId).length === 0
            text: editorRoot.dragId ? "Drop here to take it off the bar" : "Drag pieces here to hide them · drag them back up to show them"
            color: Theme.fgDim
            font { family: Theme.font; pixelSize: 12 }
        }

        Row {
            id: shelfRow
            anchors.centerIn: parent
            spacing: 8
            move: Transition { NumberAnimation { properties: "x"; duration: 260; easing.type: Easing.OutCubic } }
            add: Transition { NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 200 } }
            Repeater {
                model: ScriptModel { values: TopBarConfig.layout.hidden ?? [] }
                TopBarChip { editor: editorRoot; dimmed: true }
            }
        }
    }

    Rectangle {
        id: marker
        readonly property var spot: {
            if (editorRoot.dragId === "" || editorRoot.hoverZone === "") return null;
            const row = editorRoot.rowFor(editorRoot.hoverZone);
            const others = [];
            for (const c of row.children) if (c.chipId && c.chipId !== editorRoot.dragId) others.push(c);
            if (others.length === 0) return row.mapToItem(editorRoot, row.width / 2, row.height / 2);
            const i = Math.max(0, Math.min(editorRoot.hoverIndex, others.length));
            const c = i < others.length ? others[i] : others[others.length - 1];
            return c.mapToItem(editorRoot, i < others.length ? -5 : c.width + 4, c.height / 2);
        }
        visible: spot !== null
        width: 3
        height: 26
        radius: 1.5
        color: Theme.fg
        x: spot ? spot.x - 1 : 0
        y: spot ? spot.y - height / 2 : 0
        Behavior on x { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
    }

    TopBarChipFace {
        visible: editorRoot.dragId !== ""
        chipId: editorRoot.dragId
        x: editorRoot.dragPos.x - width / 2
        y: editorRoot.dragPos.y - height / 2
        scale: 1.08
        z: 10
        lifted: true
        compact: editorRoot.crowded && editorRoot.hoverZone !== "hidden"
    }
}
