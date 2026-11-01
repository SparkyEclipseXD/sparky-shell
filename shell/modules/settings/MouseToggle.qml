import QtQuick
import "../../services"
import "../common"

Toggle {
    id: root

    property bool initial
    property string setting
    property bool invert: false
    property var mouse

    checked: initial
    onToggled: {
        checked = !checked;
        Hardware.setMouse(mouse.sys, setting, invert ? !checked : checked);
    }
}
