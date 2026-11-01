import QtQuick

Item {
    id: root

    property string name
    property real size: 24
    property real fill: 0
    property color color: "#f2f2f2"

    implicitWidth: size
    implicitHeight: size

    Text {
        text: root.name
        color: root.color
        renderType: Text.NativeRendering
        font {
            family: "Material Symbols Rounded"
            pixelSize: root.size
            variableAxes: ({ "FILL": root.fill, "wght": 400, "opsz": Math.min(48, Math.max(20, root.size)), "GRAD": 0 })
        }
        x: (root.width - root.size) / 2
        y: (root.height - root.size) / 2 + root.size - baselineOffset
    }
}
