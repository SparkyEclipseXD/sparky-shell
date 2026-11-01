import Quickshell
import Quickshell.Widgets
import Quickshell.Wayland
import Quickshell.Services.SystemTray
import QtQuick
import "../../theme"
import "../../services"
import "../common"

Item {
    id: root

    readonly property var items: SystemTray.items.values.filter(i => i.status !== Status.Passive || open)
    readonly property int count: items.length
    property bool open: false

    implicitWidth: count > 0 ? Theme.slotWidth : 0
    implicitHeight: Theme.slotHeight
    visible: implicitWidth > 0
    clip: true
    Behavior on implicitWidth { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

    readonly property string activeWindow: Windows.list.find(w => w.active)?.id ?? ""
    onActiveWindowChanged: open = false

    onOpenChanged: DockState.holds += open ? 1 : -1
    Component.onDestruction: if (open) DockState.holds--

    Rectangle {
        id: button
        width: Theme.slotWidth
        height: Theme.slotHeight
        radius: Theme.slotRadius
        color: root.open ? Theme.pillHover : (ma.containsMouse ? Theme.pill : "transparent")
        Behavior on color { ColorAnimation { duration: Theme.animFast } }

        MaterialIcon {
            anchors.centerIn: parent
            size: 22
            name: "keyboard_arrow_up"
            rotation: root.open ? 180 : 0
            Behavior on rotation { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
        }

        Rectangle {
            anchors { right: parent.right; top: parent.top; rightMargin: 4; topMargin: 3 }
            width: Math.max(16, badge.implicitWidth + 8)
            height: 16
            radius: 8
            color: Theme.fg
            opacity: root.open ? 0 : 1
            Behavior on opacity { NumberAnimation { duration: Theme.animFast } }
            Text {
                id: badge
                anchors.centerIn: parent
                text: root.count
                color: "black"
                font { family: Theme.font; pixelSize: 10; weight: Font.Bold }
            }
        }

        MouseArea {
            id: ma
            anchors.fill: parent
            hoverEnabled: true
            onClicked: root.open = !root.open
        }
    }

    PopupWindow {
        id: panel

        anchor {
            item: button
            edges: Edges.Top
            gravity: Edges.Top
            margins.bottom: 12
        }
        visible: root.open || card.opacity > 0
        grabFocus: root.open
        color: "transparent"
        implicitHeight: card.height + 12 + 30
        implicitWidth: Math.max(card.width, 160)

        onVisibleChanged: if (!visible) root.open = false

        BackgroundEffect.blurRegion: card.opacity >= 1 ? blurRegion : null
        property Region blurRegion: Region { item: card; radius: card.radius }

        Rectangle {
            id: card
            anchors.horizontalCenter: parent.horizontalCenter

            readonly property int columns: Math.min(5, Math.max(1, root.count))
            readonly property int tile: 44

            width: columns * tile + (columns - 1) * 4 + 16
            height: grid.height + 16
            radius: 16
            color: Theme.surface
            opacity: root.open ? 1 : 0
            y: 30 + (root.open ? 0 : 8)
            Behavior on opacity { NumberAnimation { duration: root.open ? 180 : 130; easing.type: Easing.OutCubic } }
            Behavior on y { NumberAnimation { duration: 240; easing.type: Easing.OutQuint } }

            Grid {
                id: grid
                x: 8; y: 8
                columns: card.columns
                spacing: 4

                Repeater {
                    model: ScriptModel { values: root.items }

                    Rectangle {
                        id: tile
                        required property var modelData
                        readonly property var item: modelData
                        width: card.tile
                        height: card.tile
                        radius: 12
                        color: tileArea.pressed ? Qt.rgba(1, 1, 1, 0.16) : (tileArea.containsMouse ? Theme.pill : "transparent")
                        Behavior on color { ColorAnimation { duration: Theme.animFast } }

                        IconImage {
                            anchors.centerIn: parent
                            implicitSize: 24
                            source: tile.item.icon
                            scale: tileArea.pressed ? 0.9 : 1
                            Behavior on scale { NumberAnimation { duration: Theme.animFast } }
                        }

                        Rectangle {
                            anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.top; bottomMargin: 6 }
                            width: tip.implicitWidth + 16
                            height: 22
                            radius: 11
                            color: Qt.rgba(0.04, 0.04, 0.05, 0.92)
                            opacity: tileArea.containsMouse ? 1 : 0
                            visible: opacity > 0
                            z: 5
                            Behavior on opacity { NumberAnimation { duration: Theme.animFast } }
                            Text {
                                id: tip
                                anchors.centerIn: parent
                                text: tile.item.tooltipTitle || tile.item.title || tile.item.id
                                color: Theme.fg
                                font { family: Theme.font; pixelSize: 12 }
                            }
                        }

                        MouseArea {
                            id: tileArea
                            anchors.fill: parent
                            hoverEnabled: true
                            acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                            onClicked: mouse => {
                                if (mouse.button === Qt.RightButton || (mouse.button === Qt.LeftButton && tile.item.onlyMenu)) {
                                    const p = tile.mapToItem(card, mouse.x, mouse.y);
                                    tile.item.display(panel, p.x, p.y);
                                } else if (mouse.button === Qt.MiddleButton) {
                                    tile.item.secondaryActivate();
                                } else {
                                    tile.item.activate();
                                    root.open = false;
                                }
                            }
                            onWheel: wheel => tile.item.scroll(wheel.angleDelta.y / 120, false)
                        }
                    }
                }
            }
        }
    }
}
