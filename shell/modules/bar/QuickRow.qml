import QtQuick
import "../../theme"
import "../common"

Rectangle {
    id: row

    property string icon
    property bool active: false
    property string title
    property string subtitle
    property bool busy: false
    property string action: ""
    signal clicked()
    signal actionClicked()

    width: parent ? parent.width : 0
    height: 48
    radius: 14
    color: area.containsMouse ? Qt.rgba(1, 1, 1, 0.07) : "transparent"
    Behavior on color { ColorAnimation { duration: Theme.animFast } }

    MouseArea { id: area; anchors.fill: parent; hoverEnabled: true; onClicked: row.clicked() }

    Rectangle {
        id: tile
        anchors { left: parent.left; leftMargin: 6; verticalCenter: parent.verticalCenter }
        width: 34; height: 34; radius: 11
        color: row.active ? Theme.fg : Theme.pill
        Behavior on color { ColorAnimation { duration: Theme.animNormal } }
        MaterialIcon { anchors.centerIn: parent; size: 18; name: row.icon; fill: 1; color: row.active ? "black" : Theme.fg }
    }

    Column {
        anchors { left: tile.right; leftMargin: 10; right: actions.left; rightMargin: 8; verticalCenter: parent.verticalCenter }
        spacing: 1
        Text {
            width: parent.width
            text: row.title
            elide: Text.ElideRight
            color: Theme.fg
            font { family: Theme.font; pixelSize: 13; weight: Font.Medium }
        }
        FadeText {
            width: parent.width
            visible: shown !== ""
            shown: row.subtitle
            elide: Text.ElideRight
            color: Theme.fgDim
            font { family: Theme.font; pixelSize: 11 }
        }
    }

    Item {
        id: actions
        anchors { right: parent.right; rightMargin: 6; verticalCenter: parent.verticalCenter }
        width: row.busy ? 24 : (row.action ? btn.width : 0)
        height: 28

        Item {
            anchors.centerIn: parent
            visible: row.busy
            width: 16; height: 16
            Rectangle { anchors.fill: parent; radius: 8; color: "transparent"; border { width: 2; color: Qt.rgba(1, 1, 1, 0.18) } }
            Rectangle { width: 5; height: 5; radius: 2.5; x: 5.5; y: -1.5; color: Theme.fg }
            RotationAnimation on rotation { running: row.busy; from: 0; to: 360; duration: 800; loops: Animation.Infinite }
        }

        PillButton {
            id: btn
            visible: !row.busy && row.action !== ""
            implicitHeight: 28
            text: row.action
            onClicked: row.actionClicked()
        }
    }
}
