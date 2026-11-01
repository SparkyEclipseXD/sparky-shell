import Quickshell
import QtQuick
import "../../services"

Grid {
    id: zoneRow

    property string zone
    property var components: ({})

    columns: 100
    spacing: TopBarConfig.spacing
    readonly property var compact: ["wifi", "bluetooth", "notifications"]
    horizontalItemAlignment: Grid.AlignHCenter
    verticalItemAlignment: Grid.AlignVCenter

    add: Transition {
        NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 220 }
        NumberAnimation { property: "scale"; from: 0.85; to: 1; duration: 260; easing.type: Easing.OutBack }
    }
    move: Transition { NumberAnimation { properties: "x,y"; duration: 300; easing.type: Easing.OutCubic } }

    Repeater {
        model: ScriptModel { values: TopBarConfig.layout[zoneRow.zone] ?? [] }

        Item {
            required property string modelData
            readonly property real pad: zoneRow.compact.includes(modelData) ? 0 : 7
            implicitWidth: loader.implicitWidth + 2 * pad
            implicitHeight: loader.implicitHeight
            Loader {
                id: loader
                anchors.centerIn: parent
                sourceComponent: zoneRow.components[parent.modelData] ?? null
            }
        }
    }
}
