import QtQuick
import "../../theme"

Rectangle {
    id: root

    property bool checked: false
    signal toggled()

    implicitWidth: 46
    implicitHeight: 26
    radius: height / 2
    color: checked ? Qt.rgba(1, 1, 1, 0.34) : (ma.containsMouse ? Theme.pillHover : Theme.pill)
    Behavior on color { ColorAnimation { duration: Theme.animNormal } }

    Rectangle {
        id: knob
        readonly property real d: root.height - 6
        property bool travelling: false
        y: 3
        width: d + (travelling ? 7 : 0)
        height: d
        radius: d / 2
        x: root.checked ? root.width - width - 3 : 3
        color: root.checked ? Theme.fg : Qt.rgba(1, 1, 1, 0.45)
        Behavior on x { NumberAnimation { duration: 280; easing.type: Easing.OutBack; easing.overshoot: 1.1 } }
        Behavior on width { NumberAnimation { duration: 140; easing.type: Easing.OutQuad } }
        Behavior on color { ColorAnimation { duration: Theme.animNormal } }

        Connections {
            target: root
            function onCheckedChanged() { knob.travelling = true; settle.restart(); }
        }
        Timer { id: settle; interval: 150; onTriggered: knob.travelling = false }
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        onClicked: root.toggled()
    }
}
