import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import QtQuick
import "../../theme"
import "../../services"
import "../launcher"
import "../common"

PanelWindow {
    id: win

    readonly property bool shown: Clipboard.open

    WlrLayershell.namespace: "sparky-clipboard"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: shown ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    visible: shown || panel.progress > 0

    BackgroundEffect.blurRegion: panel.opacity >= 1 ? blur : null
    property Region blur: Region { item: blurArea; radius: Theme.launcherRadius * panel.scale }

    Item {
        id: blurArea
        x: panel.x + panel.width * (1 - panel.scale) / 2
        y: panel.y + panel.height * (1 - panel.scale) / 2
        width: panel.width * panel.scale
        height: panel.height * panel.scale
    }

    property var results: []
    readonly property var selected: results[list.currentIndex] ?? null
    readonly property bool previewing: shown && selected !== null && selected.kind === "image"
    readonly property int previewWidth: 420
    function refresh() { results = Clipboard.search(search.text) }

    onShownChanged: if (shown) {
        search.reset();
        refresh();
        list.currentIndex = 0;
        list.positionViewAtBeginning();
    }

    Connections {
        target: Clipboard
        function onEntriesChanged() { win.refresh() }
    }

    function copyCurrent() {
        const e = results[list.currentIndex];
        if (!e) return;
        Clipboard.copy(e);
        Clipboard.close();
    }

    function removeCurrent() {
        const e = results[list.currentIndex];
        if (e) Clipboard.remove(e);
    }

    IpcHandler {
        target: "clipboard"
        function toggle(): void { Clipboard.toggle() }
        function open(): void { Clipboard.open = true }
        function close(): void { Clipboard.close() }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: Clipboard.close()
    }

    Rectangle {
        id: panel

        property real progress: win.shown ? 1 : 0
        Behavior on progress {
            NumberAnimation {
                duration: win.shown ? 260 : 160
                easing.type: win.shown ? Easing.OutQuint : Easing.InCubic
            }
        }

        width: Theme.launcherWidth + (win.previewing ? win.previewWidth + Theme.launcherPadding : 0)
        Behavior on width { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
        height: content.implicitHeight + 2 * Theme.launcherPadding
        x: (parent.width - width) / 2
        y: (parent.height - height) / 2 + (1 - progress) * 20
        radius: Theme.launcherRadius
        color: Theme.surface
        opacity: Math.min(1, progress * 1.8)
        scale: 0.94 + 0.06 * progress
        transformOrigin: Item.Center
        clip: true

        Behavior on height { NumberAnimation { duration: Theme.animNormal; easing.type: Easing.OutCubic } }

        MouseArea { anchors.fill: parent }

        ClippingRectangle {
            id: preview
            anchors {
                top: parent.top; bottom: parent.bottom; right: parent.right
                margins: Theme.launcherPadding
            }
            width: win.previewWidth
            radius: Theme.launcherRadius - Theme.launcherPadding
            color: Theme.card
            opacity: win.previewing ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 180 } }

            property var entry: null
            Connections {
                target: win
                function onSelectedChanged() { if (win.selected?.kind === "image") preview.entry = win.selected }
            }

            Image {
                anchors { fill: parent; margins: 12; bottomMargin: 44 }
                source: preview.entry ? Clipboard.fileUrl(preview.entry) : ""
                sourceSize: Qt.size(840, 900)
                fillMode: Image.PreserveAspectFit
                asynchronous: true
                smooth: true
                mipmap: true
            }

            Text {
                anchors { bottom: parent.bottom; bottomMargin: 14; horizontalCenter: parent.horizontalCenter }
                text: preview.entry?.width ? preview.entry.width + " × " + preview.entry.height : "Image"
                color: Theme.fgDim
                font { family: Theme.font; pixelSize: 12 }
            }
        }

        Column {
            id: content
            anchors { top: parent.top; left: parent.left; margins: Theme.launcherPadding }
            width: Theme.launcherWidth - 2 * Theme.launcherPadding
            spacing: 8

            SearchField {
                id: search
                width: parent.width
                placeholder: "Search clipboard"
                onTextChanged: { win.refresh(); list.currentIndex = 0 }
                onMoveSelection: delta => list.currentIndex =
                    Math.max(0, Math.min(list.count - 1, list.currentIndex + delta))
                onAccepted: win.copyCurrent()
                onDismissed: Clipboard.close()
                onRemoveCurrent: win.removeCurrent()
            }

            ListView {
                id: list
                width: parent.width
                readonly property int maxHeight: 460
                implicitHeight: Clipboard.entries.length > 3 ? maxHeight : Math.min(contentHeight, maxHeight)
                visible: count > 0

                clip: true
                spacing: 2
                boundsBehavior: Flickable.StopAtBounds
                model: ScriptModel { values: win.results; objectProp: "id" }

                highlightMoveDuration: 130
                highlightMoveVelocity: -1
                highlightResizeDuration: 130
                highlightResizeVelocity: -1
                highlight: Rectangle { radius: 12; color: Theme.pillHover }

                add: Transition { NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 150 } }
                remove: Transition { NumberAnimation { property: "opacity"; to: 0; duration: 90 } }
                displaced: Transition {
                    NumberAnimation { properties: "y"; duration: 150; easing.type: Easing.OutCubic }
                    NumberAnimation { property: "opacity"; to: 1; duration: 150 }
                }

                delegate: Item {
                    id: row
                    required property var modelData
                    required property int index
                    readonly property bool image: modelData.kind === "image"

                    width: list.width
                    height: image ? 112 : 54

                    ClippingRectangle {
                        id: thumb
                        visible: row.image
                        anchors { left: parent.left; leftMargin: 10; verticalCenter: parent.verticalCenter }
                        height: parent.height - 16
                        width: Math.min(260, row.modelData.width && row.modelData.height
                            ? height * row.modelData.width / row.modelData.height : height * 16 / 9)
                        radius: 8
                        color: Theme.card

                        Image {
                            anchors.fill: parent
                            source: row.image ? Clipboard.fileUrl(row.modelData) : ""
                            sourceSize: Qt.size(520, 200)
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            smooth: true
                        }
                    }

                    Column {
                        anchors {
                            left: row.image ? thumb.right : parent.left
                            leftMargin: row.image ? 14 : 14
                            right: del.left; rightMargin: 8
                            verticalCenter: parent.verticalCenter
                        }
                        spacing: 3

                        Text {
                            width: parent.width
                            visible: !row.image
                            text: (row.modelData.text || "").replace(/\s+/g, " ").trim()
                            textFormat: Text.PlainText
                            elide: Text.ElideRight
                            maximumLineCount: 1
                            color: Theme.fg
                            font { family: Theme.font; pixelSize: 14 }
                        }

                        Text {
                            width: parent.width
                            text: {
                                const m = row.modelData;
                                const parts = [];
                                if (row.image) {
                                    parts.push("Image");
                                    if (m.width) parts.push(m.width + " × " + m.height);
                                } else if (m.lines > 1) {
                                    parts.push(m.lines + " lines");
                                }
                                parts.push(ago(m.time));
                                return parts.join("  ·  ");
                            }
                            elide: Text.ElideRight
                            color: Theme.fgDim
                            font { family: Theme.font; pixelSize: 12 }

                            function ago(t): string {
                                const s = Math.max(0, Math.floor(Date.now() / 1000 - t));
                                if (s < 60) return "just now";
                                if (s < 3600) return Math.floor(s / 60) + "m ago";
                                if (s < 86400) return Math.floor(s / 3600) + "h ago";
                                return Math.floor(s / 86400) + "d ago";
                            }
                        }
                    }

                    MouseArea {
                        id: rowMa
                        anchors.fill: parent
                        hoverEnabled: true
                        onPositionChanged: list.currentIndex = row.index
                        onClicked: { list.currentIndex = row.index; win.copyCurrent() }
                    }

                    Rectangle {
                        id: del
                        anchors { right: parent.right; rightMargin: 10; verticalCenter: parent.verticalCenter }
                        width: 28; height: 28; radius: 14
                        opacity: row.ListView.isCurrentItem ? 1 : 0
                        Behavior on opacity { NumberAnimation { duration: Theme.animFast } }
                        color: delMa.containsMouse ? Theme.pillHover : "transparent"
                        Behavior on color { ColorAnimation { duration: Theme.animFast } }

                        SymbolIcon {
                            anchors.centerIn: parent
                            size: 14
                            name: "window-close-symbolic"
                            color: delMa.containsMouse ? Theme.fg : Theme.fgDim
                        }

                        MouseArea {
                            id: delMa
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: Clipboard.remove(row.modelData)
                        }
                    }
                }
            }

            Text {
                visible: list.count === 0
                width: parent.width
                height: Clipboard.entries.length > 3 ? list.maxHeight : 64
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                text: Clipboard.entries.length === 0 ? "Nothing copied yet" : "No matches"
                color: Theme.fgDim
                font { family: Theme.font; pixelSize: 14 }
            }

            Item {
                width: parent.width
                height: 34

                Text {
                    anchors { left: parent.left; leftMargin: 8; verticalCenter: parent.verticalCenter }
                    text: "Enter copy   ·   Shift+Del remove   ·   \"img\" pictures only"
                    color: Qt.rgba(1, 1, 1, 0.35)
                    font { family: Theme.font; pixelSize: 12 }
                }

                PillButton {
                    anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                    implicitHeight: 30
                    text: "Clear all"
                    visible: Clipboard.entries.length > 0
                    onClicked: Clipboard.clear()
                }
            }
        }
    }
}
