import QtQuick
import "../../theme"

Item {
    id: root

    property string source
    property real pressedScale: 1

    readonly property real target: 0.98

    property real fit: 1
    property real offX: 0
    property real offY: 0

    implicitWidth: Theme.iconSize
    implicitHeight: Theme.iconSize

    Image {
        id: icon
        anchors.centerIn: parent
        width: parent.width
        height: parent.height
        source: root.source
        sourceSize: Qt.size(96, 96)
        fillMode: Image.PreserveAspectFit
        mipmap: true
        smooth: true

        scale: root.fit * root.pressedScale
        transform: Translate {
            x: -root.offX * root.width
            y: -root.offY * root.height
        }
        Behavior on scale { NumberAnimation { duration: Theme.animFast; easing.type: Easing.OutCubic } }
    }

    Image {
        id: probe
        visible: false
        source: root.source
        sourceSize: Qt.size(64, 64)
        fillMode: Image.PreserveAspectFit
        onStatusChanged: if (status === Image.Ready) canvas.requestPaint()
    }

    Canvas {
        id: canvas
        visible: false
        width: 64
        height: 64
        renderStrategy: Canvas.Immediate

        onPaint: {
            if (probe.status !== Image.Ready) return;
            const ctx = getContext("2d");
            ctx.clearRect(0, 0, 64, 64);
            ctx.drawImage(probe, 0, 0, 64, 64);
            const px = ctx.getImageData(0, 0, 64, 64).data;

            let minX = 64, minY = 64, maxX = -1, maxY = -1;
            for (let y = 0; y < 64; y++)
                for (let x = 0; x < 64; x++)
                    if (px[(y * 64 + x) * 4 + 3] > 24) {
                        if (x < minX) minX = x;
                        if (x > maxX) maxX = x;
                        if (y < minY) minY = y;
                        if (y > maxY) maxY = y;
                    }
            if (maxX < 0) return;

            const size = Math.max(maxX - minX + 1, maxY - minY + 1) / 64;
            root.fit = Math.max(0.6, Math.min(1.8, root.target / size));
            root.offX = (minX + maxX + 1) / 128 - 0.5;
            root.offY = (minY + maxY + 1) / 128 - 0.5;
        }
    }
}
