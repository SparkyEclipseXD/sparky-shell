import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import QtQuick
import "../../theme"
import "../../services"
import "../common"
import "../launcher"

PanelWindow {
    id: win

    property var request: null
    readonly property bool shown: request !== null
    property int current: 0
    property string query: ""

    readonly property var apps: {
        if (!request) return [];
        const list = [];
        for (const id of request.choices) {
            const entry = DesktopEntries.byId(id) ?? DesktopEntries.heuristicLookup(id);
            if (entry && !list.some(a => a.id === id)) list.push({ id, entry, name: entry.name || id });
        }
        list.sort((a, b) => (b.id === request.last) - (a.id === request.last) || a.name.localeCompare(b.name));
        return list;
    }
    readonly property var shownApps: {
        const q = query.trim().toLowerCase();
        return q ? apps.filter(a => a.name.toLowerCase().includes(q) || a.id.toLowerCase().includes(q)) : apps;
    }

    function open(req) {
        if (request) answer({ cancel: true });
        query = "";
        search.text = "";
        current = 0;
        request = req;
    }

    function answer(result) {
        if (!request) return;
        Quickshell.execDetached(["qdbus6", "org.freedesktop.impl.portal.desktop.sparky", "/org/freedesktop/portal/desktop",
                                 "org.sparky.ScreenShare.Answer", String(request.id), JSON.stringify(result)]);
        request = null;
    }

    function choose() {
        const app = shownApps[current];
        if (app) answer({ choice: app.id });
    }

    IpcHandler {
        target: "appchooser"
        function open(json: string): void {
            try { win.open(JSON.parse(json)) } catch (e) { console.warn("appchooser: bad request", e) }
        }
        function close(): void { win.request = null }
        function cancel(): void { win.answer({ cancel: true }) }
        function update(json: string): void {
            try {
                const u = JSON.parse(json);
                if (win.request && u.id === win.request.id)
                    win.request = Object.assign({}, win.request, { choices: u.choices });
            } catch (e) {}
        }
    }

    WlrLayershell.namespace: "sparky-appchooser"
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

    onShownAppsChanged: current = Math.min(current, Math.max(0, shownApps.length - 1))

    Rectangle {
        anchors.fill: parent
        color: "black"
        opacity: 0.42 * win.progress
        MouseArea { anchors.fill: parent; onClicked: win.answer({ cancel: true }) }
    }

    Rectangle {
        id: card

        readonly property int pad: 26

        anchors.centerIn: parent
        anchors.verticalCenterOffset: (1 - win.progress) * 28
        width: 640
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
                    width: 52; height: 52; radius: 17
                    color: Theme.pillHover
                    IconImage {
                        anchors.centerIn: parent
                        implicitSize: 34
                        source: Quickshell.iconPath(win.request?.contentType ? win.request.contentType.replace("/", "-")
                                                    : (win.request?.typeIcon || "text-x-generic"), "text-x-generic")
                    }
                }

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2
                    width: content.width - 66

                    Text {
                        width: parent.width
                        text: win.request?.file ? "Open “" + win.request.file + "” with" : "Choose an app"
                        elide: Text.ElideMiddle
                        color: Theme.fg
                        font { family: Theme.font; pixelSize: 18; weight: Font.Medium }
                    }
                    Text {
                        width: parent.width
                        text: [win.request?.typeName, win.request?.app ? "from " + win.request.app : ""].filter(x => x).join("  ·  ")
                        elide: Text.ElideRight
                        color: Theme.fgDim
                        font { family: Theme.font; pixelSize: 13 }
                    }
                }
            }

            Item {
                width: parent.width
                height: win.apps.length > 6 ? 46 : 0
                visible: height > 0
                clip: true

                SearchField {
                    id: search
                    width: parent.width
                    placeholder: "Search apps"
                    onTextChanged: { win.query = text; win.current = 0; }
                    onMoveSelection: delta => win.current = Math.max(0, Math.min(win.shownApps.length - 1, win.current + delta * grid.columns))
                    onAccepted: win.choose()
                    onDismissed: win.answer({ cancel: true })
                }
            }

            GridView {
                id: grid
                readonly property int columns: 4
                width: parent.width
                height: Math.max(1, Math.min(3, Math.ceil(count / columns))) * cellHeight
                cellWidth: width / columns
                cellHeight: 128
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                currentIndex: win.current
                model: ScriptModel { values: win.shownApps; objectProp: "id" }

                add: Transition {
                    NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 180 }
                    NumberAnimation { property: "scale"; from: 0.9; to: 1; duration: 220; easing.type: Easing.OutCubic }
                }
                remove: Transition { NumberAnimation { property: "opacity"; to: 0; duration: 120 } }
                displaced: Transition { NumberAnimation { properties: "x,y"; duration: 220; easing.type: Easing.OutCubic } }

                Keys.onPressed: event => {
                    const n = win.shownApps.length;
                    if (event.key === Qt.Key_Escape) win.answer({ cancel: true });
                    else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) win.choose();
                    else if (event.key === Qt.Key_Right || event.key === Qt.Key_Tab) win.current = Math.min(n - 1, win.current + 1);
                    else if (event.key === Qt.Key_Left || event.key === Qt.Key_Backtab) win.current = Math.max(0, win.current - 1);
                    else if (event.key === Qt.Key_Down) win.current = Math.min(n - 1, win.current + grid.columns);
                    else if (event.key === Qt.Key_Up) win.current = Math.max(0, win.current - grid.columns);
                    else return;
                    event.accepted = true;
                }

                delegate: Item {
                    id: cell
                    required property var modelData
                    required property int index
                    readonly property bool selected: index === win.current
                    readonly property bool last: modelData.id === win.request?.last
                    width: grid.cellWidth
                    height: grid.cellHeight

                    Rectangle {
                        anchors { fill: parent; margins: 5 }
                        radius: 20
                        color: cell.selected ? Theme.pillHover : (area.containsMouse ? Qt.rgba(1, 1, 1, 0.07) : "transparent")
                        border { width: cell.selected ? 2 : 0; color: Theme.fg }
                        Behavior on color { ColorAnimation { duration: Theme.animFast } }

                        FittedIcon {
                            anchors { horizontalCenter: parent.horizontalCenter; top: parent.top; topMargin: 16 }
                            width: 52; height: 52
                            source: Icons.find(cell.modelData.entry, cell.modelData.id)
                            scale: area.pressed ? 0.92 : 1
                            Behavior on scale { NumberAnimation { duration: Theme.animFast } }
                        }

                        Column {
                            anchors { left: parent.left; right: parent.right; bottom: parent.bottom; margins: 8; bottomMargin: 12 }
                            spacing: 1
                            Text {
                                width: parent.width
                                horizontalAlignment: Text.AlignHCenter
                                text: cell.modelData.name
                                elide: Text.ElideRight
                                color: Theme.fg
                                font { family: Theme.font; pixelSize: 13; weight: cell.selected ? Font.Medium : Font.Normal }
                            }
                            Text {
                                width: parent.width
                                visible: cell.last
                                horizontalAlignment: Text.AlignHCenter
                                text: "Last used"
                                color: Theme.fgDim
                                font { family: Theme.font; pixelSize: 11 }
                            }
                        }

                        MouseArea {
                            id: area
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: win.current = cell.index
                            onDoubleClicked: { win.current = cell.index; win.choose(); }
                        }
                    }
                }
            }

            Text {
                visible: win.shownApps.length === 0
                text: win.apps.length === 0 ? "No app can open this" : "No apps match"
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
                        readonly property bool ready: win.shownApps.length > 0
                        width: openLabel.implicitWidth + 44
                        height: 40
                        radius: 20
                        color: ready ? (openArea.pressed ? Qt.rgba(1, 1, 1, 0.8) : Theme.fg) : Theme.pill
                        Behavior on color { ColorAnimation { duration: Theme.animNormal } }

                        Text {
                            id: openLabel
                            anchors.centerIn: parent
                            text: "Open"
                            color: parent.ready ? "black" : Theme.fgDim
                            font { family: Theme.font; pixelSize: 14; weight: Font.Medium }
                        }

                        MouseArea { id: openArea; anchors.fill: parent; onClicked: win.choose() }
                    }
                }
            }
        }
    }

    Connections {
        target: win
        function onShownChanged() {
            if (!win.shown) return;
            if (win.apps.length > 6) search.forceActiveFocus(); else grid.forceActiveFocus();
        }
    }
}
