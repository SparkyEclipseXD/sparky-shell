import QtQuick
import "../../theme"

Item {
    property bool open: true

    width: open ? 13 : 0
    height: Theme.slotHeight
    opacity: open ? 1 : 0
    Behavior on width { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
    Behavior on opacity { NumberAnimation { duration: 180 } }

    Rectangle {
        anchors.centerIn: parent
        width: 1
        height: Theme.slotHeight * 0.55
        color: Theme.divider
    }
}
