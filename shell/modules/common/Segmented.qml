import QtQuick
import "../../theme"

Rectangle {
    id: root

    property var options: []
    property var value
    property int itemWidth: 60
    signal picked(var value)

    readonly property int current: options.findIndex(o => o.value === value)

    implicitWidth: options.length * itemWidth + 8
    implicitHeight: 38
    radius: height / 2
    color: Theme.pill

    Rectangle {
        visible: root.current >= 0
        x: 4 + root.current * root.itemWidth
        y: 4
        width: root.itemWidth
        height: root.height - 8
        radius: height / 2
        color: Theme.pillHover
        Behavior on x { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
    }

    Row {
        x: 4; y: 4

        Repeater {
            model: root.options

            Item {
                id: option
                required property var modelData
                required property int index
                width: root.itemWidth
                height: root.height - 8

                Text {
                    anchors.centerIn: parent
                    text: option.modelData.label
                    color: option.index === root.current || ma.containsMouse ? Theme.fg : Theme.fgDim
                    font { family: Theme.font; pixelSize: 13; weight: Font.Medium }
                    Behavior on color { ColorAnimation { duration: Theme.animFast } }
                }

                MouseArea {
                    id: ma
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: root.picked(option.modelData.value)
                }
            }
        }
    }
}
