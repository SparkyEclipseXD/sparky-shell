import Quickshell
import Quickshell.Wayland
import QtQuick
import "../../theme"
import "../../services"
import "../common"

Item {
    id: root

    property string icon
    property real iconFill: 1
    default property alias panelContent: body.data
    property int panelWidth: 300
    property bool open: false

    implicitWidth: 30
    implicitHeight: 26

    readonly property string activeWindow: Windows.list.find(w => w.active)?.id ?? ""
    onActiveWindowChanged: open = false

    Rectangle {
        anchors.fill: parent
        radius: 9
        color: root.open ? Theme.pillHover : (ma.containsMouse ? Theme.pill : "transparent")
        Behavior on color { ColorAnimation { duration: Theme.animFast } }

        MaterialIcon {
            anchors.centerIn: parent
            size: 18
            name: root.icon
            fill: root.iconFill
        }

        MouseArea { id: ma; anchors.fill: parent; hoverEnabled: true; onClicked: root.open = !root.open }
    }

    PopupWindow {
        id: panel
        anchor {
            item: root
            edges: Edges.Bottom
            gravity: Edges.Bottom
            margins.top: 14
        }
        visible: root.open || card.opacity > 0
        grabFocus: root.open
        color: "transparent"
        implicitWidth: root.panelWidth
        implicitHeight: card.height + 10

        onVisibleChanged: if (!visible) root.open = false

        BackgroundEffect.blurRegion: card.opacity >= 1 ? blur : null
        property Region blur: Region { item: card; radius: card.radius }

        Rectangle {
            id: card
            width: root.panelWidth
            height: body.childrenRect.height + 24
            radius: 20
            color: Theme.surface
            opacity: root.open ? 1 : 0
            y: root.open ? 0 : -8
            Behavior on opacity { NumberAnimation { duration: root.open ? 180 : 130; easing.type: Easing.OutCubic } }
            Behavior on y { NumberAnimation { duration: 240; easing.type: Easing.OutQuint } }
            Behavior on height { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

            Item {
                id: body
                x: 12; y: 12
                width: parent.width - 24
            }
        }
    }
}
