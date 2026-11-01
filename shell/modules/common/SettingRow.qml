import QtQuick
import "../../theme"

Rectangle {
    id: row

    property string label
    property string hint
    default property alias control: holder.data

    width: parent ? parent.width : 0
    height: Math.max(64, texts.implicitHeight + 28, holder.height + 28)
    radius: 14
    color: Theme.card

    Column {
        id: texts
        anchors { left: parent.left; leftMargin: 18; right: holder.left; rightMargin: 18; verticalCenter: parent.verticalCenter }
        spacing: 2

        Text {
            text: row.label
            color: Theme.fg
            font { family: Theme.font; pixelSize: 15 }
        }

        Text {
            visible: text !== ""
            width: parent.width
            text: row.hint
            wrapMode: Text.WordWrap
            color: Theme.fgDim
            font { family: Theme.font; pixelSize: 12 }
        }
    }

    Item {
        id: holder
        anchors { right: parent.right; rightMargin: 16; verticalCenter: parent.verticalCenter }
        width: childrenRect.width
        height: childrenRect.height
    }
}
