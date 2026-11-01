import Quickshell.Widgets
import QtQuick
import QtQuick.Effects
import "../../theme"
import "../../services"

Rectangle {
    width: Theme.slotWidth
    height: Theme.slotHeight
    radius: Theme.slotRadius
    color: ma.containsMouse ? Theme.pillHover : "transparent"
    Behavior on color { ColorAnimation { duration: Theme.animFast } }

    IconImage {
        id: logo
        anchors.centerIn: parent
        implicitSize: Theme.iconSize
        source: "file:///usr/share/icons/cachyos.svg"
        visible: false
    }

    MultiEffect {
        anchors.fill: logo
        source: logo
        colorization: 1.0
        colorizationColor: "white"
        scale: ma.pressed ? 0.88 : 1
        Behavior on scale { NumberAnimation { duration: Theme.animFast; easing.type: Easing.OutCubic } }
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: mouse => {
            if (mouse.button === Qt.RightButton) {
                LauncherState.close();
                Power.toggle();
            } else {
                LauncherState.toggle();
            }
        }
    }
}
