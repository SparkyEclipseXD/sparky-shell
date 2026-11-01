import QtQuick
import "../../theme"
import "../../services"
import "../common"

Item {
    Column {
        anchors { fill: parent; margins: 28; topMargin: 4 }
        spacing: 18

        Text {
            text: "Controls"
            color: Theme.fg
            font { family: Theme.font; pixelSize: 22; weight: Font.Medium }
        }

        Text {
            width: parent.width
            wrapMode: Text.WordWrap
            text: "Click a key combo, then press the new one. Esc cancels, Backspace clears it. Changes apply right away."
            color: Theme.fgDim
            font { family: Theme.font; pixelSize: 13 }
        }

        ListView {
            id: list
            width: parent.width
            height: parent.height - y - 56
            clip: true
            spacing: 8
            boundsBehavior: Flickable.StopAtBounds
            model: Binds.binds

            add: Transition { NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 180 } }
            remove: Transition { NumberAnimation { property: "opacity"; to: 0; duration: 120 } }
            displaced: Transition { NumberAnimation { property: "y"; duration: 180; easing.type: Easing.OutCubic } }

            delegate: Rectangle {
                id: row
                required property var modelData
                readonly property bool custom: Binds.isCustom(modelData)

                width: list.width
                height: 64
                radius: 14
                color: Theme.card

                Column {
                    anchors { left: parent.left; leftMargin: 18; right: chip.left; rightMargin: 14; verticalCenter: parent.verticalCenter }
                    spacing: 2

                    Text {
                        text: row.modelData.label
                        color: Theme.fg
                        font { family: Theme.font; pixelSize: 15 }
                    }

                    TextInput {
                        id: command
                        width: parent.width
                        readOnly: !row.custom
                        text: Binds.isKwin(row.modelData) ? "Built into KWin" : (row.modelData.command ?? "")
                        color: Theme.fgDim
                        selectionColor: Qt.rgba(1, 1, 1, 0.25)
                        clip: true
                        font { family: Theme.font; pixelSize: 12 }
                        onEditingFinished: if (row.custom) Binds.update(row.modelData.id, { command: text })

                        Text {
                            visible: row.custom && command.text === ""
                            text: "Command to run, e.g. kitty"
                            color: Qt.rgba(1, 1, 1, 0.3)
                            font: command.font
                        }
                    }
                }

                KeyChip {
                    id: chip
                    anchors { right: remove.left; rightMargin: row.custom ? 10 : -20; verticalCenter: parent.verticalCenter }
                    keys: row.modelData.keys
                    onCaptured: value => Binds.update(row.modelData.id, { keys: value })
                }

                Rectangle {
                    id: remove
                    visible: row.custom
                    anchors { right: parent.right; rightMargin: 14; verticalCenter: parent.verticalCenter }
                    width: 30; height: 30; radius: 15
                    color: rm.containsMouse ? Theme.pillHover : "transparent"
                    Behavior on color { ColorAnimation { duration: Theme.animFast } }
                    MaterialIcon {
                        anchors.centerIn: parent
                        size: 18
                        name: "close"
                        color: rm.containsMouse ? Theme.fg : Theme.fgDim
                    }
                    MouseArea {
                        id: rm
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: Binds.remove(row.modelData.id)
                    }
                }
            }
        }

        Row {
            spacing: 12
            PillButton { text: "Add custom bind"; onClicked: Binds.addCustom() }
            PillButton { text: "Reset to defaults"; onClicked: Binds.reset() }
        }
    }
}
