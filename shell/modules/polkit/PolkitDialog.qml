import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import Quickshell.Wayland
import Quickshell.Services.Polkit
import QtQuick
import "../../theme"
import "../../services"
import "../common"

PanelWindow {
    id: win

    readonly property AuthFlow flow: agent.flow
    readonly property bool shown: flow !== null && !flow.isCompleted && !flow.isCancelled
    property bool checking: false
    property bool reveal: false
    property bool details: false

    readonly property var parts: {
        const m = (flow?.message ?? "").match(/^([\s\S]*?)`([^`']+)['`]([\s\S]*)$/);
        return m ? { before: m[1].trim(), command: m[2], after: m[3].trim() }
                 : { before: flow?.message ?? "", command: "", after: "" };
    }

    WlrLayershell.namespace: "sparky-polkit"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: shown ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    visible: shown || progress > 0

    property real progress: shown ? 1 : 0
    Behavior on progress {
        NumberAnimation { duration: win.shown ? 320 : 180; easing.type: win.shown ? Easing.OutQuint : Easing.InCubic }
    }

    BackgroundEffect.blurRegion: progress >= 1 ? blur : null
    property Region blur: Region { item: card; radius: card.radius }

    onShownChanged: if (shown) {
        field.text = "";
        checking = false;
        reveal = false;
        details = false;
        field.forceActiveFocus();
    }

    function submit() {
        if (!flow || !flow.isResponseRequired || checking) return;
        checking = true;
        flow.submit(field.text);
        field.text = "";
    }

    function cancel() { flow?.cancelAuthenticationRequest() }

    property bool takenOver: false

    Process {
        running: true
        command: ["sh", "-c",
            'systemctl --user stop plasma-polkit-agent.service; ' +
            'systemctl --user stop sparky-polkit-guard.service 2>/dev/null; ' +
            'systemd-run --user --collect --quiet --unit=sparky-polkit-guard sh -c ' +
            '"while kill -0 $PPID 2>/dev/null; do sleep 2; done; systemctl --user start plasma-polkit-agent.service" ' +
            '>/dev/null 2>&1; true']
        onExited: win.takenOver = true
    }

    Loader {
        active: win.takenOver
        sourceComponent: PolkitAgent {}
        onLoaded: agentHolder.agent = item
    }
    QtObject {
        id: agentHolder
        property var agent: null
    }
    readonly property var agent: agentHolder.agent ?? { flow: null }

    Connections {
        target: win.flow
        ignoreUnknownSignals: true
        function onIsResponseRequiredChanged() {
            if (win.flow.isResponseRequired) {
                win.checking = false;
                field.forceActiveFocus();
            }
        }
        function onAuthenticationFailed() {
            win.checking = false;
            shake.restart();
        }
    }

    Rectangle {
        anchors.fill: parent
        color: "black"
        opacity: 0.42 * win.progress
    }

    Rectangle {
        id: card

        readonly property int pad: 26

        anchors.centerIn: parent
        anchors.verticalCenterOffset: (1 - win.progress) * 28
        width: 460
        height: content.implicitHeight + 2 * pad
        radius: 30
        color: Theme.surface
        opacity: Math.min(1, win.progress * 1.6)
        scale: 0.93 + 0.07 * win.progress
        Behavior on height { NumberAnimation { duration: Theme.animNormal; easing.type: Easing.OutCubic } }

        Column {
            id: content
            x: card.pad
            y: card.pad
            width: card.width - 2 * card.pad
            spacing: 16

            Row {
                spacing: 14

                Rectangle {
                    width: 48; height: 48; radius: 16
                    color: Theme.pillHover
                    MaterialIcon { anchors.centerIn: parent; size: 26; name: "shield_lock"; fill: 1 }
                }

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2

                    Text {
                        text: "Authentication required"
                        color: Theme.fg
                        font { family: Theme.font; pixelSize: 18; weight: Font.Medium }
                    }
                    Text {
                        text: "An app wants to make changes to your system"
                        color: Theme.fgDim
                        font { family: Theme.font; pixelSize: 13 }
                    }
                }
            }

            Text {
                width: parent.width
                visible: text !== ""
                text: win.parts.before
                wrapMode: Text.Wrap
                color: Qt.rgba(1, 1, 1, 0.82)
                font { family: Theme.font; pixelSize: 14 }
            }

            Rectangle {
                width: parent.width
                visible: win.parts.command !== ""
                height: command.implicitHeight + 20
                radius: 12
                color: Qt.rgba(1, 1, 1, 0.06)

                Text {
                    id: command
                    x: 14; y: 10
                    width: parent.width - 28
                    text: win.parts.command
                    wrapMode: Text.WrapAnywhere
                    color: Theme.fg
                    font { family: "JetBrainsMono Nerd Font"; pixelSize: 13 }
                }
            }

            Text {
                width: parent.width
                visible: text !== ""
                text: win.parts.after
                wrapMode: Text.Wrap
                color: Qt.rgba(1, 1, 1, 0.82)
                font { family: Theme.font; pixelSize: 14 }
            }

            Rectangle {
                width: parent.width
                height: 52
                radius: 16
                color: idArea.containsMouse && (win.flow?.identities.length ?? 0) > 1 ? Theme.pillHover : Theme.pill
                Behavior on color { ColorAnimation { duration: Theme.animFast } }

                id: idRow
                readonly property var identity: win.flow?.selectedIdentity
                readonly property bool isMe: !identity || identity.displayName === User.name || identity.displayName === User.realName

                ClippingRectangle {
                    id: who
                    anchors { left: parent.left; leftMargin: 8; verticalCenter: parent.verticalCenter }
                    width: 36; height: 36; radius: 18
                    color: Theme.pillHover

                    Text {
                        anchors.centerIn: parent
                        visible: !idRow.isMe || face.status !== Image.Ready
                        text: (idRow.identity?.displayName ?? User.realName)[0]?.toUpperCase() ?? "?"
                        color: Theme.fg
                        font { family: Theme.font; pixelSize: 15; weight: Font.Medium }
                    }
                    Image {
                        id: face
                        anchors.fill: parent
                        visible: idRow.isMe
                        source: User.avatar
                        sourceSize: Qt.size(72, 72)
                        fillMode: Image.PreserveAspectCrop
                        cache: false
                    }
                }

                Column {
                    anchors { left: who.right; leftMargin: 12; verticalCenter: parent.verticalCenter }
                    spacing: 1
                    Text {
                        text: idRow.isMe ? User.realName : (idRow.identity?.displayName ?? "")
                        color: Theme.fg
                        font { family: Theme.font; pixelSize: 14; weight: Font.Medium }
                    }
                    Text {
                        text: idRow.isMe ? "@" + User.name : "Administrator"
                        color: Theme.fgDim
                        font { family: Theme.font; pixelSize: 12 }
                    }
                }

                MaterialIcon {
                    visible: (win.flow?.identities.length ?? 0) > 1
                    anchors { right: parent.right; rightMargin: 14; verticalCenter: parent.verticalCenter }
                    size: 20
                    name: "unfold_more"
                    color: Theme.fgDim
                }

                MouseArea {
                    id: idArea
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        const ids = win.flow?.identities ?? [];
                        if (ids.length < 2) return;
                        const i = ids.indexOf(win.flow.selectedIdentity);
                        win.flow.selectedIdentity = ids[(i + 1) % ids.length];
                    }
                }
            }

            Rectangle {
                id: pill
                width: parent.width
                height: 48
                radius: 24
                color: field.activeFocus ? Theme.pillHover : Theme.pill
                border.width: win.flow?.supplementaryIsError ? 1 : 0
                border.color: Qt.rgba(1, 0.55, 0.55, 0.6)
                Behavior on color { ColorAnimation { duration: Theme.animNormal } }

                transform: Translate { id: shakeT }
                SequentialAnimation {
                    id: shake
                    NumberAnimation { target: shakeT; property: "x"; to: -12; duration: 50; easing.type: Easing.OutQuad }
                    NumberAnimation { target: shakeT; property: "x"; to: 10; duration: 70; easing.type: Easing.InOutQuad }
                    NumberAnimation { target: shakeT; property: "x"; to: -6; duration: 60; easing.type: Easing.InOutQuad }
                    NumberAnimation { target: shakeT; property: "x"; to: 3; duration: 50; easing.type: Easing.InOutQuad }
                    NumberAnimation { target: shakeT; property: "x"; to: 0; duration: 60; easing.type: Easing.OutQuad }
                }

                MaterialIcon {
                    id: lockIcon
                    anchors { left: parent.left; leftMargin: 18; verticalCenter: parent.verticalCenter }
                    size: 18
                    name: "lock"
                    color: Theme.fgDim
                }

                TextInput {
                    id: field
                    anchors { left: lockIcon.right; leftMargin: 10; right: eye.left; rightMargin: 8; verticalCenter: parent.verticalCenter }
                    enabled: !win.checking && (win.flow?.isResponseRequired ?? false)
                    echoMode: win.reveal || (win.flow?.responseVisible ?? false) ? TextInput.Normal : TextInput.Password
                    passwordCharacter: "●"
                    passwordMaskDelay: 0
                    color: Theme.fg
                    selectionColor: Qt.rgba(1, 1, 1, 0.25)
                    font { family: Theme.font; pixelSize: 15; letterSpacing: echoMode === TextInput.Password ? 2 : 0 }
                    clip: true
                    onAccepted: win.submit()
                    Keys.onEscapePressed: win.cancel()

                    Text {
                        visible: field.text === ""
                        anchors.verticalCenter: parent.verticalCenter
                        text: win.checking ? "Checking…" : ((win.flow?.inputPrompt ?? "").replace(/:\s*$/, "") || "Password")
                        color: Qt.rgba(1, 1, 1, 0.45)
                        font { family: Theme.font; pixelSize: 15 }
                    }
                }

                Rectangle {
                    id: eye
                    anchors { right: parent.right; rightMargin: 7; verticalCenter: parent.verticalCenter }
                    width: 34; height: 34; radius: 17
                    color: eyeArea.containsMouse ? Theme.pillHover : "transparent"
                    Behavior on color { ColorAnimation { duration: Theme.animFast } }

                    MaterialIcon {
                        anchors.centerIn: parent
                        visible: !win.checking
                        size: 18
                        name: win.reveal ? "visibility_off" : "visibility"
                        color: Theme.fgDim
                    }

                    Item {
                        anchors.centerIn: parent
                        visible: win.checking
                        width: 18; height: 18
                        Rectangle { anchors.fill: parent; radius: 9; color: "transparent"; border { width: 2; color: Qt.rgba(1, 1, 1, 0.18) } }
                        Rectangle { width: 6; height: 6; radius: 3; x: 6; y: -2; color: Theme.fg }
                        RotationAnimation on rotation { running: win.checking; from: 0; to: 360; duration: 800; loops: Animation.Infinite }
                    }

                    MouseArea {
                        id: eyeArea
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: { win.reveal = !win.reveal; field.forceActiveFocus(); }
                    }
                }
            }

            Text {
                width: parent.width
                visible: text !== ""
                text: win.flow?.supplementaryMessage ?? ""
                wrapMode: Text.Wrap
                color: win.flow?.supplementaryIsError ? Qt.rgba(1, 0.75, 0.75, 1) : Theme.fgDim
                font { family: Theme.font; pixelSize: 13 }
            }

            Rectangle {
                width: parent.width
                visible: win.details
                height: actionText.implicitHeight + 18
                radius: 12
                color: Qt.rgba(1, 1, 1, 0.04)

                Text {
                    id: actionText
                    x: 14; y: 9
                    width: parent.width - 28
                    text: "Action: " + (win.flow?.actionId ?? "")
                    wrapMode: Text.WrapAnywhere
                    color: Theme.fgDim
                    font { family: "JetBrainsMono Nerd Font"; pixelSize: 12 }
                }
            }

            Item {
                width: parent.width
                height: 40

                PillButton {
                    anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                    implicitHeight: 40
                    text: win.details ? "Hide details" : "Details"
                    onClicked: { win.details = !win.details; field.forceActiveFocus(); }
                }

                Row {
                    anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                    spacing: 8

                    PillButton {
                        implicitHeight: 40
                        text: "Cancel"
                        onClicked: win.cancel()
                    }

                    Rectangle {
                        width: authLabel.implicitWidth + 40
                        height: 40
                        radius: 20
                        readonly property bool ready: field.text !== "" && !win.checking
                        color: ready ? (authArea.pressed ? Qt.rgba(1, 1, 1, 0.8) : Theme.fg) : Theme.pill
                        Behavior on color { ColorAnimation { duration: Theme.animNormal } }

                        Text {
                            id: authLabel
                            anchors.centerIn: parent
                            text: "Authenticate"
                            color: parent.ready ? "black" : Theme.fgDim
                            font { family: Theme.font; pixelSize: 14; weight: Font.Medium }
                            Behavior on color { ColorAnimation { duration: Theme.animNormal } }
                        }

                        MouseArea {
                            id: authArea
                            anchors.fill: parent
                            onClicked: win.submit()
                        }
                    }
                }
            }
        }
    }
}
