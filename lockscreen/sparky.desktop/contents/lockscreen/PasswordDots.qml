import QtQuick

Item {
    id: root

    property int count: 0
    property int cursor: 0
    property bool caretVisible: true
    property color color: "#f2f2f2"
    property real dotSize: 8
    property real spacing: 6

    readonly property real step: dotSize + spacing

    implicitHeight: dotSize * 2.4
    implicitWidth: Math.max(0, count * step - spacing)

    ListModel { id: dots }
    property int nextId: 0
    onCountChanged: {
        while (dots.count < count) dots.append({ uid: nextId++ });
        while (dots.count > count) dots.remove(dots.count - 1);
    }

    ListView {
        id: list
        anchors.verticalCenter: parent.verticalCenter
        width: Math.max(root.width, contentWidth)
        height: root.dotSize * 2
        orientation: ListView.Horizontal
        interactive: false
        spacing: root.spacing
        model: dots

        add: Transition {
            NumberAnimation { property: "scale"; from: 0.2; to: 1; duration: 240; easing.type: Easing.OutBack; easing.overshoot: 2.2 }
            NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 140; easing.type: Easing.OutQuad }
        }
        remove: Transition {
            NumberAnimation { property: "scale"; to: 0.2; duration: 150; easing.type: Easing.InCubic }
            NumberAnimation { property: "opacity"; to: 0; duration: 150; easing.type: Easing.InCubic }
        }

        delegate: Item {
            width: root.dotSize
            height: list.height
            Rectangle {
                anchors.centerIn: parent
                width: root.dotSize
                height: root.dotSize
                radius: width / 2
                color: root.color
            }
        }
    }

    Rectangle {
        id: caret
        visible: root.caretVisible
        width: 2
        height: root.dotSize * 2.1
        radius: 1
        color: root.color
        anchors.verticalCenter: parent.verticalCenter
        x: root.cursor === 0 ? 0 : root.cursor * root.step - root.spacing / 2 - 1 + 2
        Behavior on x { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }

        property bool idle: true
        onXChanged: { idle = false; opacity = 1; idleTimer.restart(); }
        Timer { id: idleTimer; interval: 500; onTriggered: caret.idle = true }

        SequentialAnimation on opacity {
            running: caret.visible && caret.idle
            loops: Animation.Infinite
            NumberAnimation { to: 0; duration: 140 }
            PauseAnimation { duration: 420 }
            NumberAnimation { to: 1; duration: 140 }
            PauseAnimation { duration: 520 }
        }
    }
}
