import QtQuick
import QtQuick.Effects

Item {
    id: root

    property real radius: 0
    default property alias content: inner.data

    Item {
        id: inner
        anchors.fill: parent
        visible: false
        layer.enabled: true
    }

    Rectangle {
        id: mask
        anchors.fill: parent
        radius: root.radius
        visible: false
        layer.enabled: true
        layer.smooth: true
    }

    MultiEffect {
        anchors.fill: parent
        source: inner
        maskEnabled: true
        maskSource: mask
        maskThresholdMin: 0.5
        maskSpreadAtMin: 1.0
    }
}
