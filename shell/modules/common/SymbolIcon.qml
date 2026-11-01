import Quickshell
import Quickshell.Widgets
import QtQuick
import QtQuick.Effects
import "../../theme"

Item {
    id: root

    property string name
    property color color: Theme.fg
    property int size: 18

    implicitWidth: size
    implicitHeight: size

    IconImage {
        id: icon
        anchors.fill: parent
        implicitSize: root.size
        source: Quickshell.iconPath(root.name)
        visible: false
    }

    MultiEffect {
        anchors.fill: icon
        source: icon
        colorization: 1.0
        colorizationColor: root.color
    }
}
