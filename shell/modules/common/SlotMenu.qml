import Quickshell
import QtQuick
import "../../theme"
import "../../services"

PopupWindow {
    id: menu

    required property var item
    required property Item anchorItem
    property bool above: true

    readonly property bool running: item.windows.length > 0

    anchor {
        item: anchorItem
        edges: menu.above ? Edges.Top : Edges.Bottom
        gravity: menu.above ? Edges.Top : Edges.Bottom
        margins.bottom: menu.above ? 8 : 0
        margins.top: menu.above ? 0 : 6
    }
    implicitWidth: 190
    implicitHeight: column.implicitHeight + 12
    color: "transparent"
    grabFocus: true

    onVisibleChanged: DockState.holds += visible ? 1 : -1
    Component.onDestruction: if (visible) DockState.holds--

    Rectangle {
        anchors.fill: parent
        radius: 14
        color: Theme.surface

        Column {
            id: column
            anchors { fill: parent; margins: 6 }
            spacing: 2

            MenuRow {
                text: menu.item.pinned ? "Unpin from taskbar" : "Pin to taskbar"
                onActivated: { Apps.togglePin(menu.item); menu.visible = false }
            }
            MenuRow {
                text: menu.running ? "New window" : "Open"
                visible: menu.item.entry !== null
                onActivated: { menu.item.entry?.execute(); menu.visible = false }
            }
            MenuRow {
                text: "Close window"
                visible: menu.running
                onActivated: { Windows.close(menu.item.windows[0].id); menu.visible = false }
            }
        }
    }
}
