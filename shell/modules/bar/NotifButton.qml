import Quickshell
import QtQuick
import "../../theme"
import "../../services"
import "../common"

BarButton {
    id: root

    readonly property bool dnd: Notifs.prefs.dnd

    icon: dnd ? "notifications_off" : "notifications"
    iconFill: dnd ? 1 : 0
    panelWidth: 280

    Column {
        width: parent.width
        spacing: 6

        Item {
            width: parent.width
            height: 34
            Text {
                anchors { left: parent.left; leftMargin: 6; verticalCenter: parent.verticalCenter }
                text: "Do not disturb"
                color: Theme.fg
                font { family: Theme.font; pixelSize: 15; weight: Font.Medium }
            }
            Toggle {
                anchors { right: parent.right; rightMargin: 4; verticalCenter: parent.verticalCenter }
                checked: root.dnd
                onToggled: Notifs.set("dnd", !root.dnd)
            }
        }

        Text {
            width: parent.width
            leftPadding: 6
            wrapMode: Text.WordWrap
            text: root.dnd ? "Popups are held back" + (Notifs.prefs.criticalBreaksDnd ? ", except urgent ones." : ".")
                           : "Popups show as they arrive."
            color: Theme.fgDim
            font { family: Theme.font; pixelSize: 12 }
        }

        Row {
            width: parent.width
            spacing: 6
            PillButton {
                width: (parent.width - 6) / 2
                implicitHeight: 34
                text: "Send a test"
                onClicked: Notifs.test()
            }
            PillButton {
                width: (parent.width - 6) / 2
                implicitHeight: 34
                text: "Settings"
                onClicked: { root.open = false; SettingsState.showTab("notifications"); }
            }
        }
    }
}
