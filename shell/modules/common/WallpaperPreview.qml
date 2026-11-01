import Quickshell.Widgets
import QtQuick
import QtMultimedia
import "../../services"

ClippingRectangle {
    id: root

    required property string path
    property bool playing: true

    readonly property string kind: Wallpaper.ext(path)

    color: "transparent"

    Image {
        anchors.fill: parent
        source: root.kind === "gif" ? "" : Wallpaper.previewFor(root.path)
        sourceSize: Qt.size(root.width * 2, root.height * 2)
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        smooth: true
    }

    AnimatedImage {
        anchors.fill: parent
        visible: root.kind === "gif"
        source: visible ? "file://" + root.path : ""
        fillMode: Image.PreserveAspectCrop
        playing: root.playing
        asynchronous: true
        smooth: true
    }

    Loader {
        anchors.fill: parent
        active: root.kind === "mp4" && root.playing && Wallpaper.clipFor(root.path) !== ""
        sourceComponent: Video {
            source: Wallpaper.clipFor(root.path)
            fillMode: VideoOutput.PreserveAspectCrop
            muted: true
            loops: MediaPlayer.Infinite
            autoPlay: true
            opacity: playbackState === MediaPlayer.PlayingState && position > 0 ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 200 } }
        }
    }
}
