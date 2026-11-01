import QtQuick
import "../../theme"
import "../../services"
import "../common"

Rectangle {
    id: root

    property string chipId
    property bool lifted: false
    property bool compact: false
    readonly property var info: TopBarConfig.items[chipId] ?? { label: chipId, icon: "help" }

    width: compact ? 32 : chipRow.implicitWidth + 22
    Behavior on width { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
    clip: true
    height: 32
    radius: 16
    color: lifted ? Theme.fg : Theme.pillHover

    Row {
        id: chipRow
        anchors.centerIn: parent
        spacing: 6
        MaterialIcon { anchors.verticalCenter: parent.verticalCenter; size: 16; name: root.info.icon; color: root.lifted ? "black" : Theme.fg }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            visible: !root.compact
            text: root.info.label
            color: root.lifted ? "black" : Theme.fg
            font { family: Theme.font; pixelSize: 13; weight: Font.Medium }
        }
    }
}
