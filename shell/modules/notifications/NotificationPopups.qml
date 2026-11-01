import Quickshell
import Quickshell.Wayland
import QtQuick
import "../../theme"
import "../../services"

PanelWindow {
    id: win

    readonly property string position: Notifs.prefs.position
    readonly property bool atBottom: position.startsWith("bottom")
    readonly property int side: position.endsWith("right") ? 1 : position.endsWith("left") ? -1 : 0

    property var cards: []

    screen: Quickshell.screens[0]
    WlrLayershell.namespace: "sparky-notifications"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Normal
    color: "transparent"
    visible: Notifs.popups.length > 0

    mask: Region { regions: win.cards.map(c => c.hitRegion) }
    BackgroundEffect.blurRegion: Region { regions: win.cards.filter(c => c.settled).map(c => c.blurRegion) }

    Repeater {
        id: stack
        model: ScriptModel { values: Notifs.popups }

        NotificationCard {
            id: card
            required property var modelData
            required property int index

            popup: modelData
            side: win.side
            fromBottom: win.atBottom

            readonly property real offset: {
                let sum = 0;
                for (let i = 0; i < index && i < stack.count; i++)
                    sum += stack.itemAt(i)?.height ?? 0;
                return sum;
            }

            x: win.side === 1 ? win.width - width - Theme.dockMargin
             : win.side === -1 ? Theme.dockMargin
             : (win.width - width) / 2
            y: win.atBottom ? win.height - Theme.dockMargin - offset - height : Theme.dockMargin + offset

            Component.onCompleted: win.cards = [...win.cards, card]
            Component.onDestruction: win.cards = win.cards.filter(c => c !== card)
        }
    }
}
