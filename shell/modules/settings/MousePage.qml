import Quickshell
import QtQuick
import "../../theme"
import "../../services"
import "../common"

Item {
    id: page

    readonly property bool shown: visible && SettingsState.open
    onShownChanged: if (shown) Hardware.refresh()

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
                text: "Mouse"
                color: Theme.fg
                font { family: Theme.font; pixelSize: 22; weight: Font.Medium }
            }

            Text {
                visible: Hardware.mice.length === 0
                text: "No mouse found"
                color: Theme.fgDim
                font { family: Theme.font; pixelSize: 13 }
            }

            Repeater {
                model: ScriptModel { values: Hardware.mice; objectProp: "sys" }

                Column {
                    id: mouseBlock
                    required property var modelData
                    readonly property var m: modelData
                    width: column.width
                    spacing: 10

                    Row {
                        visible: Hardware.mice.length > 1
                        spacing: 10
                        topPadding: 8
                        MaterialIcon { anchors.verticalCenter: parent.verticalCenter; size: 20; name: "mouse"; color: Theme.fgDim }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: /^\(?BLE\)?$/.test(mouseBlock.m.name) ? "Bluetooth mouse" : mouseBlock.m.name
                            color: Theme.fgDim
                            font { family: Theme.font; pixelSize: 14; weight: Font.Medium }
                        }
                    }

                    SettingRow {
                        label: "Pointer speed"
                        hint: Math.round((speed.current + 1) * 50) + "%"
                        Slider {
                            id: speed
                            from: -1; to: 1; step: 0.01
                            value: mouseBlock.m.pointerAcceleration
                            onMoved: v => Hardware.setMouse(mouseBlock.m.sys, "pointerAcceleration", v)
                        }
                    }

                    SettingRow {
                        label: "Pointer acceleration"
                        hint: "Off is best for games: the pointer moves exactly as far as the mouse"
                        MouseToggle { mouse: mouseBlock.m; setting: "flat"; invert: true; initial: !mouseBlock.m.flat }
                    }

                    SettingRow {
                        label: "Scroll speed"
                        hint: scroll.current.toFixed(1) + "×"
                        Slider {
                            id: scroll
                            from: 0.2; to: 3; step: 0.1
                            value: mouseBlock.m.scrollFactor
                            onMoved: v => Hardware.setMouse(mouseBlock.m.sys, "scrollFactor", v)
                        }
                    }

                    SettingRow {
                        label: "Natural scrolling"
                        hint: "Content follows your finger, like a phone"
                        MouseToggle { mouse: mouseBlock.m; setting: "naturalScroll"; initial: mouseBlock.m.naturalScroll }
                    }

                    SettingRow {
                        label: "Left-handed"
                        hint: "Swap the left and right buttons"
                        MouseToggle { mouse: mouseBlock.m; setting: "leftHanded"; initial: mouseBlock.m.leftHanded }
                    }

                    SettingRow {
                        label: "Middle-click by pressing both buttons"
                        MouseToggle { mouse: mouseBlock.m; setting: "middleEmulation"; initial: mouseBlock.m.middleEmulation }
                    }
                }
            }
        }
    }
}
