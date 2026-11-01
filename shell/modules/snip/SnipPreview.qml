import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import QtQuick
import "../../theme"
import "../../services"
import "../common"

PanelWindow {
    id: win

    readonly property bool shown: SnipState.shot !== "" && SnipState.shotScreen === screen
    readonly property int cardWidth: Math.min(1180, Math.round(width * 0.64))
    readonly property int pad: 18

    WlrLayershell.namespace: "sparky-snip-preview"
    WlrLayershell.layer: WlrLayer.Overlay
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    visible: shown || card.progress > 0
    mask: Region { item: card }

    BackgroundEffect.blurRegion: card.progress >= 1 ? blur : null
    property Region blur: Region { item: blurArea; radius: Theme.launcherRadius * card.scale }

    Item {
        id: blurArea
        x: card.x + card.width * (1 - card.scale) / 2
        y: card.y + card.height * (1 - card.scale) / 2
        width: card.width * card.scale
        height: card.height * card.scale
    }

    Connections {
        target: SnipState
        function onShotSerialChanged() { if (win.shown) hide.restart() }
    }

    Timer {
        id: hide
        interval: 6000
        running: win.shown && !hover.hovered
        onTriggered: SnipState.dismissShot()
    }

    Timer { id: newSnip; interval: 260; onTriggered: SnipState.start() }

    HoverHandler { id: hover }

    Rectangle {
        id: card

        property real progress: win.shown ? 1 : 0
        Behavior on progress {
            NumberAnimation {
                duration: win.shown ? 280 : 180
                easing.type: win.shown ? Easing.OutQuint : Easing.InCubic
            }
        }

        property string path: ""
        Connections {
            target: SnipState
            function onShotChanged() { if (SnipState.shot !== "") card.path = SnipState.shot }
        }

        width: win.cardWidth
        height: content.implicitHeight + 2 * win.pad
        x: (win.width - width) / 2
        y: (win.height - height) / 2 + (1 - progress) * 20
        opacity: Math.min(1, progress * 1.6)
        scale: 0.94 + 0.06 * progress
        radius: Theme.launcherRadius + 6
        color: Theme.surface

        property bool recopied: false
        Timer { id: recopiedReset; interval: 1600; onTriggered: card.recopied = false }

        Column {
            id: content
            anchors { fill: parent; margins: win.pad }
            spacing: 14

            ClippingRectangle {
                id: frame
                width: parent.width
                height: shot.implicitWidth > 0
                    ? Math.max(200, Math.min(win.height * 0.62, width * shot.implicitHeight / shot.implicitWidth))
                    : 360
                radius: Theme.launcherRadius + 6 - win.pad
                color: Theme.card

                Image {
                    id: shot
                    anchors.fill: parent
                    source: card.path ? "file://" + card.path : ""
                    fillMode: Image.PreserveAspectFit
                    cache: false
                    asynchronous: true
                    smooth: true
                    mipmap: true
                    scale: open.containsMouse ? 1.01 : 1
                    Behavior on scale { NumberAnimation { duration: Theme.animNormal; easing.type: Easing.OutCubic } }
                }

                MouseArea {
                    id: open
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        Quickshell.execDetached(["xdg-open", card.path]);
                        SnipState.dismissShot();
                    }
                }
            }

            Item {
                width: parent.width
                height: buttons.implicitHeight

                Text {
                    anchors { left: parent.left; leftMargin: 4; verticalCenter: parent.verticalCenter }
                    text: card.recopied ? "Copied again" : "Copied to clipboard"
                    color: Theme.fgDim
                    font { family: Theme.font; pixelSize: 13 }
                }

                Row {
                    id: buttons
                    anchors.right: parent.right
                    spacing: 6

                    PillButton {
                        icon: "edit-copy-symbolic"
                        text: "Copy"
                        implicitHeight: 34
                        onClicked: {
                            Quickshell.execDetached(["sh", "-c", 'wl-copy --type image/png < "$1"', "sh", card.path]);
                            card.recopied = true;
                            recopiedReset.restart();
                            hide.restart();
                        }
                    }
                    PillButton {
                        icon: "edit-cut-symbolic"
                        text: "New snip"
                        implicitHeight: 34
                        onClicked: {
                            SnipState.dismissShot();
                            newSnip.restart();
                        }
                    }
                    PillButton {
                        icon: "folder-symbolic"
                        text: "Folder"
                        implicitHeight: 34
                        onClicked: {
                            Quickshell.execDetached(["dbus-send", "--session", "--dest=org.freedesktop.FileManager1",
                                "--type=method_call", "/org/freedesktop/FileManager1",
                                "org.freedesktop.FileManager1.ShowItems",
                                "array:string:file://" + card.path, "string:"]);
                            SnipState.dismissShot();
                        }
                    }
                    PillButton {
                        icon: "edit-delete-symbolic"
                        text: "Delete"
                        implicitHeight: 34
                        onClicked: {
                            Quickshell.execDetached(["rm", "-f", "--", card.path]);
                            SnipState.dismissShot();
                        }
                    }
                    PillButton {
                        icon: "window-close-symbolic"
                        implicitHeight: 34
                        onClicked: SnipState.dismissShot()
                    }
                }
            }
        }
    }
}
