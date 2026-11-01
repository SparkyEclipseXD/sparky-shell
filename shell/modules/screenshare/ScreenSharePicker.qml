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

    property var request: null
    readonly property bool shown: request !== null
    property string tab: "screens"
    property int current: 0

    readonly property var screens: Quickshell.screens.map(s => ({
        key: s.x + "x" + s.y, name: s.name, label: s.model || s.name,
        size: s.width + " × " + s.height
    }))
    readonly property var windows: Windows.list.map(w => ({
        key: w.id, appId: w.appId, cls: w.cls, title: w.caption,
        label: DesktopEntries.heuristicLookup(w.appId)?.name ?? w.appId
    }))
    readonly property var items: tab === "screens" ? screens : windows

    function open(req) {
        if (request) answer({ cancel: true });
        tab = req.monitors || !req.windows ? "screens" : "windows";
        current = 0;
        request = req;
    }

    function answer(result) {
        if (!request) return;
        Quickshell.execDetached(["qdbus6", "org.freedesktop.impl.portal.desktop.sparky", "/org/freedesktop/portal/desktop",
                                 "org.sparky.ScreenShare.Answer", String(request.id), JSON.stringify(result)]);
        request = null;
    }

    function share() {
        const it = items[current];
        if (!it) return;
        if (tab === "screens") answer({ outputs: [it.key] });
        else answer({ windows: [[it.appId, it.title]] });
    }

    IpcHandler {
        target: "screenshare"
        function open(json: string): void {
            try { win.open(JSON.parse(json)) } catch (e) { console.warn("screenshare: bad request", e) }
        }
    }

    WlrLayershell.namespace: "sparky-screenshare"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: shown ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    visible: shown || progress > 0

    property real progress: shown ? 1 : 0
    Behavior on progress {
        NumberAnimation { duration: win.shown ? 320 : 180; easing.type: win.shown ? Easing.OutQuint : Easing.InCubic }
    }

    BackgroundEffect.blurRegion: progress >= 1 ? blur : null
    property Region blur: Region { item: card; radius: card.radius }

    onShownChanged: if (shown) keys.forceActiveFocus()

    Rectangle {
        anchors.fill: parent
        color: "black"
        opacity: 0.42 * win.progress
        MouseArea { anchors.fill: parent; onClicked: win.answer({ cancel: true }) }
    }

    Item {
        id: keys
        focus: true
        Keys.onPressed: event => {
            const n = win.items.length;
            if (event.key === Qt.Key_Escape) win.answer({ cancel: true });
            else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) win.share();
            else if (event.key === Qt.Key_Right || event.key === Qt.Key_Tab) win.current = Math.min(n - 1, win.current + 1);
            else if (event.key === Qt.Key_Left || event.key === Qt.Key_Backtab) win.current = Math.max(0, win.current - 1);
            else if (event.key === Qt.Key_Down) win.current = Math.min(n - 1, win.current + grid.columns);
            else if (event.key === Qt.Key_Up) win.current = Math.max(0, win.current - grid.columns);
            else return;
            event.accepted = true;
        }
    }

    Rectangle {
        id: card

        readonly property int pad: 26

        anchors.centerIn: parent
        anchors.verticalCenterOffset: (1 - win.progress) * 28
        width: 780
        height: content.implicitHeight + 2 * pad
        radius: 30
        color: Theme.surface
        opacity: Math.min(1, win.progress * 1.6)
        scale: 0.93 + 0.07 * win.progress
        Behavior on height { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

        MouseArea { anchors.fill: parent }

        Column {
            id: content
            x: card.pad
            y: card.pad
            width: card.width - 2 * card.pad
            spacing: 18

            Row {
                spacing: 14

                Rectangle {
                    width: 48; height: 48; radius: 16
                    color: Theme.pillHover
                    MaterialIcon { anchors.centerIn: parent; size: 26; name: "screen_share"; fill: 1 }
                }

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2
                    Text {
                        text: "Share your screen"
                        color: Theme.fg
                        font { family: Theme.font; pixelSize: 18; weight: Font.Medium }
                    }
                    Text {
                        text: (win.request?.app || "An app") + " wants to see what's on your screen"
                        color: Theme.fgDim
                        font { family: Theme.font; pixelSize: 13 }
                    }
                }
            }

            Segmented {
                visible: (win.request?.monitors ?? false) && (win.request?.windows ?? false)
                itemWidth: 110
                options: [{ label: "Screens", value: "screens" }, { label: "Windows", value: "windows" }]
                value: win.tab
                onPicked: v => { win.tab = v; win.current = 0; }
            }

            GridView {
                id: grid
                readonly property int columns: 3
                width: parent.width
                height: Math.min(2, Math.ceil(count / columns)) * cellHeight
                cellWidth: width / columns
                cellHeight: 186
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                model: ScriptModel { values: win.items; objectProp: "key" }
                currentIndex: win.current

                add: Transition {
                    NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 180 }
                    NumberAnimation { property: "scale"; from: 0.92; to: 1; duration: 220; easing.type: Easing.OutCubic }
                }

                delegate: Item {
                    id: cell
                    required property var modelData
                    required property int index
                    readonly property bool selected: index === win.current
                    width: grid.cellWidth
                    height: grid.cellHeight

                    Rectangle {
                        id: tile
                        anchors { fill: parent; margins: 6 }
                        radius: 20
                        color: cell.selected ? Theme.pillHover : (area.containsMouse ? Qt.rgba(1, 1, 1, 0.08) : Theme.card)
                        border { width: cell.selected ? 2 : 0; color: Theme.fg }
                        Behavior on color { ColorAnimation { duration: Theme.animFast } }

                        ClippingRectangle {
                            id: preview
                            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 10 }
                            height: 112
                            radius: 13
                            color: Qt.rgba(0, 0, 0, 0.3)

                            Image {
                                anchors.fill: parent
                                visible: win.tab === "screens"
                                source: visible ? Wallpaper.previewFor(Wallpaper.current) : ""
                                sourceSize: Qt.size(440, 250)
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                            }

                            FittedIcon {
                                anchors.centerIn: parent
                                visible: win.tab === "windows"
                                width: 56; height: 56
                                source: visible ? Icons.find(DesktopEntries.heuristicLookup(cell.modelData.appId), cell.modelData.appId, cell.modelData.cls) : ""
                            }
                        }

                        Column {
                            anchors { left: parent.left; right: parent.right; top: preview.bottom; margins: 12; topMargin: 10 }
                            spacing: 1

                            Text {
                                width: parent.width
                                text: win.tab === "screens" ? cell.modelData.label : cell.modelData.title
                                elide: Text.ElideRight
                                color: Theme.fg
                                font { family: Theme.font; pixelSize: 14; weight: Font.Medium }
                            }
                            Text {
                                width: parent.width
                                text: win.tab === "screens" ? cell.modelData.size : cell.modelData.label
                                elide: Text.ElideRight
                                color: Theme.fgDim
                                font { family: Theme.font; pixelSize: 12 }
                            }
                        }

                        MouseArea {
                            id: area
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: win.current = cell.index
                            onDoubleClicked: { win.current = cell.index; win.share(); }
                        }
                    }
                }
            }

            Text {
                visible: win.items.length === 0
                text: win.tab === "screens" ? "No screens found" : "No windows open"
                color: Theme.fgDim
                font { family: Theme.font; pixelSize: 13 }
            }

            Item {
                width: parent.width
                height: 40

                Row {
                    anchors.right: parent.right
                    spacing: 8

                    PillButton {
                        implicitHeight: 40
                        text: "Cancel"
                        onClicked: win.answer({ cancel: true })
                    }

                    Rectangle {
                        readonly property bool ready: win.items.length > 0
                        width: shareLabel.implicitWidth + 44
                        height: 40
                        radius: 20
                        color: ready ? (shareArea.pressed ? Qt.rgba(1, 1, 1, 0.8) : Theme.fg) : Theme.pill
                        Behavior on color { ColorAnimation { duration: Theme.animNormal } }

                        Text {
                            id: shareLabel
                            anchors.centerIn: parent
                            text: "Share"
                            color: parent.ready ? "black" : Theme.fgDim
                            font { family: Theme.font; pixelSize: 14; weight: Font.Medium }
                        }

                        MouseArea {
                            id: shareArea
                            anchors.fill: parent
                            onClicked: win.share()
                        }
                    }
                }
            }
        }
    }
}
