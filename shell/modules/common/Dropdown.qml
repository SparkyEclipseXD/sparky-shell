import QtQuick
import "../../theme"

Item {
    id: root

    property var options: []
    property var value
    signal picked(var value)

    property bool open: false
    readonly property var current: options.find(o => o.value === value) ?? options[0]

    implicitWidth: Math.max(pill.width, 190)
    implicitHeight: pill.height
    z: open ? 100 : 0

    Rectangle {
        id: pill
        width: Math.max(190, row.implicitWidth + 32)
        height: 38
        radius: 19
        color: ma.pressed || root.open ? Theme.pillHover : (ma.containsMouse ? Qt.rgba(1, 1, 1, 0.12) : Theme.pill)
        Behavior on color { ColorAnimation { duration: Theme.animFast } }

        Row {
            id: row
            anchors { left: parent.left; leftMargin: 16; verticalCenter: parent.verticalCenter }
            spacing: 8
            MaterialIcon { anchors.verticalCenter: parent.verticalCenter; size: 18; name: root.current?.icon ?? ""; visible: !!root.current?.icon }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: root.current?.label ?? ""
                color: Theme.fg
                font { family: Theme.font; pixelSize: 14; weight: Font.Medium }
            }
        }
        MaterialIcon {
            anchors { right: parent.right; rightMargin: 12; verticalCenter: parent.verticalCenter }
            size: 20
            name: "keyboard_arrow_down"
            color: Theme.fgDim
            rotation: root.open ? 180 : 0
            Behavior on rotation { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
        }
        MouseArea { id: ma; anchors.fill: parent; hoverEnabled: true; onClicked: root.open = !root.open }
    }

    Rectangle {
        id: menu
        anchors { top: pill.bottom; topMargin: 6; right: pill.right }
        width: pill.width
        height: root.open ? list.implicitHeight + 12 : 0
        radius: 16
        clip: true
        color: Qt.rgba(0.08, 0.08, 0.09, 0.98)
        opacity: root.open ? 1 : 0
        visible: height > 0
        Behavior on height { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
        Behavior on opacity { NumberAnimation { duration: 160 } }

        Column {
            id: list
            x: 6; y: 6
            width: parent.width - 12
            spacing: 2

            Repeater {
                model: root.options
                Rectangle {
                    id: opt
                    required property var modelData
                    readonly property bool chosen: modelData.value === root.value
                    width: list.width
                    height: 36
                    radius: 11
                    color: optArea.containsMouse ? Qt.rgba(1, 1, 1, 0.08) : "transparent"
                    Behavior on color { ColorAnimation { duration: Theme.animFast } }

                    Row {
                        anchors { left: parent.left; leftMargin: 10; verticalCenter: parent.verticalCenter }
                        spacing: 8
                        MaterialIcon { anchors.verticalCenter: parent.verticalCenter; size: 18; name: opt.modelData.icon ?? ""; visible: !!opt.modelData.icon; color: opt.chosen ? Theme.fg : Theme.fgDim }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: opt.modelData.label
                            color: opt.chosen ? Theme.fg : Qt.rgba(1, 1, 1, 0.75)
                            font { family: Theme.font; pixelSize: 14; weight: opt.chosen ? Font.Medium : Font.Normal }
                        }
                    }
                    MaterialIcon {
                        anchors { right: parent.right; rightMargin: 10; verticalCenter: parent.verticalCenter }
                        visible: opt.chosen
                        size: 18
                        name: "check"
                    }
                    MouseArea {
                        id: optArea
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: { root.open = false; root.picked(opt.modelData.value); }
                    }
                }
            }
        }
    }
}
