import QtQuick
import QtQuick.Effects

Rectangle {
    id: root
    color: "black"

    property int stage
    readonly property bool done: stage >= 6
    readonly property real s: Math.min(width, height) / 1080

    Info { id: info }

    FontLoader { id: gsf; source: "fonts/GoogleSansFlex.ttf" }
    readonly property string font: gsf.status === FontLoader.Ready ? gsf.font.family : "sans-serif"

    Image {
        id: wallpaper
        anchors.fill: parent
        source: "images/wallpaper.jpg"
        fillMode: Image.PreserveAspectCrop
        visible: false
    }

    MultiEffect {
        id: wall
        anchors.fill: parent
        source: wallpaper
        blurEnabled: true
        blurMax: 64
        blur: root.done ? 0 : 1
        brightness: root.done ? 0 : -0.18
        opacity: 0
        Behavior on blur { NumberAnimation { duration: 600; easing.type: Easing.InOutCubic } }
        Behavior on brightness { NumberAnimation { duration: 600; easing.type: Easing.InOutCubic } }

        NumberAnimation on opacity { from: 0; to: 1; duration: 700; easing.type: Easing.OutCubic }
    }

    Column {
        id: welcome
        anchors.centerIn: parent
        anchors.verticalCenterOffset: (1 - intro) * 18 - (root.done ? 12 : 0)
        spacing: 22 * root.s
        opacity: root.done ? 0 : intro
        Behavior on opacity { enabled: root.done; NumberAnimation { duration: 320; easing.type: Easing.InCubic } }
        Behavior on anchors.verticalCenterOffset { enabled: root.done; NumberAnimation { duration: 320; easing.type: Easing.InCubic } }

        property real intro: 0
        SequentialAnimation on intro {
            PauseAnimation { duration: 250 }
            NumberAnimation { to: 1; duration: 650; easing.type: Easing.OutQuint }
        }

        Item {
            id: avatar
            anchors.horizontalCenter: parent.horizontalCenter
            width: 132 * root.s
            height: width
            scale: 0.92 + 0.08 * welcome.intro

            Image {
                id: face
                anchors.fill: parent
                source: "images/avatar.png"
                fillMode: Image.PreserveAspectCrop
                sourceSize: Qt.size(width * 2, height * 2)
                visible: false
                layer.enabled: true
            }
            Rectangle {
                id: faceMask
                anchors.fill: parent
                radius: width * 0.32
                visible: false
                layer.enabled: true
            }
            MultiEffect {
                anchors.fill: parent
                source: face
                maskEnabled: true
                maskSource: faceMask
                maskThresholdMin: 0.5
                maskSpreadAtMin: 1
                visible: face.status === Image.Ready
            }
            Rectangle {
                anchors.fill: parent
                visible: face.status !== Image.Ready
                radius: width * 0.32
                color: Qt.rgba(1, 1, 1, 0.12)
                Text {
                    anchors.centerIn: parent
                    text: (info.name || "?")[0]
                    color: "#f2f2f2"
                    font { family: root.font; pixelSize: 56 * root.s; weight: Font.Medium }
                }
            }
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "Welcome back, " + info.name
            color: "#f2f2f2"
            font { family: root.font; pixelSize: 30 * root.s; weight: Font.Medium }
        }

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 10 * root.s
            Repeater {
                model: 3
                Rectangle {
                    id: dot
                    required property int index
                    width: 8 * root.s
                    height: width
                    radius: width / 2
                    color: "#f2f2f2"
                    opacity: 0.25
                    SequentialAnimation on opacity {
                        loops: Animation.Infinite
                        PauseAnimation { duration: dot.index * 180 }
                        NumberAnimation { to: 1; duration: 360; easing.type: Easing.OutQuad }
                        NumberAnimation { to: 0.25; duration: 540; easing.type: Easing.InQuad }
                        PauseAnimation { duration: (2 - dot.index) * 180 }
                    }
                }
            }
        }
    }
}
