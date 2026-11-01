import QtQuick
import "../../theme"
import "../../services"
import "../common"

Item {
    id: page

    readonly property bool live: visible && SettingsState.open

    onLiveChanged: if (live) Hardware.refresh()

    Flickable {
        anchors.fill: parent
        contentHeight: content.implicitHeight + 32
        clip: true
        boundsBehavior: Flickable.StopAtBounds

    Column {
        id: content
        x: 28; y: 4
        width: page.width - 56
        spacing: 18

        Text {
            text: "Wallpaper"
            color: Theme.fg
            font { family: Theme.font; pixelSize: 22; weight: Font.Medium }
        }

        Item {
            width: parent.width
            height: Math.min(260, width * 9 / 16)

            WallpaperPreview {
                anchors.fill: parent
                radius: 18
                color: Theme.card
                path: Wallpaper.current
                playing: page.live
            }

            Rectangle {
                anchors { left: parent.left; bottom: parent.bottom; margins: 14 }
                height: 32
                width: caption.implicitWidth + 28
                radius: 16
                color: Qt.rgba(0, 0, 0, 0.55)

                Text {
                    id: caption
                    anchors.centerIn: parent
                    text: "Current · " + Wallpaper.kind(Wallpaper.current)
                    color: Theme.fg
                    font { family: Theme.font; pixelSize: 13 }
                }
            }
        }

        Row {
            spacing: 14

            PillButton { text: "Upload wallpaper…"; onClicked: Wallpaper.pick() }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "PNG, JPG, GIF or MP4"
                color: Theme.fgDim
                font { family: Theme.font; pixelSize: 13 }
            }
        }

        Text {
            text: "Previous"
            color: Theme.fgDim
            font { family: Theme.font; pixelSize: 14; weight: Font.Medium }
        }

        Text {
            visible: Wallpaper.history.length === 0
            text: "Wallpapers you switch away from will show up here."
            color: Theme.fgDim
            font { family: Theme.font; pixelSize: 13 }
        }

        ListView {
            width: parent.width
            height: 96
            visible: Wallpaper.history.length > 0
            orientation: ListView.Horizontal
            spacing: 12
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            model: Wallpaper.history

            remove: Transition { NumberAnimation { property: "opacity"; to: 0; duration: 140 } }
            displaced: Transition { NumberAnimation { property: "x"; duration: 200; easing.type: Easing.OutCubic } }

            delegate: Item {
                id: tile
                required property string modelData
                width: 160
                height: 90

                WallpaperPreview {
                    anchors.fill: parent
                    radius: 12
                    color: Theme.card
                    path: tile.modelData
                    playing: page.live
                    scale: ma.containsMouse ? 1.04 : 1
                    Behavior on scale { NumberAnimation { duration: Theme.animNormal; easing.type: Easing.OutCubic } }
                }

                Rectangle {
                    visible: Wallpaper.isMoving(tile.modelData)
                    anchors { right: parent.right; top: parent.top; margins: 6 }
                    width: badge.implicitWidth + 14
                    height: 20
                    radius: 10
                    color: Qt.rgba(0, 0, 0, 0.6)
                    Text {
                        id: badge
                        anchors.centerIn: parent
                        text: Wallpaper.kind(tile.modelData)
                        color: Theme.fg
                        font { family: Theme.font; pixelSize: 11 }
                    }
                }

                MouseArea {
                    id: ma
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: Wallpaper.apply(tile.modelData)
                }

                Rectangle {
                    anchors { left: parent.left; top: parent.top; margins: 6 }
                    width: 22; height: 22; radius: 11
                    opacity: ma.containsMouse || rm.containsMouse ? 1 : 0
                    visible: opacity > 0
                    color: rm.containsMouse ? Qt.rgba(0, 0, 0, 0.8) : Qt.rgba(0, 0, 0, 0.6)
                    Behavior on opacity { NumberAnimation { duration: Theme.animFast } }

                    MaterialIcon {
                        anchors.centerIn: parent
                        size: 15
                        name: "close"
                    }

                    MouseArea {
                        id: rm
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: Wallpaper.forget(tile.modelData)
                    }
                }
            }
        }
        Item {
            z: 5
            width: parent.width
            height: tbTitle.height
            Text {
                id: tbTitle
                topPadding: 14
                text: "Top bar"
                color: Theme.fg
                font { family: Theme.font; pixelSize: 22; weight: Font.Medium }
            }
            Row {
                anchors { right: parent.right; bottom: parent.bottom }
                spacing: 8

                Toggle {
                    anchors.verticalCenter: parent.verticalCenter
                    checked: TopBarConfig.enabled
                    onToggled: TopBarConfig.setEnabled(!TopBarConfig.enabled)
                }

                PillButton {
                    implicitHeight: 38
                    text: "Reset"
                    onClicked: TopBarConfig.reset()
                }
            }
        }

        TopBarEditor {
            width: parent.width
            opacity: TopBarConfig.enabled ? 1 : 0.45
            Behavior on opacity { NumberAnimation { duration: 200 } }
        }

        SettingRow {
            label: "Spacing"
            hint: gapSlider.current + " px between pieces"
            opacity: TopBarConfig.enabled ? 1 : 0.45
            Slider {
                id: gapSlider
                from: 0; to: 24; step: 1
                value: TopBarConfig.spacing
                onMoved: v => TopBarConfig.setSpacing(v)
            }
        }

        Text {
            topPadding: 14
            text: "Display"
            color: Theme.fg
            font { family: Theme.font; pixelSize: 22; weight: Font.Medium }
        }

        Repeater {
            model: Hardware.displays

            Column {
                id: screenBlock
                required property var modelData
                readonly property var screenInfo: modelData
                readonly property var current: modelData.current
                readonly property var sizes: [...new Set(modelData.modes.map(m => m.width + "×" + m.height))]
                property string size: current ? current.width + "×" + current.height : (sizes[0] ?? "")
                readonly property var rates: modelData.modes.filter(m => m.width + "×" + m.height === size)
                width: parent.width
                spacing: 10

                Text {
                    visible: Hardware.displays.length > 1
                    text: screenBlock.screenInfo.model
                    color: Theme.fgDim
                    font { family: Theme.font; pixelSize: 14; weight: Font.Medium }
                }

                SettingRow {
                    label: "Refresh rate"
                    hint: screenBlock.current ? "Now " + Math.round(screenBlock.current.hz) + " Hz on " + screenBlock.screenInfo.name : ""

                    Segmented {
                        itemWidth: 76
                        options: screenBlock.rates.map(m => ({ label: Math.round(m.hz) + " Hz", value: m.id }))
                        value: screenBlock.current?.id ?? ""
                        onPicked: v => Hardware.setMode(screenBlock.screenInfo.name, v)
                    }
                }

                SettingRow {
                    label: "Resolution"
                    hint: "Picks the fastest refresh rate it supports"

                    PillButton {
                        id: sizeButton
                        text: screenBlock.size + "  ▾"
                        onClicked: sizeMenu.visible = !sizeMenu.visible
                    }
                }

                Rectangle {
                    id: sizeMenu
                    visible: false
                    width: parent.width
                    height: sizeFlow.implicitHeight + 24
                    radius: 14
                    color: Theme.card

                    Flow {
                        id: sizeFlow
                        x: 12; y: 12
                        width: parent.width - 24
                        spacing: 8

                        Repeater {
                            model: screenBlock.sizes
                            PillButton {
                                required property string modelData
                                implicitHeight: 34
                                text: modelData
                                color: modelData === screenBlock.size ? Theme.pillHover : Theme.pill
                                onClicked: {
                                    screenBlock.size = modelData;
                                    sizeMenu.visible = false;
                                    const best = screenBlock.rates[0];
                                    if (best) Hardware.setMode(screenBlock.screenInfo.name, best.id);
                                }
                            }
                        }
                    }
                }
            }
        }

        Text {
            visible: Hardware.displays.length === 0
            text: "Looking for screens…"
            color: Theme.fgDim
            font { family: Theme.font; pixelSize: 13 }
        }
    }
    }
}
