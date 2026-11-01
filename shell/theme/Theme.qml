pragma Singleton
import QtQuick

QtObject {
    readonly property color surface: Qt.rgba(0.02, 0.02, 0.03, 0.74)
    readonly property color surfaceRaised: Qt.rgba(0.10, 0.10, 0.11, 0.80)
    readonly property color pill: Qt.rgba(1, 1, 1, 0.07)
    readonly property color pillHover: Qt.rgba(1, 1, 1, 0.15)

    readonly property color window: Qt.rgba(0.03, 0.03, 0.04, 0.72)
    readonly property color sidebar: Qt.rgba(1, 1, 1, 0.035)
    readonly property color card: Qt.rgba(1, 1, 1, 0.05)

    readonly property color fg: "#f2f2f2"
    readonly property color fgDim: Qt.rgba(1, 1, 1, 0.5)

    readonly property int dockHeight: 48
    readonly property int topBarHeight: 36
    readonly property int dockMargin: 14
    readonly property int dockRadius: 18
    readonly property int dockPadding: 12
    readonly property int slotWidth: 44
    readonly property int slotHeight: 40
    readonly property int slotRadius: 10
    readonly property int slotSpacing: 2
    readonly property int launcherWidth: 560
    readonly property int launcherRadius: 20
    readonly property int launcherPadding: 10
    readonly property int launcherTop: 90
    readonly property int iconSize: 30
    readonly property int notifWidth: 380

    readonly property color divider: Qt.rgba(1, 1, 1, 0.18)

    readonly property string font: "Google Sans Flex"
    readonly property int fontSize: 14

    readonly property int animFast: 110
    readonly property int animNormal: 160
}
