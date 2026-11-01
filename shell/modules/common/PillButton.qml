import QtQuick
import "../../theme"

Rectangle {
    id: root

    property alias text: label.text
    property string icon: ""
    property bool danger: false
    signal clicked()

    readonly property bool iconOnly: icon !== "" && label.text === ""

    implicitWidth: iconOnly ? implicitHeight : content.implicitWidth + 36
    implicitHeight: 38
    radius: height / 2
    color: ma.pressed ? Qt.rgba(1, 1, 1, 0.22) : (ma.containsMouse ? Theme.pillHover : Theme.pill)
    Behavior on color { ColorAnimation { duration: Theme.animFast } }

    Row {
        id: content
        anchors.centerIn: parent
        spacing: 8

        MaterialIcon {
            anchors.verticalCenter: parent.verticalCenter
            visible: root.icon !== "" && !root.icon.endsWith("-symbolic")
            name: visible ? root.icon : ""
            size: 18
        }

        SymbolIcon {
            anchors.verticalCenter: parent.verticalCenter
            visible: root.icon.endsWith("-symbolic")
            name: visible ? root.icon : ""
            size: 16
        }

        Text {
            id: label
            anchors.verticalCenter: parent.verticalCenter
            visible: text !== ""
            color: Theme.fg
            font { family: Theme.font; pixelSize: 14; weight: Font.Medium }
        }
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        onClicked: root.clicked()
    }
}
