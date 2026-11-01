import QtQuick

Text {
    id: root

    property string shown
    text: shown

    Behavior on shown {
        SequentialAnimation {
            NumberAnimation { target: root; property: "opacity"; to: 0; duration: 110; easing.type: Easing.InQuad }
            PropertyAction { target: root; property: "shown" }
            NumberAnimation { target: root; property: "opacity"; to: 1; duration: 170; easing.type: Easing.OutQuad }
        }
    }
}
