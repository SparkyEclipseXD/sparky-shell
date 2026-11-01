import QtQuick
import "../../theme"

Rectangle {
    id: row

    property alias text: label.text
    signal activated()

    width: parent.width
    height: visible ? 34 : 0
    radius: 9
    color: ma.containsMouse ? Theme.pillHover : "transparent"
    Behavior on color { ColorAnimation { duration: Theme.animFast } }

    Text {
        id: label
        anchors { left: parent.left; leftMargin: 12; verticalCenter: parent.verticalCenter }
        color: Theme.fg
        font { family: Theme.font; pixelSize: 14 }
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        onClicked: row.activated()
    }
}
