import QtQuick

Item {
    id: root

    property bool locked: true
    property bool viewVisible: false
    property string notification

    signal clearPassword()
    signal notificationRepeated()

    implicitWidth: 800
    implicitHeight: 600

    LockScreenUi {
        id: ui
        anchors.fill: parent
    }

    onClearPassword: ui.clearPassword()
    onViewVisibleChanged: if (viewVisible) ui.wake()
}
