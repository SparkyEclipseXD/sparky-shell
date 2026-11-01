import Quickshell
import Quickshell.Widgets
import QtQuick
import "../../theme"
import "../../services"
import "../common"

Item {
    id: slot

    required property var popup
    property int side: 1
    property bool fromBottom: false
    readonly property int gap: 10
    readonly property int pad: 14

    property bool open: false
    property bool cardIn: false
    property int exitDir: side
    property real dragX: 0

    readonly property int timeoutMs: popup.critical ? 0 : Notifs.prefs.timeout * 1000
    property real remaining: 1

    property real slideX: cardIn ? 0 : (popup.leaving ? exitDir : side) * (width + 40)
    property real slideY: cardIn || side !== 0 || exitDir !== 0 ? 0 : -24
    Behavior on slideX { NumberAnimation { duration: slot.cardIn ? 420 : 220; easing.type: slot.cardIn ? Easing.OutQuint : Easing.InCubic } }
    Behavior on slideY { NumberAnimation { duration: slot.cardIn ? 360 : 200; easing.type: slot.cardIn ? Easing.OutQuint : Easing.InCubic } }
    Behavior on dragX { enabled: !touch.pressed; NumberAnimation { duration: 260; easing.type: Easing.OutBack } }

    readonly property Region hitRegion: Region { x: slot.x; y: slot.y + card.y; width: card.width; height: card.height }
    readonly property Region blurRegion: Region {
        x: slot.x; y: slot.y + card.y; width: card.width; height: card.height
        radius: Theme.dockRadius
    }
    readonly property bool settled: cardIn && card.opacity === 1 && slideX === 0 && slideY === 0 && dragX === 0
                                    && Math.abs(height - card.height - gap) < 0.5

    width: Theme.notifWidth
    height: open ? card.height + gap : 0
    Behavior on height { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

    Component.onCompleted: { open = true; enter.start() }

    Timer {
        id: enter
        interval: 140
        onTriggered: {
            if (slot.popup.leaving) return;
            slot.cardIn = true;
            if (slot.timeoutMs > 0) countdown.start();
        }
    }

    Connections {
        target: slot.popup
        function onLeavingChanged() {
            if (!slot.popup.leaving) return;
            enter.stop();
            countdown.stop();
            slot.cardIn = false;
            collapse.start();
        }
        function onRevisionChanged() { if (slot.cardIn && slot.timeoutMs > 0) countdown.restart() }
    }

    Timer { id: collapse; interval: 160; onTriggered: { slot.open = false; done.start() } }
    Timer { id: done; interval: 260; onTriggered: Notifs.remove(slot.popup) }

    NumberAnimation {
        id: countdown
        target: slot
        property: "remaining"
        from: 1; to: 0
        duration: slot.timeoutMs
        paused: running && (hover.hovered || touch.pressed)
        onFinished: Notifs.close(slot.popup, false)
    }

    Rectangle {
        id: card

        readonly property bool hasImage: slot.popup.image !== "" && picture.status !== Image.Error

        width: parent.width
        height: Math.max(icon.height + 2 * slot.pad, texts.y + texts.implicitHeight + slot.pad + 2)
        y: slot.fromBottom ? slot.height - height : 0
        radius: Theme.dockRadius
        color: slot.popup.critical ? Theme.surfaceRaised : Theme.surface
        opacity: slot.cardIn ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: slot.cardIn ? 260 : 180; easing.type: Easing.OutCubic } }
        Behavior on height { enabled: slot.settled; NumberAnimation { duration: Theme.animNormal; easing.type: Easing.OutCubic } }

        transform: Translate { x: slot.slideX + slot.dragX; y: slot.slideY }

        HoverHandler { id: hover }

        MouseArea {
            id: touch
            anchors.fill: parent
            property real startX
            property bool moved: false

            onPressed: mouse => { startX = mapToItem(slot, mouse.x, 0).x; moved = false }
            onPositionChanged: mouse => {
                const dx = mapToItem(slot, mouse.x, 0).x - startX;
                if (Math.abs(dx) > 6) moved = true;
                if (moved) slot.dragX = dx;
            }
            onReleased: {
                if (!moved) {
                    Notifs.activate(slot.popup);
                } else if (Math.abs(slot.dragX) > 100) {
                    slot.exitDir = Math.sign(slot.dragX);
                    slot.slideX = 0;
                    Notifs.close(slot.popup, true);
                } else {
                    slot.dragX = 0;
                }
            }
        }

        Item {
            id: icon
            anchors { left: parent.left; leftMargin: slot.pad; verticalCenter: parent.verticalCenter }
            width: 40; height: 40

            Rectangle {
                anchors.fill: parent
                visible: !card.hasImage && Notifs.isSymbolic(slot.popup)
                radius: 12
                color: Theme.pill
            }

            ClippingRectangle {
                anchors.fill: parent
                visible: card.hasImage
                radius: 10
                color: Theme.card

                Image {
                    id: picture
                    anchors.fill: parent
                    source: slot.popup.image
                    sourceSize: Qt.size(80, 80)
                    fillMode: Image.PreserveAspectCrop
                    smooth: true
                    mipmap: true
                }
            }

            Image {
                visible: card.hasImage && !Notifs.isSymbolic(slot.popup)
                anchors { right: parent.right; bottom: parent.bottom; margins: -4 }
                width: 18; height: 18
                source: Notifs.iconFor(slot.popup)
                sourceSize: Qt.size(36, 36)
                mipmap: true
            }

            SymbolIcon {
                visible: !card.hasImage && Notifs.isSymbolic(slot.popup)
                anchors.centerIn: parent
                size: 22
                name: slot.popup.icon
            }

            FittedIcon {
                visible: !card.hasImage && !Notifs.isSymbolic(slot.popup)
                anchors.centerIn: parent
                width: 34; height: 34
                source: Notifs.iconFor(slot.popup)
            }
        }

        Column {
            id: texts
            anchors { left: icon.right; leftMargin: 12; right: parent.right; rightMargin: slot.pad }
            y: slot.pad - 2
            spacing: 2

            Text {
                width: parent.width - 26
                text: slot.popup.appName
                elide: Text.ElideRight
                color: Theme.fgDim
                font { family: Theme.font; pixelSize: 12 }
            }

            Text {
                visible: text !== ""
                width: parent.width
                text: slot.popup.summary
                wrapMode: Text.Wrap
                maximumLineCount: 2
                elide: Text.ElideRight
                color: Theme.fg
                font { family: Theme.font; pixelSize: Theme.fontSize; weight: Font.Medium }
            }

            Text {
                visible: Notifs.prefs.showBody && text !== ""
                width: parent.width
                text: slot.popup.body
                textFormat: Text.StyledText
                wrapMode: Text.Wrap
                maximumLineCount: 4
                elide: Text.ElideRight
                color: Qt.rgba(1, 1, 1, 0.72)
                linkColor: Theme.fg
                font { family: Theme.font; pixelSize: 13 }
                onLinkActivated: link => Qt.openUrlExternally(link)
            }

            Flow {
                visible: slot.popup.actions.length > 0
                width: parent.width
                topPadding: 8
                spacing: 6

                Repeater {
                    model: slot.popup.actions

                    PillButton {
                        required property var modelData
                        implicitHeight: 30
                        text: modelData.text
                        onClicked: Notifs.invoke(slot.popup, modelData)
                    }
                }
            }
        }

        Rectangle {
            x: card.width - width - 10; y: 10
            width: 26; height: 26; radius: 13
            opacity: hover.hovered ? 1 : 0
            visible: opacity > 0
            color: closeArea.containsMouse ? Theme.pillHover : Theme.pill
            Behavior on opacity { NumberAnimation { duration: Theme.animFast } }
            Behavior on color { ColorAnimation { duration: Theme.animFast } }

            SymbolIcon {
                anchors.centerIn: parent
                size: 12
                name: "window-close-symbolic"
            }

            MouseArea {
                id: closeArea
                anchors.fill: parent
                hoverEnabled: true
                onClicked: Notifs.close(slot.popup, true)
            }
        }

        Rectangle {
            visible: slot.timeoutMs > 0
            anchors { bottom: parent.bottom; bottomMargin: 5; left: parent.left; leftMargin: Theme.dockRadius }
            width: (card.width - 2 * Theme.dockRadius) * slot.remaining
            height: 2
            radius: 1
            color: Qt.rgba(1, 1, 1, 0.22)
        }
    }
}
