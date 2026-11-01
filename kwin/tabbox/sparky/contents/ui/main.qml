import QtQuick
import org.kde.plasma.core as PlasmaCore
import org.kde.kwin as KWin
import org.kde.kirigami as Kirigami

KWin.TabBoxSwitcher {
    id: tabBox

    readonly property color surface: Qt.rgba(0.02, 0.02, 0.03, 0.88)
    readonly property color pill: Qt.rgba(1, 1, 1, 0.07)
    readonly property color pillHover: Qt.rgba(1, 1, 1, 0.15)
    readonly property color fg: "#f2f2f2"
    readonly property color fgDim: Qt.rgba(1, 1, 1, 0.55)
    readonly property string font: "Google Sans Flex"

    Instantiator {
        active: tabBox.visible
        delegate: PlasmaCore.Dialog {
            location: PlasmaCore.Types.Floating
            backgroundHints: PlasmaCore.Dialog.NoBackground
            visible: true
            flags: Qt.ToolTip | Qt.X11BypassWindowManagerHint
            x: tabBox.screenGeometry.x + (tabBox.screenGeometry.width - card.width) / 2
            y: tabBox.screenGeometry.y + (tabBox.screenGeometry.height - card.height) / 2

            mainItem: Rectangle {
                id: card

                readonly property int pad: 14
                readonly property real screenRatio: tabBox.screenGeometry.width / tabBox.screenGeometry.height
                readonly property int cellWidth: 220
                readonly property int thumbHeight: Math.round((cellWidth - 2 * 10) / screenRatio)
                readonly property int cellHeight: thumbHeight + 48
                readonly property int maxWidth: tabBox.screenGeometry.width * 0.9

                width: Math.max(cellWidth, Math.min(list.count * (cellWidth + list.spacing) - list.spacing, maxWidth)) + 2 * pad
                height: cellHeight + 2 * pad
                radius: 22
                color: tabBox.surface
                focus: true

                opacity: 0
                scale: 0.94
                Component.onCompleted: { opacity = 1; scale = 1; }
                Behavior on opacity { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
                Behavior on scale { NumberAnimation { duration: 240; easing.type: Easing.OutQuint } }
                Behavior on width { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                ListView {
                    id: list
                    anchors { fill: parent; margins: card.pad }
                    orientation: ListView.Horizontal
                    spacing: 6
                    clip: true

                    remove: Transition {
                        NumberAnimation { property: "opacity"; to: 0; duration: 160; easing.type: Easing.InCubic }
                        NumberAnimation { property: "scale"; to: 0.85; duration: 160; easing.type: Easing.InCubic }
                    }
                    displaced: Transition {
                        NumberAnimation { properties: "x"; duration: 220; easing.type: Easing.OutCubic }
                    }
                    focus: true
                    keyNavigationWraps: true
                    boundsBehavior: Flickable.StopAtBounds
                    model: tabBox.model
                    currentIndex: tabBox.currentIndex
                    onCurrentIndexChanged: tabBox.currentIndex = currentIndex

                    highlightFollowsCurrentItem: false
                    highlight: Rectangle {
                        x: list.currentItem ? list.currentItem.x : 0
                        width: card.cellWidth
                        height: card.cellHeight
                        radius: 16
                        color: tabBox.pillHover
                        Behavior on x { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                    }
                    preferredHighlightBegin: 0
                    preferredHighlightEnd: width
                    highlightRangeMode: ListView.ApplyRange
                    highlightMoveDuration: 220
                    highlightMoveVelocity: -1

                    delegate: MouseArea {
                        id: cell
                        required property int index
                        required property var model
                        width: card.cellWidth
                        height: card.cellHeight
                        hoverEnabled: true
                        onClicked: tabBox.model.activate(index)

                        Rectangle {
                            anchors.fill: parent
                            radius: 16
                            color: tabBox.pill
                            opacity: cell.containsMouse && !cell.ListView.isCurrentItem ? 1 : 0
                            Behavior on opacity { NumberAnimation { duration: 110 } }
                        }

                        Item {
                            id: thumbBox
                            anchors { top: parent.top; left: parent.left; right: parent.right; margins: 10 }
                            height: card.thumbHeight
                            scale: cell.ListView.isCurrentItem ? 1 : 0.93
                            opacity: cell.ListView.isCurrentItem ? 1 : 0.7
                            Behavior on scale { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                            Behavior on opacity { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

                            KWin.WindowThumbnail {
                                anchors.fill: parent
                                wId: cell.model.windowId
                            }
                        }

                        Rectangle {
                            id: closeButton
                            readonly property bool shown: cell.model.closeable
                                && (cell.containsMouse || cell.ListView.isCurrentItem)
                            anchors { top: parent.top; right: parent.right; margins: 4 }
                            width: 28; height: 28; radius: 14
                            color: closeArea.containsMouse ? Qt.rgba(0.85, 0.2, 0.2, 0.9) : Qt.rgba(0.02, 0.02, 0.03, 0.82)
                            opacity: shown ? 1 : 0
                            scale: shown ? 1 : 0.6
                            visible: opacity > 0
                            Behavior on opacity { NumberAnimation { duration: 140 } }
                            Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutBack } }
                            Behavior on color { ColorAnimation { duration: 110 } }

                            Kirigami.Icon {
                                anchors.centerIn: parent
                                width: 14; height: 14
                                source: "window-close-symbolic"
                                color: tabBox.fg
                                isMask: true
                            }

                            MouseArea {
                                id: closeArea
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: tabBox.model.close(cell.index)
                            }
                        }

                        Row {
                            anchors {
                                top: thumbBox.bottom; topMargin: 10
                                horizontalCenter: parent.horizontalCenter
                            }
                            width: Math.min(implicitWidth, parent.width - 20)
                            spacing: 8

                            Kirigami.Icon {
                                id: appIcon
                                width: 20; height: 20
                                anchors.verticalCenter: parent.verticalCenter
                                source: cell.model.icon
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                width: Math.min(implicitWidth, cell.width - 20 - appIcon.width - 8)
                                text: cell.model.caption
                                textFormat: Text.PlainText
                                elide: Text.ElideRight
                                color: cell.ListView.isCurrentItem ? tabBox.fg : tabBox.fgDim
                                font { family: tabBox.font; pixelSize: 13 }
                                Behavior on color { ColorAnimation { duration: 220 } }
                            }
                        }
                    }
                }

                Text {
                    anchors.centerIn: parent
                    visible: list.count === 0
                    text: "No open windows"
                    color: tabBox.fgDim
                    font { family: tabBox.font; pixelSize: 14 }
                }

                Keys.onPressed: event => {
                    if (event.key === Qt.Key_Left) list.decrementCurrentIndex();
                    else if (event.key === Qt.Key_Right) list.incrementCurrentIndex();
                    else if (event.key === Qt.Key_Q || event.key === Qt.Key_Delete) {
                        if (list.currentIndex >= 0) tabBox.model.close(list.currentIndex);
                    }
                    else return;
                    event.accepted = true;
                }
            }

            onSceneGraphError: () => {
            }
        }
    }
}
