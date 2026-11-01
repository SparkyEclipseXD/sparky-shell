import Quickshell
import QtQuick
import "../../theme"
import "../../services"
import "../common"

Item {
    id: page

    component Heading: Text {
        topPadding: 10
        color: Theme.fgDim
        font { family: Theme.font; pixelSize: 14; weight: Font.Medium }
    }

    Flickable {
        anchors.fill: parent
        contentHeight: column.implicitHeight + 32
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        Column {
            id: column
            x: 28; y: 4
            width: page.width - 56
            spacing: 10

            Text {
                bottomPadding: 6
                text: "Notifications"
                color: Theme.fg
                font { family: Theme.font; pixelSize: 22; weight: Font.Medium }
            }

            SettingRow {
                label: "Do not disturb"
                hint: "Hold back popups until you turn this off"
                Toggle { checked: Notifs.prefs.dnd; onToggled: Notifs.set("dnd", !checked) }
            }

            SettingRow {
                label: "Let urgent ones through"
                hint: "Critical alerts still pop up during Do not disturb"
                Toggle { checked: Notifs.prefs.criticalBreaksDnd; onToggled: Notifs.set("criticalBreaksDnd", !checked) }
            }

            Heading { text: "Popups" }

            SettingRow {
                label: "Position"
                hint: "Where popups stack on screen"

                Rectangle {
                    id: picker
                    width: 184; height: 108
                    radius: 12
                    color: Qt.rgba(1, 1, 1, 0.04)

                    Rectangle {
                        anchors { bottom: parent.bottom; bottomMargin: 7; horizontalCenter: parent.horizontalCenter }
                        width: 50; height: 7; radius: 3.5
                        color: Theme.pill
                    }

                    Repeater {
                        model: [
                            { value: "top-left", col: 0, row: 0 },
                            { value: "top", col: 1, row: 0 },
                            { value: "top-right", col: 2, row: 0 },
                            { value: "bottom-left", col: 0, row: 1 },
                            { value: "bottom-right", col: 2, row: 1 }
                        ]

                        Rectangle {
                            id: spot
                            required property var modelData
                            readonly property bool current: Notifs.prefs.position === modelData.value

                            width: 46; height: 20; radius: 7
                            x: modelData.col === 0 ? 8 : modelData.col === 1 ? (picker.width - width) / 2 : picker.width - width - 8
                            y: modelData.row === 0 ? 8 : picker.height - height - 8
                            color: current ? Qt.rgba(1, 1, 1, 0.7) : (spotArea.containsMouse ? Theme.pillHover : Theme.pill)
                            Behavior on color { ColorAnimation { duration: Theme.animNormal } }

                            MouseArea {
                                id: spotArea
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: Notifs.set("position", spot.modelData.value)
                            }
                        }
                    }
                }
            }

            SettingRow {
                label: "Stay on screen"
                hint: "Hovering pauses them. Critical alerts stay until closed."
                Segmented {
                    options: [3, 5, 8, 12].map(s => ({ label: s + "s", value: s }))
                    value: Notifs.prefs.timeout
                    onPicked: v => Notifs.set("timeout", v)
                }
            }

            SettingRow {
                label: "At most on screen"
                hint: "Older ones make way for new ones"
                Segmented {
                    options: [1, 2, 3, 5].map(n => ({ label: String(n), value: n }))
                    value: Notifs.prefs.maxVisible
                    onPicked: v => Notifs.set("maxVisible", v)
                }
            }

            SettingRow {
                label: "Show message text"
                hint: "Turn off to only show the app and title"
                Toggle { checked: Notifs.prefs.showBody; onToggled: Notifs.set("showBody", !checked) }
            }

            SettingRow {
                label: "Play a sound"
                Toggle { checked: Notifs.prefs.sound; onToggled: Notifs.set("sound", !checked) }
            }

            Item { width: 1; height: 6 }

            PillButton {
                icon: "notifications_active"
                text: "Send test notification"
                onClicked: Notifs.test()
            }
        }
    }
}
