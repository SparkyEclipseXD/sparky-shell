import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import Quickshell.Wayland
import QtQuick
import "../../theme"
import "../../services"
import "../common"

PanelWindow {
    id: win

    property bool shown: false
    property int current: 0
    property bool renaming: false
    property int steps: 0

    property var dragWin: null
    property string dragIcon: ""
    property point dragPos
    property int dropIndex: -1
    property point dragFrom

    function drop(sourceIndex) {
        const target = desktops[dropIndex];
        const moving = target && dropIndex !== sourceIndex;
        const tile = moving ? row.itemAtIndex(dropIndex) : null;
        landing.to = tile ? tile.mapToItem(card, tile.width / 2, card.ring + card.tileH / 2) : dragFrom;
        landing.windowId = moving ? dragWin.id : "";
        landing.desktopId = moving ? target.id : "";
        landing.restart();
    }

    readonly property var desktops: Windows.desktops
    readonly property int count: desktops.length

    function open(step) {
        if (!shown) {
            current = Math.max(0, desktops.findIndex(d => d.id === Windows.currentDesktop));
            steps = 0;
            shown = true;
            return;
        }
        move(step);
        steps++;
    }
    function move(step) { if (count > 0) current = (current + step + count) % count }
    function close() { shown = false; renaming = false; dragWin = null; dropIndex = -1; }
    function choose(i) {
        const d = desktops[i];
        close();
        if (d && d.id !== Windows.currentDesktop) {
            pendingSwitch = d.id;
            switchLater.restart();
        }
    }

    property string pendingSwitch: ""
    Timer {
        id: switchLater
        interval: 150
        onTriggered: Windows.switchDesktop(win.pendingSwitch)
    }
    function remove(i) {
        if (count <= 1 || !desktops[i]) return;
        Windows.removeDesktop(desktops[i].id);
        if (current >= count - 1) current = Math.max(0, count - 2);
    }

    IpcHandler {
        target: "workspaces"
        function next(): void { win.open(1) }
        function prev(): void { win.open(-1) }
        function toggle(): void { win.shown ? win.close() : win.open(0) }
    }

    WlrLayershell.namespace: "sparky-workspaces"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: shown ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    visible: shown || progress > 0

    property real progress: shown ? 1 : 0
    Behavior on progress {
        NumberAnimation { duration: win.shown ? 300 : 170; easing.type: win.shown ? Easing.OutQuint : Easing.InCubic }
    }

    BackgroundEffect.blurRegion: progress >= 1 ? blur : null
    property Region blur: Region { item: card; radius: card.radius }

    onShownChanged: if (shown) keys.forceActiveFocus()

    Rectangle {
        anchors.fill: parent
        color: "black"
        opacity: 0.38 * win.progress
        MouseArea { anchors.fill: parent; onClicked: win.close() }
    }

    Item {
        id: keys
        focus: true

        Keys.onPressed: event => {
            if (win.renaming) return;
            const k = event.key, shift = event.modifiers & Qt.ShiftModifier;
            if (k === Qt.Key_Escape) win.close();
            else if (k === Qt.Key_Backtab || (k === Qt.Key_Tab && shift)) { win.move(-1); win.steps++; }
            else if (k === Qt.Key_Tab) { win.move(1); win.steps++; }
            else if (k === Qt.Key_Left) win.move(-1);
            else if (k === Qt.Key_Right) win.move(1);
            else if (k === Qt.Key_Return || k === Qt.Key_Enter || k === Qt.Key_Space) win.choose(win.current);
            else if (k === Qt.Key_Q || k === Qt.Key_Delete) win.remove(win.current);
            else if (k === Qt.Key_N || k === Qt.Key_Plus) Windows.addDesktop();
            else if (k >= Qt.Key_1 && k <= Qt.Key_9 && k - Qt.Key_1 < win.count) win.choose(k - Qt.Key_1);
            else return;
            event.accepted = true;
        }
        Keys.onReleased: event => {
            if (!win.renaming && win.steps > 0 && !win.dragWin && (event.key === Qt.Key_Meta || event.key === Qt.Key_Super_L || event.key === Qt.Key_Super_R)) {
                win.choose(win.current);
                event.accepted = true;
            }
        }
    }

    Rectangle {
        id: card

        readonly property int pad: 16
        readonly property real ratio: (win.screen?.width ?? 16) / (win.screen?.height ?? 9)
        readonly property int tileW: 240
        readonly property int tileH: Math.round(tileW / ratio)
        readonly property int ring: 7

        anchors.centerIn: parent
        anchors.verticalCenterOffset: (1 - win.progress) * 24
        width: Math.min(row.contentWidth + 2 * ring, win.width - 120) + 2 * pad - 2 * ring
        height: tileH + 44 + 2 * pad
        radius: 28
        color: Theme.surface
        opacity: Math.min(1, win.progress * 1.6)
        scale: 0.94 + 0.06 * win.progress
        Behavior on width { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

        MouseArea { anchors.fill: parent }

        Rectangle {
            z: 5
            readonly property Item at: row.currentItem
            x: row.x + (at ? at.x - row.contentX : 0) - 4
            y: row.y + card.ring - 4
            width: card.tileW + 8
            height: card.tileH + 8
            radius: 20
            color: "transparent"
            border { width: 2; color: Theme.fg }
            visible: at !== null
            opacity: win.dragWin ? 0 : 1
            Behavior on x { enabled: win.progress >= 1; NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }
            Behavior on opacity { NumberAnimation { duration: 140 } }
        }

        FittedIcon {
            id: ghost
            z: 10
            visible: win.dragWin !== null
            property point at: win.dragPos
            x: at.x - width / 2
            y: at.y - height / 2
            width: 44; height: 44
            source: win.dragIcon
            scale: visible && !landing.running ? 1.2 : 0.9
            Behavior on at { enabled: !landing.running; PropertyAnimation { duration: 90; easing.type: Easing.OutCubic } }
            Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutBack } }
        }

        SequentialAnimation {
            id: landing
            property point to
            property string windowId
            property string desktopId
            ParallelAnimation {
                PropertyAnimation { target: ghost; property: "at"; to: landing.to; duration: 260; easing.type: Easing.OutCubic }
                NumberAnimation { target: ghost; property: "opacity"; to: 0; duration: 260; easing.type: Easing.InQuad }
            }
            ScriptAction {
                script: {
                    if (landing.windowId) Windows.moveToDesktop(landing.windowId, landing.desktopId);
                    win.dragWin = null;
                    win.dropIndex = -1;
                    ghost.opacity = 1;
                }
            }
        }

        ListView {
            id: row
            x: card.pad - card.ring
            y: card.pad - card.ring
            width: card.width - 2 * (card.pad - card.ring)
            height: card.tileH + 44 + card.ring
            leftMargin: card.ring
            rightMargin: card.ring
            orientation: ListView.Horizontal
            spacing: 14
            interactive: contentWidth > width
            boundsBehavior: Flickable.StopAtBounds
            currentIndex: win.current
            highlightFollowsCurrentItem: false
            highlightRangeMode: ListView.ApplyRange
            preferredHighlightBegin: 0
            preferredHighlightEnd: width
            highlightMoveDuration: 220
            clip: true

            model: ScriptModel { values: win.desktops; objectProp: "id" }

            add: Transition {
                NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 200 }
                NumberAnimation { property: "scale"; from: 0.85; to: 1; duration: 260; easing.type: Easing.OutBack }
            }
            remove: Transition {
                NumberAnimation { property: "opacity"; to: 0; duration: 160; easing.type: Easing.InCubic }
                NumberAnimation { property: "scale"; to: 0.85; duration: 160; easing.type: Easing.InCubic }
            }
            displaced: Transition { NumberAnimation { properties: "x"; duration: 220; easing.type: Easing.OutCubic } }

            delegate: Item {
                id: tile
                required property var modelData
                required property int index
                readonly property bool selected: index === win.current
                readonly property bool isCurrent: modelData.id === Windows.currentDesktop
                readonly property bool dropTarget: win.dragWin !== null && win.dropIndex === index
                readonly property var windows: Windows.onDesktop(modelData.id)
                    .filter(w => !w.minimized)
                    .sort((a, b) => a.z - b.z)

                width: card.tileW
                height: card.tileH + 44 + card.ring

                Item {
                    id: screenBox
                    y: card.ring
                    width: card.tileW
                    height: card.tileH
                    scale: tile.dropTarget ? 1.04 : tile.selected ? 1 : 0.95
                    opacity: tile.selected || tile.dropTarget ? 1 : 0.78
                    Behavior on scale { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }
                    Behavior on opacity { NumberAnimation { duration: 240 } }

                    ClippingRectangle {
                        anchors.fill: parent
                        radius: 16
                        color: Theme.card

                        Image {
                            anchors.fill: parent
                            source: Wallpaper.previewFor(Wallpaper.current)
                            sourceSize: Qt.size(card.tileW * 2, card.tileH * 2)
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                        }

                        Rectangle {
                            anchors.fill: parent
                            color: Qt.rgba(0, 0, 0, tile.dropTarget ? 0.15 : 0.32)
                            Behavior on color { ColorAnimation { duration: 140 } }
                        }

                        Flow {
                            anchors.centerIn: parent
                            add: Transition {
                                NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 200 }
                                NumberAnimation { property: "scale"; from: 0.4; to: 1; duration: 280; easing.type: Easing.OutBack }
                            }
                            move: Transition {
                                NumberAnimation { properties: "x,y"; duration: 240; easing.type: Easing.OutCubic }
                            }
                            width: Math.min(parent.width - 24, tile.windows.length * 52 - 8)
                            spacing: 8

                            Repeater {
                                model: tile.windows

                                Item {
                                    id: app
                                    required property var modelData
                                    readonly property string icon: Icons.find(DesktopEntries.heuristicLookup(modelData.appId), modelData.appId, modelData.cls)
                                    readonly property bool lifted: win.dragWin !== null && win.dragWin.id === modelData.id
                                    width: 44; height: 44

                                    Rectangle {
                                        anchors.fill: parent
                                        radius: 12
                                        color: appArea.containsMouse && !win.dragWin ? Qt.rgba(1, 1, 1, 0.18) : "transparent"
                                        Behavior on color { ColorAnimation { duration: Theme.animFast } }
                                    }

                                    FittedIcon {
                                        anchors.centerIn: parent
                                        width: 34; height: 34
                                        source: app.icon
                                        opacity: app.lifted ? 0.25 : 1
                                        Behavior on opacity { NumberAnimation { duration: 140 } }
                                    }

                                    MouseArea {
                                        id: appArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.ArrowCursor
                                        property point start
                                        property bool moved: false

                                        onPressed: mouse => { start = Qt.point(mouse.x, mouse.y); moved = false; }
                                        onPositionChanged: mouse => {
                                            if (!pressed) return;
                                            if (!moved && Math.hypot(mouse.x - start.x, mouse.y - start.y) > 6) {
                                                moved = true;
                                                win.dragWin = app.modelData;
                                                win.dragFrom = mapToItem(card, width / 2, height / 2);
                                                win.dragPos = win.dragFrom;
                                                win.dragIcon = app.icon;
                                            }
                                            if (!moved) return;
                                            win.dragPos = mapToItem(card, mouse.x, mouse.y);
                                            const p = mapToItem(row.contentItem, mouse.x, mouse.y);
                                            win.dropIndex = row.indexAt(p.x, p.y);
                                        }
                                        onReleased: {
                                            if (moved) win.drop(tile.index);
                                        }
                                        onClicked: {
                                            if (moved) return;
                                            const id = app.modelData.id;
                                            win.choose(tile.index);
                                            Windows.activate(id);
                                        }
                                    }
                                }
                            }
                        }

                        Text {
                            anchors.centerIn: parent
                            visible: tile.windows.length === 0
                            text: "Empty"
                            color: Theme.fgDim
                            font { family: Theme.font; pixelSize: 13 }
                        }
                    }

                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: -4
                        radius: 20
                        color: "transparent"
                        border { width: 2; color: Theme.fg }
                        opacity: tile.dropTarget ? 1 : 0
                        Behavior on opacity { NumberAnimation { duration: 180 } }
                    }

                    Rectangle {
                        readonly property bool show: win.count > 1 && (tileArea.containsMouse || closeArea.containsMouse || tile.selected)
                        anchors { top: parent.top; right: parent.right; margins: 6 }
                        width: 26; height: 26; radius: 13
                        enabled: !win.dragWin
                        color: closeArea.containsMouse ? Qt.rgba(0.85, 0.2, 0.2, 0.9) : Qt.rgba(0, 0, 0, 0.6)
                        opacity: show ? 1 : 0
                        scale: show ? 1 : 0.6
                        visible: opacity > 0
                        z: 2
                        Behavior on opacity { NumberAnimation { duration: 140 } }
                        Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutBack } }
                        Behavior on color { ColorAnimation { duration: 110 } }

                        MaterialIcon { anchors.centerIn: parent; size: 16; name: "close" }

                        MouseArea {
                            id: closeArea
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: win.remove(tile.index)
                        }
                    }
                }

                MouseArea {
                    id: tileArea
                    anchors.fill: screenBox
                    z: -1
                    hoverEnabled: true
                    onEntered: if (!win.dragWin) win.current = tile.index
                    onClicked: win.choose(tile.index)
                }

                Row {
                    anchors { horizontalCenter: parent.horizontalCenter; top: screenBox.bottom; topMargin: 14 }
                    spacing: 7

                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        visible: tile.isCurrent
                        width: 6; height: 6; radius: 3
                        color: Theme.fg
                    }

                    TextInput {
                        id: nameField
                        anchors.verticalCenter: parent.verticalCenter
                        text: /^(undefined|null)?$/.test(tile.modelData.name || "") ? "Desktop " + (tile.index + 1) : tile.modelData.name
                        readOnly: !activeFocus
                        color: tile.selected ? Theme.fg : Theme.fgDim
                        selectionColor: Qt.rgba(1, 1, 1, 0.25)
                        font { family: Theme.font; pixelSize: 14; weight: tile.selected ? Font.Medium : Font.Normal }
                        onActiveFocusChanged: {
                            win.renaming = activeFocus;
                            if (!activeFocus) text = Qt.binding(() => /^(undefined|null)?$/.test(tile.modelData.name || "")
                                                                ? "Desktop " + (tile.index + 1) : tile.modelData.name);
                        }
                        onAccepted: {
                            if (text.trim()) Windows.renameDesktop(tile.modelData.id, text.trim());
                            keys.forceActiveFocus();
                        }
                        Keys.onEscapePressed: keys.forceActiveFocus()

                        MouseArea {
                            anchors.fill: parent
                            enabled: !nameField.activeFocus
                            onClicked: win.choose(tile.index)
                            onDoubleClicked: { nameField.forceActiveFocus(); nameField.selectAll(); }
                        }
                    }
                }
            }

            footer: Item {
                width: card.tileW * 0.42 + row.spacing
                height: card.tileH + card.ring

                Rectangle {
                    x: row.spacing
                    y: card.ring
                    width: card.tileW * 0.42
                    height: card.tileH
                    radius: 16
                    color: addArea.containsMouse ? Theme.pillHover : Theme.pill
                    scale: addArea.pressed ? 0.95 : 1
                    Behavior on color { ColorAnimation { duration: Theme.animFast } }
                    Behavior on scale { NumberAnimation { duration: Theme.animFast } }

                    MaterialIcon { anchors.centerIn: parent; size: 30; name: "add"; color: addArea.containsMouse ? Theme.fg : Theme.fgDim }

                    MouseArea {
                        id: addArea
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: Windows.addDesktop()
                    }
                }
            }
        }
    }
}
