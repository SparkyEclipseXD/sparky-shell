import QtQuick
import "../../theme"

Item {
    id: root

    property real from: 0
    property real to: 1
    property real value: 0
    property real step: 0.01
    property int rate: 60
    signal moved(real value)

    property real pos: (value - from) / (to - from)
    property bool touched: false
    onValueChanged: if (!touched) pos = Math.max(0, Math.min(1, (value - from) / (to - from)))

    readonly property real current: Math.round((from + pos * (to - from)) / step) * step

    implicitWidth: 220
    implicitHeight: 28

    Behavior on pos {
        enabled: !drag.pressed
        NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
    }

    function report() {
        if (!throttle.running) {
            root.moved(root.current);
            throttle.start();
        } else {
            throttle.pending = true;
        }
    }
    Timer {
        id: throttle
        property bool pending: false
        interval: root.rate
        onTriggered: if (pending) { pending = false; root.moved(root.current); }
    }

    Rectangle {
        id: track
        anchors.verticalCenter: parent.verticalCenter
        x: knob.width / 2
        width: parent.width - knob.width
        height: 6
        radius: 3
        color: Theme.pill

        Rectangle {
            width: Math.max(height, parent.width * root.pos)
            height: parent.height
            radius: 3
            color: Qt.rgba(1, 1, 1, drag.pressed ? 0.75 : 0.55)
            Behavior on color { ColorAnimation { duration: 120 } }
        }
    }

    Rectangle {
        id: knob
        readonly property real size: drag.pressed ? 24 : (drag.containsMouse ? 20 : 18)
        x: track.x + root.pos * track.width - width / 2
        anchors.verticalCenter: parent.verticalCenter
        width: size
        height: size
        radius: size / 2
        color: Theme.fg
        Behavior on width { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
        Behavior on height { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
    }

    MouseArea {
        id: drag
        anchors.fill: parent
        anchors.margins: -6
        hoverEnabled: true
        preventStealing: true
        cursorShape: Qt.PointingHandCursor

        function at(x): real { return Math.max(0, Math.min(1, (x - 6 - track.x) / track.width)) }

        onPressed: mouse => {
            root.touched = true;
            root.pos = at(mouse.x);
            root.report();
        }
        onPositionChanged: mouse => {
            if (!pressed) return;
            root.pos = at(mouse.x);
            root.report();
        }
        onReleased: {
            throttle.stop();
            throttle.pending = false;
            root.moved(root.current);
        }
    }
}
