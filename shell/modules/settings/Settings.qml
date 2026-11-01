import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import QtQuick
import "../../theme"
import "../../services"
import "../common"

FloatingWindow {
    id: win

    visible: SettingsState.open
    onVisibleChanged: if (!visible) SettingsState.open = false

    title: "Sparky Settings"
    implicitWidth: 940
    implicitHeight: 620
    minimumSize: Qt.size(760, 520)
    color: "transparent"

    readonly property int cornerRadius: maximized ? 0 : Theme.dockRadius

    BackgroundEffect.blurRegion: Region { item: glass; radius: win.cornerRadius }

    Rectangle {
        id: glass
        anchors.fill: parent
        radius: win.cornerRadius
        color: Theme.window
    }

    property int tab: SettingsState.tab
    onTabChanged: SettingsState.tab = tab
    Connections { target: SettingsState; function onTabChanged() { win.tab = SettingsState.tab } }
    readonly property var tabs: [
        { name: "Customization", icon: "palette" },
        { name: "Controls", icon: "keyboard" },
        { name: "Mouse", icon: "mouse" },
        { name: "Notifications", icon: "notifications" },
        { name: "Wi-Fi", icon: "wifi" },
        { name: "Bluetooth", icon: "bluetooth" }
    ]

    MouseArea {
        anchors { top: parent.top; left: parent.left; right: parent.right }
        height: 56
        onPressed: win.startSystemMove()
    }

    Rectangle {
        id: sidebar
        anchors { top: parent.top; bottom: parent.bottom; left: parent.left }
        width: 230
        color: Theme.sidebar
        topLeftRadius: win.cornerRadius
        bottomLeftRadius: win.cornerRadius

        MouseArea {
            anchors { top: parent.top; left: parent.left; right: parent.right }
            height: 72
            onPressed: win.startSystemMove()
        }

        Row {
            x: 24; y: 26
            spacing: 10

            MaterialIcon {
                anchors.verticalCenter: parent.verticalCenter
                size: 26
                name: "settings"
                fill: 1
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "Settings"
                color: Theme.fg
                font { family: Theme.font; pixelSize: 20; weight: Font.Medium }
            }
        }

        Rectangle {
            x: 14
            y: 84 + win.tab * 50
            width: sidebar.width - 28
            height: 42
            radius: 21
            color: Theme.pillHover
            Behavior on y { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
        }

        Repeater {
            model: win.tabs

            Item {
                id: tabItem
                required property var modelData
                required property int index
                readonly property bool current: win.tab === index
                x: 14
                y: 84 + index * 50
                width: sidebar.width - 28
                height: 42

                MaterialIcon {
                    id: tabIcon
                    anchors { left: parent.left; leftMargin: 13; verticalCenter: parent.verticalCenter }
                    size: 25
                    weight: 500
                    name: tabItem.modelData.icon
                    fill: tabItem.current ? 1 : 0
                    color: tabItem.current ? Theme.fg : Qt.rgba(1, 1, 1, 0.72)
                    Behavior on color { ColorAnimation { duration: Theme.animFast } }
                }

                Text {
                    anchors { left: tabIcon.right; leftMargin: 13; verticalCenter: parent.verticalCenter }
                    text: tabItem.modelData.name
                    color: tabItem.current ? Theme.fg : Qt.rgba(1, 1, 1, 0.72)
                    font { family: Theme.font; pixelSize: 15 }
                    Behavior on color { ColorAnimation { duration: Theme.animFast } }
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: win.tab = tabItem.index
                }
            }
        }

        Rectangle {
            id: account
            anchors { left: parent.left; right: parent.right; bottom: parent.bottom; margins: 14 }
            height: 60
            radius: 18
            color: userArea.containsMouse ? Theme.pill : "transparent"
            Behavior on color { ColorAnimation { duration: Theme.animFast } }

            MouseArea {
                id: userArea
                anchors.fill: parent
                hoverEnabled: true
                onClicked: User.edit()
            }

            ClippingRectangle {
                id: avatar
                anchors { left: parent.left; leftMargin: 10; verticalCenter: parent.verticalCenter }
                width: 40; height: 40; radius: 20
                color: Theme.pillHover
                scale: userArea.pressed ? 0.94 : 1
                Behavior on scale { NumberAnimation { duration: Theme.animFast; easing.type: Easing.OutCubic } }

                Text {
                    anchors.centerIn: parent
                    visible: picture.status !== Image.Ready
                    text: User.initial
                    color: Theme.fg
                    font { family: Theme.font; pixelSize: 17; weight: Font.Medium }
                }

                Image {
                    id: picture
                    anchors.fill: parent
                    source: User.avatar
                    sourceSize: Qt.size(80, 80)
                    fillMode: Image.PreserveAspectCrop
                    cache: false
                    smooth: true
                    mipmap: true
                }
            }

            Column {
                anchors { left: avatar.right; leftMargin: 12; right: power.left; rightMargin: 6; verticalCenter: parent.verticalCenter }
                spacing: 1

                Text {
                    width: parent.width
                    text: User.realName
                    elide: Text.ElideRight
                    color: Theme.fg
                    font { family: Theme.font; pixelSize: 14; weight: Font.Medium }
                }
                Text {
                    width: parent.width
                    text: "@" + User.name
                    elide: Text.ElideRight
                    color: Theme.fgDim
                    font { family: Theme.font; pixelSize: 12 }
                }
            }

            Rectangle {
                id: power
                anchors { right: parent.right; rightMargin: 8; verticalCenter: parent.verticalCenter }
                width: 34; height: 34; radius: 17
                color: powerArea.pressed ? Qt.rgba(1, 1, 1, 0.22) : (powerArea.containsMouse ? Theme.pillHover : "transparent")
                Behavior on color { ColorAnimation { duration: Theme.animFast } }

                MaterialIcon {
                    anchors.centerIn: parent
                    size: 19
                    name: "power_settings_new"
                    color: powerArea.containsMouse ? Theme.fg : Theme.fgDim
                }

                MouseArea {
                    id: powerArea
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: Power.open = true
                }
            }
        }
    }

    CustomizationPage {
        anchors { top: parent.top; topMargin: 50; bottom: parent.bottom; left: sidebar.right; right: parent.right }
        clip: true
        opacity: win.tab === 0 ? 1 : 0
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: 160 } }
    }

    ControlsPage {
        anchors { top: parent.top; topMargin: 50; bottom: parent.bottom; left: sidebar.right; right: parent.right }
        clip: true
        opacity: win.tab === 1 ? 1 : 0
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: 160 } }
    }

    MousePage {
        anchors { top: parent.top; topMargin: 50; bottom: parent.bottom; left: sidebar.right; right: parent.right }
        clip: true
        opacity: win.tab === 2 ? 1 : 0
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: 160 } }
    }

    NotificationsPage {
        anchors { top: parent.top; topMargin: 50; bottom: parent.bottom; left: sidebar.right; right: parent.right }
        clip: true
        opacity: win.tab === 3 ? 1 : 0
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: 160 } }
    }

    WifiPage {
        anchors { top: parent.top; topMargin: 50; bottom: parent.bottom; left: sidebar.right; right: parent.right }
        clip: true
        opacity: win.tab === 4 ? 1 : 0
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: 160 } }
    }

    BluetoothPage {
        anchors { top: parent.top; topMargin: 50; bottom: parent.bottom; left: sidebar.right; right: parent.right }
        clip: true
        opacity: win.tab === 5 ? 1 : 0
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: 160 } }
    }

    Row {
        anchors { top: parent.top; right: parent.right; margins: 14 }
        spacing: 4

        Repeater {
            model: [
                { icon: "keyboard_arrow_down", act: () => win.minimized = true },
                { icon: win.maximized ? "collapse_content" : "keyboard_arrow_up",
                  act: () => win.maximized = !win.maximized },
                { icon: "close", act: () => SettingsState.open = false }
            ]

            Rectangle {
                id: button
                required property var modelData
                width: 30; height: 30; radius: 15
                color: bma.pressed ? Qt.rgba(1, 1, 1, 0.22) : (bma.containsMouse ? Theme.pillHover : "transparent")
                Behavior on color { ColorAnimation { duration: Theme.animFast } }

                MaterialIcon {
                    anchors.centerIn: parent
                    size: 20
                    name: button.modelData.icon
                    color: bma.containsMouse ? Theme.fg : Theme.fgDim
                }

                MouseArea {
                    id: bma
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: button.modelData.act()
                }
            }
        }
    }

    Repeater {
        model: win.maximized ? [] : [
            { e: Qt.TopEdge, x: 1, y: 0, w: 1, h: 0, cur: Qt.SizeVerCursor },
            { e: Qt.BottomEdge, x: 1, y: 2, w: 1, h: 0, cur: Qt.SizeVerCursor },
            { e: Qt.LeftEdge, x: 0, y: 1, w: 0, h: 1, cur: Qt.SizeHorCursor },
            { e: Qt.RightEdge, x: 2, y: 1, w: 0, h: 1, cur: Qt.SizeHorCursor },
            { e: Qt.TopEdge | Qt.LeftEdge, x: 0, y: 0, w: 0, h: 0, cur: Qt.SizeFDiagCursor },
            { e: Qt.BottomEdge | Qt.RightEdge, x: 2, y: 2, w: 0, h: 0, cur: Qt.SizeFDiagCursor },
            { e: Qt.TopEdge | Qt.RightEdge, x: 2, y: 0, w: 0, h: 0, cur: Qt.SizeBDiagCursor },
            { e: Qt.BottomEdge | Qt.LeftEdge, x: 0, y: 2, w: 0, h: 0, cur: Qt.SizeBDiagCursor }
        ]

        MouseArea {
            required property var modelData
            readonly property int grip: 6
            readonly property int corner: 14
            width: modelData.w ? win.width - 2 * corner : (modelData.h ? grip : corner)
            height: modelData.h ? win.height - 2 * corner : (modelData.w ? grip : corner)
            x: modelData.x === 0 ? 0 : modelData.x === 1 ? corner : win.width - width
            y: modelData.y === 0 ? 0 : modelData.y === 1 ? corner : win.height - height
            cursorShape: modelData.cur
            onPressed: win.startSystemResize(modelData.e)
        }
    }
}
