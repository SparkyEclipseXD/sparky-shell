import Quickshell
import Quickshell.Widgets
import QtQuick
import "../../theme"
import "../../services"
import "../common"

ListView {
    id: list

    property var results: []
    signal launched(var entry)

    readonly property int rowHeight: 42
    readonly property int maxRows: 7

    function launchCurrent() {
        if (currentItem) launched(results[currentIndex]);
    }

    model: ScriptModel { values: list.results }
    implicitHeight: Math.min(count, maxRows) * rowHeight
    Behavior on implicitHeight { NumberAnimation { duration: Theme.animNormal; easing.type: Easing.OutCubic } }

    clip: true
    boundsBehavior: Flickable.StopAtBounds
    highlightMoveDuration: 130
    highlightMoveVelocity: -1
    highlightFollowsCurrentItem: true

    highlight: Rectangle {
        radius: 10
        color: Theme.pillHover
    }

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

        width: list.width
        height: list.rowHeight

        IconImage {
            id: icon
            anchors { left: parent.left; leftMargin: 10; verticalCenter: parent.verticalCenter }
            implicitSize: 24
            source: Icons.find(row.modelData)
        }

        Text {
            anchors {
                left: icon.right; leftMargin: 12; right: parent.right; rightMargin: 12
                verticalCenter: parent.verticalCenter
            }
            text: row.modelData.name
            elide: Text.ElideRight
            color: Theme.fg
            font { family: Theme.font; pixelSize: 14 }
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            onPositionChanged: list.currentIndex = row.index
            onClicked: mouse => {
                if (mouse.button === Qt.RightButton) {
                    list.currentIndex = row.index;
                    menu.active = true;
                } else list.launched(row.modelData);
            }
        }

        LazyLoader {
            id: menu
            SlotMenu {
                item: Apps.itemForEntry(row.modelData)
                anchorItem: row
                above: false
                visible: true
                onVisibleChanged: if (!visible) Qt.callLater(() => menu.active = false)
            }
        }
    }
}
