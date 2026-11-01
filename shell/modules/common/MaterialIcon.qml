import QtQuick
import "../../theme"

Item {
    id: root

    property string name
    property real size: 24
    property real fill: 0
    property int weight: 400
    property color color: Theme.fg

    Behavior on fill { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

    implicitWidth: size
    implicitHeight: size

    Text {
        text: root.name
        color: root.color
        renderType: Text.NativeRendering
        font {
            family: "Material Symbols Rounded"
            pixelSize: root.size
            variableAxes: ({ "FILL": root.fill, "wght": root.weight, "opsz": Math.min(48, Math.max(20, root.size)), "GRAD": 0 })
        }
        x: (root.width - root.size) / 2
        y: (root.height - root.size) / 2 + root.size - baselineOffset
    }
}
