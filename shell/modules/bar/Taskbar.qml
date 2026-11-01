import Quickshell
import Quickshell.Widgets
import QtQuick
import "../../theme"
import "../../services"
import "../common"

ListView {
    id: list

    property var source: []
    property bool indicators: true
    property bool reorderable: false
    property bool dragging: false

    readonly property int count: model.values.length
    readonly property real targetWidth: count * Theme.slotWidth + Math.max(0, count - 1) * Theme.slotSpacing
    property real animatedWidth: targetWidth
    Behavior on animatedWidth { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

    implicitWidth: animatedWidth
    implicitHeight: Theme.slotHeight
    orientation: ListView.Horizontal
    spacing: Theme.slotSpacing
    interactive: false
    clip: false

    model: ScriptModel {
        values: list.source
        objectProp: "id"
    }

    add: Transition {
        ParallelAnimation {
            NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 220; easing.type: Easing.OutCubic }
            NumberAnimation { property: "scale"; from: 0.5; to: 1; duration: 260; easing.type: Easing.OutBack; easing.overshoot: 1.4 }
        }
    }
    remove: Transition {
        ParallelAnimation {
            NumberAnimation { property: "opacity"; to: 0; duration: 160; easing.type: Easing.InCubic }
            NumberAnimation { property: "scale"; to: 0.5; duration: 160; easing.type: Easing.InCubic }
        }
    }
    displaced: Transition {
        NumberAnimation { properties: "x"; duration: 220; easing.type: Easing.OutCubic }
    }

    delegate: Rectangle {
        id: slot
        required property var modelData
        required property int index
        property bool pressed: false
        property bool dragged: false
        property real dragPos: 0
        property real grab: 0
        readonly property bool running: modelData.windows.length > 0
        readonly property bool focused: running && modelData.windows.some(w => w.active)

        width: Theme.slotWidth
        height: Theme.slotHeight
        radius: Theme.slotRadius
        color: dragged ? Theme.pillHover : focused ? Theme.pillHover : (ma.containsMouse && !list.dragging ? Theme.pill : "transparent")
        z: dragged ? 10 : 0
        scale: dragged ? 1.12 : 1
        Behavior on scale { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
        transform: Translate { x: slot.dragged ? slot.dragPos - slot.x : 0 }
        Behavior on color { ColorAnimation { duration: Theme.animFast } }

        FittedIcon {
            anchors.centerIn: parent
            anchors.verticalCenterOffset: list.indicators && slot.running ? -2 : 0
            Behavior on anchors.verticalCenterOffset { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
            source: Apps.iconFor(slot.modelData)
            pressedScale: slot.pressed ? 0.88 : 1
        }

        Rectangle {
            anchors { bottom: parent.bottom; bottomMargin: 2; horizontalCenter: parent.horizontalCenter }
            width: !list.indicators ? 0 : slot.focused ? 18 : (slot.running ? 8 : 0)
            height: 3
            radius: 2
            color: Theme.fg
            opacity: !list.indicators ? 0 : slot.focused ? 1 : (slot.running ? 0.55 : 0)
            Behavior on width { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
            Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
        }

        MouseArea {
            id: ma
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            cursorShape: Qt.ArrowCursor
            property real startX: 0

            onPressed: mouse => {
                slot.pressed = true;
                startX = mouse.x;
                slot.grab = mouse.x;
            }
            onPositionChanged: mouse => {
                if (!list.reorderable || !(mouse.buttons & Qt.LeftButton)) return;
                if (!slot.dragged && Math.abs(mouse.x - startX) > 6) {
                    slot.dragged = true;
                    slot.pressed = false;
                    list.dragging = true;
                }
                if (!slot.dragged) return;
                const step = Theme.slotWidth + Theme.slotSpacing;
                const pos = Math.max(0, Math.min((list.count - 1) * step, mapToItem(list, mouse.x, 0).x - slot.grab));
                slot.dragPos = pos;
                const target = Math.round(pos / step);
                if (target !== slot.index) Config.movePinned(slot.modelData.id, target);
            }
            onReleased: {
                slot.pressed = false;
                if (slot.dragged) {
                    slot.dragged = false;
                    list.dragging = false;
                    Config.save(Config.pinned);
                }
            }
            onCanceled: {
                slot.pressed = false;
                if (slot.dragged) {
                    slot.dragged = false;
                    list.dragging = false;
                    Config.save(Config.pinned);
                }
            }
            onClicked: mouse => {
                if (mouse.button === Qt.RightButton) menu.visible = !menu.visible;
                else if (Math.abs(mouse.x - startX) <= 6) Apps.activate(slot.modelData);
            }
        }

        SlotMenu { id: menu; item: slot.modelData; anchorItem: slot; visible: false }
    }
}
