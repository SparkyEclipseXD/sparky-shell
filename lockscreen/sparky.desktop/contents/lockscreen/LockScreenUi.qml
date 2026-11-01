import QtQuick
import QtQuick.Effects
import QtMultimedia
import org.kde.plasma.plasma5support as Plasma5Support
import org.kde.plasma.private.mpris as Mpris
import org.kde.plasma.private.sessions

Item {
    id: ui

    readonly property color fg: "#f2f2f2"
    readonly property color dim: Qt.rgba(1, 1, 1, 0.55)
    readonly property color cardColor: Qt.rgba(1, 1, 1, 0.065)
    readonly property color raised: Qt.rgba(1, 1, 1, 0.11)
    readonly property string font: "Google Sans Flex"

    readonly property real s: Math.min(width, height) / 1080
    readonly property real panelW: Math.min(width - 48, Math.min(width, height) * 0.7 * 16 / 9)
    readonly property real panelH: Math.min(width, height) * 0.7
    readonly property real outerRadius: 42 * s
    readonly property real margin: 16 * s
    readonly property real cardRadius: outerRadius - margin
    readonly property real gap: 16 * s
    readonly property real centreW: 400 * s

    property var info: ({})
    property bool leaving: false
    property string message: ""
    property string pending: ""

    function clearPassword() { field.text = "" }
    function wake() {
        authenticator.startAuthenticating();
        field.forceActiveFocus();
    }

    function submit() {
        if (leaving || field.text === "") return;
        message = "";
        if (authenticator.pamTimeout) {
            pending = field.text;
        } else {
            authenticator.respond(field.text);
        }
        busy.running = true;
    }

    FontLoader { source: Qt.resolvedUrl("../fonts/GoogleSansFlex.ttf") }
    FontLoader { source: Qt.resolvedUrl("../fonts/MaterialSymbolsRounded.ttf") }

    Connections {
        target: authenticator
        function onFailed(kind) {
            if (kind != 0) return;
            busy.running = false;
            ui.message = "Wrong password, try again";
            field.text = "";
            shake.restart();
            authenticator.startAuthenticating();
        }
        function onSucceeded() {
            authenticator.stopAuthenticating();
            busy.running = false;
            ui.leaving = true;
            quitTimer.start();
        }
        function onPamTimeoutChanged() {
            if (!authenticator.pamTimeout && ui.pending.length > 0) {
                authenticator.respond(ui.pending);
                ui.pending = "";
            }
        }
    }
    Timer { id: quitTimer; interval: 340; onTriggered: Qt.quit() }
    Timer { interval: 1000; repeat: true; running: !authenticator.unlocked; onTriggered: authenticator.startAuthenticating() }
    Component.onCompleted: wake()

    SessionManagement { id: sessions }

    Plasma5Support.DataSource {
        engine: "executable"
        connectedSources: ["python3 \"$HOME/.local/bin/sparky-lockinfo\""]
        interval: 3000
        onNewData: (source, data) => {
            try { ui.info = JSON.parse(data["stdout"] || "{}") } catch (e) {}
        }
    }

    property real intro: 0
    NumberAnimation on intro { from: 0; to: 1; duration: 900; easing.type: Easing.OutQuint }
    function stagger(delay): real { return Math.max(0, Math.min(1, (intro - delay) / (1 - delay))) }

    property date now: new Date()
    Timer { interval: 1000; repeat: true; running: true; onTriggered: ui.now = new Date() }

    Rectangle { anchors.fill: parent; color: "black" }

    Item {
        id: wallpaper
        anchors.fill: parent

        Image {
            anchors.fill: parent
            source: ui.info.still ? "file://" + ui.info.still
                  : (ui.info.wallpaper && !/\.(mp4|gif)$/i.test(ui.info.wallpaper) ? "file://" + ui.info.wallpaper : "")
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
        }

        Video {
            anchors.fill: parent
            source: ui.info.wallpaper && /\.mp4$/i.test(ui.info.wallpaper) ? "file://" + ui.info.wallpaper : ""
            fillMode: VideoOutput.PreserveAspectCrop
            muted: true
            loops: MediaPlayer.Infinite
            autoPlay: true
            opacity: playbackState === MediaPlayer.PlayingState && position > 0 ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 400 } }
        }

        Rectangle { anchors.fill: parent; color: Qt.rgba(0, 0, 0, 0.18) }
    }

    Item {
        id: panel
        readonly property real t: ui.stagger(0)
        width: ui.panelW
        height: ui.panelH
        anchors.centerIn: parent
        opacity: t * (ui.leaving ? 0 : 1)
        scale: (0.97 + 0.03 * t) * (ui.leaving ? 1.03 : 1)
        Behavior on opacity { enabled: ui.leaving; NumberAnimation { duration: 300; easing.type: Easing.InCubic } }
        Behavior on scale { enabled: ui.leaving; NumberAnimation { duration: 300; easing.type: Easing.InCubic } }

        Rounded {
            anchors.fill: parent
            radius: ui.outerRadius

            ShaderEffectSource {
                id: behind
                anchors.fill: parent
                sourceItem: wallpaper
                sourceRect: Qt.rect((ui.width - panel.width) / 2, (ui.height - panel.height) / 2, panel.width, panel.height)
                live: true
                visible: false
            }
            MultiEffect { anchors.fill: parent; source: behind; blurEnabled: true; blur: 1; blurMax: 64; saturation: -0.2 }
            Rectangle { anchors.fill: parent; color: Qt.rgba(0.02, 0.02, 0.03, 0.42) }
        }

        Column {
            id: left
            readonly property real t: ui.stagger(0.15)
            readonly property real pool: panel.height - 2 * ui.margin - 2 * ui.gap
            x: ui.margin - (1 - t) * 30
            y: ui.margin
            width: (panel.width - 2 * ui.margin - ui.centreW - 2 * 40 * ui.s) / 2
            spacing: ui.gap
            opacity: t

            WeatherCard { width: left.width; height: Math.round(left.pool * 0.18) }
            FetchCard { width: left.width; height: Math.round(left.pool * 0.35) }
            MediaCard { width: left.width; height: left.pool - Math.round(left.pool * 0.18) - Math.round(left.pool * 0.35) }
        }

        Column {
            id: right
            readonly property real t: ui.stagger(0.15)
            readonly property real pool: panel.height - 2 * ui.margin - ui.gap
            x: panel.width - ui.margin - width + (1 - t) * 30
            y: ui.margin
            width: left.width
            spacing: ui.gap
            opacity: t

            ResourcesCard { width: right.width; height: Math.round(right.pool * 0.23) }
            CalendarCard { width: right.width; height: right.pool - Math.round(right.pool * 0.23) }
        }

        Column {
            id: centre
            readonly property real t: ui.stagger(0.08)
            readonly property real avatarSize: Math.min(ui.centreW * 0.85, (panel.height - 2 * ui.margin) * 0.36)
            anchors.horizontalCenter: parent.horizontalCenter
            y: (panel.height - implicitHeight) / 2 + (1 - t) * 24
            width: ui.centreW
            spacing: 18 * ui.s
            opacity: t

            Column {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 6 * ui.s

                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 10 * ui.s

                    Text {
                        id: hours
                        text: Qt.formatTime(ui.now, "hh AP").split(" ")[0]
                        color: ui.fg
                        font { family: ui.font; pixelSize: 132 * ui.s; weight: Font.Medium; letterSpacing: -4 * ui.s }
                    }
                    Column {
                        anchors.verticalCenter: hours.verticalCenter
                        anchors.verticalCenterOffset: 4 * ui.s
                        spacing: 6 * ui.s
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: Qt.formatTime(ui.now, "mm")
                            color: Qt.rgba(1, 1, 1, 0.82)
                            font { family: ui.font; pixelSize: 56 * ui.s; weight: Font.Medium }
                        }
                        Rectangle {
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: ampm.implicitWidth + 16 * ui.s
                            height: 34 * ui.s
                            radius: 10 * ui.s
                            color: ui.raised
                            Text {
                                id: ampm
                                anchors.centerIn: parent
                                text: ui.now.getHours() >= 12 ? "PM" : "AM"
                                color: ui.fg
                                font { family: ui.font; pixelSize: 24 * ui.s; weight: Font.Medium }
                            }
                        }
                    }
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Qt.formatDate(ui.now, "dddd  •  d MMM").toUpperCase()
                    color: Qt.rgba(1, 1, 1, 0.85)
                    font { family: ui.font; pixelSize: 19 * ui.s; weight: Font.DemiBold; letterSpacing: 2.5 * ui.s }
                }
            }

            Rounded {
                anchors.horizontalCenter: parent.horizontalCenter
                width: centre.avatarSize
                height: centre.avatarSize
                radius: width * 0.32

                Rectangle { anchors.fill: parent; color: Qt.rgba(1, 1, 1, 0.1) }
                Text {
                    anchors.centerIn: parent
                    visible: face.status !== Image.Ready
                    text: (kscreenlocker_userName || "?")[0].toUpperCase()
                    color: ui.fg
                    font { family: ui.font; pixelSize: centre.avatarSize * 0.42; weight: Font.Medium }
                }
                Image {
                    id: face
                    anchors.fill: parent
                    source: kscreenlocker_userImage ? "file://" + kscreenlocker_userImage : ""
                    fillMode: Image.PreserveAspectCrop
                    sourceSize: Qt.size(width * 2, height * 2)
                    smooth: true
                }
            }

            Rectangle {
                readonly property int hour: ui.now.getHours()
                anchors.horizontalCenter: parent.horizontalCenter
                width: greetRow.implicitWidth + 32 * ui.s
                height: 38 * ui.s
                radius: height / 2
                color: ui.cardColor

                Row {
                    id: greetRow
                    anchors.centerIn: parent
                    spacing: 9 * ui.s
                    Icon {
                        anchors.verticalCenter: parent.verticalCenter
                        size: 17 * ui.s
                        name: parent.parent.hour >= 6 && parent.parent.hour < 19 ? "light_mode" : "dark_mode"
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        textFormat: Text.StyledText
                        text: {
                            const h = parent.parent.hour;
                            const part = h < 5 ? "Good night" : h < 12 ? "Good morning" : h < 18 ? "Good afternoon" : "Good evening";
                            return part + ", <b>" + (kscreenlocker_userName || "").split(" ")[0] + "</b>";
                        }
                        color: Qt.rgba(1, 1, 1, 0.85)
                        font { family: ui.font; pixelSize: 15 * ui.s }
                    }
                }
            }

            Rectangle {
                id: pill
                anchors.horizontalCenter: parent.horizontalCenter
                width: 300 * ui.s
                height: 46 * ui.s
                radius: height / 2
                color: field.activeFocus ? ui.raised : ui.cardColor
                border.width: ui.message !== "" ? 1 : 0
                border.color: Qt.rgba(1, 0.55, 0.55, 0.55)
                Behavior on color { ColorAnimation { duration: 160 } }

                transform: Translate { id: shakeT }
                SequentialAnimation {
                    id: shake
                    NumberAnimation { target: shakeT; property: "x"; to: -14; duration: 50; easing.type: Easing.OutQuad }
                    NumberAnimation { target: shakeT; property: "x"; to: 12; duration: 70; easing.type: Easing.InOutQuad }
                    NumberAnimation { target: shakeT; property: "x"; to: -8; duration: 60; easing.type: Easing.InOutQuad }
                    NumberAnimation { target: shakeT; property: "x"; to: 4; duration: 50; easing.type: Easing.InOutQuad }
                    NumberAnimation { target: shakeT; property: "x"; to: 0; duration: 60; easing.type: Easing.OutQuad }
                }

                Icon {
                    id: lockIcon
                    anchors { left: parent.left; leftMargin: 17 * ui.s; verticalCenter: parent.verticalCenter }
                    size: 17 * ui.s
                    name: "lock"
                    fill: 1
                    color: Qt.rgba(1, 1, 1, 0.75)
                }

                TextInput {
                    id: field
                    anchors { left: lockIcon.right; leftMargin: 11 * ui.s; right: go.left; rightMargin: 8 * ui.s; verticalCenter: parent.verticalCenter }
                    focus: true
                    enabled: !ui.leaving
                    echoMode: TextInput.Password
                    passwordMaskDelay: 0
                    color: "transparent"
                    selectionColor: "transparent"
                    cursorDelegate: Item {}
                    font { family: ui.font; pixelSize: 14 * ui.s; letterSpacing: 2 }
                    clip: true
                    onAccepted: ui.submit()
                    onTextChanged: if (text !== "") ui.message = ""
                    Keys.onEscapePressed: text = ""

                    PasswordDots {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width
                        count: field.length
                        cursor: field.cursorPosition
                        caretVisible: field.activeFocus
                        dotSize: 8 * ui.s
                        spacing: 6 * ui.s
                        color: ui.fg
                    }

                    Text {
                        x: 6 * ui.s
                        visible: field.text === ""
                        anchors.verticalCenter: parent.verticalCenter
                        text: authenticator.graceLocked ? "Locked for a moment…" : "Enter your password"
                        color: Qt.rgba(1, 1, 1, 0.6)
                        font { family: ui.font; pixelSize: 14 * ui.s }
                    }
                }

                Rectangle {
                    id: go
                    anchors { right: parent.right; rightMargin: 6 * ui.s; verticalCenter: parent.verticalCenter }
                    width: 34 * ui.s; height: width; radius: width / 2
                    color: field.text !== "" ? ui.fg : ui.raised
                    Behavior on color { ColorAnimation { duration: 160 } }

                    Icon {
                        anchors.centerIn: parent
                        visible: !busy.running
                        name: "arrow_forward"
                        size: 18 * ui.s
                        color: field.text !== "" ? "black" : ui.fg
                    }
                    Item {
                        id: spinner
                        anchors.centerIn: parent
                        visible: busy.running
                        width: 16 * ui.s; height: width
                        Rectangle { anchors.fill: parent; radius: width / 2; color: "transparent"; border { width: 2; color: Qt.rgba(0, 0, 0, 0.25) } }
                        Rectangle { width: 5 * ui.s; height: width; radius: width / 2; x: parent.width / 2 - width / 2; y: -width / 3; color: "black" }
                        RotationAnimation on rotation { id: busy; running: false; from: 0; to: 360; duration: 800; loops: Animation.Infinite }
                    }
                    MouseArea { anchors.fill: parent; onClicked: ui.submit() }
                }
            }

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 8 * ui.s

                Repeater {
                    model: [
                        { icon: "bedtime", label: "Sleep", act: () => sessions.suspend(), show: sessions.canSuspend },
                        { icon: "switch_account", label: "Switch user", act: () => sessions.switchUser(), show: sessions.canSwitchUser }
                    ]
                    IconButton {
                        required property var modelData
                        visible: modelData.show
                        icon: modelData.icon
                        label: modelData.label
                        onClicked: modelData.act()
                    }
                }
            }

            Text {
                width: parent.width
                height: 16 * ui.s
                horizontalAlignment: Text.AlignHCenter
                text: ui.message
                opacity: text !== "" ? 1 : 0
                color: Qt.rgba(1, 0.8, 0.8, 1)
                font { family: ui.font; pixelSize: 13 * ui.s }
                Behavior on opacity { NumberAnimation { duration: 160 } }
            }
        }
    }

    component Card: Rectangle {
        radius: ui.cardRadius
        color: ui.cardColor
    }

    component WeatherCard: Card {
        id: wc
        readonly property var w: ui.info.weather ?? null

        function iconFor(code): string {
            const night = ui.now.getHours() < 6 || ui.now.getHours() >= 19;
            if (code === 113) return night ? "clear_night" : "sunny";
            if (code === 116) return night ? "partly_cloudy_night" : "partly_cloudy_day";
            if (code === 119 || code === 122) return "cloud";
            if ([143, 248, 260].includes(code)) return "foggy";
            if ([200, 386, 389, 392, 395].includes(code)) return "thunderstorm";
            if ([179, 182, 185, 227, 230, 281, 284, 311, 314, 317, 320, 323, 326, 329, 332, 335, 338, 350,
                 362, 365, 368, 371, 374, 377].includes(code)) return "weather_snowy";
            return "rainy";
        }

        Row {
            anchors.centerIn: parent
            visible: wc.w !== null
            spacing: 18 * ui.s

            Row {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 10 * ui.s
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: (wc.w?.temp ?? "") + "°"
                    color: ui.fg
                    font { family: ui.font; pixelSize: 44 * ui.s; weight: Font.Medium }
                }
                Icon {
                    anchors.verticalCenter: parent.verticalCenter
                    size: 36 * ui.s
                    fill: 1
                    name: wc.iconFor(wc.w?.code ?? 113)
                }
            }
            Rectangle { anchors.verticalCenter: parent.verticalCenter; width: 1; height: 50 * ui.s; color: Qt.rgba(1, 1, 1, 0.14) }
            Column {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 3 * ui.s
                Text { text: wc.w?.desc ?? ""; color: ui.fg; font { family: ui.font; pixelSize: 15 * ui.s; weight: Font.Medium } }
                Text { text: "Feels like " + (wc.w?.feels ?? "") + "°"; color: ui.dim; font { family: ui.font; pixelSize: 12 * ui.s } }
                Text { text: "High " + (wc.w?.high ?? "") + "°  •  Low " + (wc.w?.low ?? "") + "°"; color: ui.dim; font { family: ui.font; pixelSize: 12 * ui.s } }
            }
        }

        Text {
            anchors.centerIn: parent
            visible: wc.w === null
            text: "Weather unavailable"
            color: ui.dim
            font { family: ui.font; pixelSize: 14 * ui.s }
        }
    }

    component FetchCard: Card {
        id: fc

        Row {
            x: 16 * ui.s; y: 16 * ui.s
            spacing: 10 * ui.s
            Rectangle {
                width: 26 * ui.s; height: width; radius: 8 * ui.s
                color: ui.fg
                Text { anchors.centerIn: parent; text: ">"; color: "black"; font { family: ui.font; pixelSize: 14 * ui.s; weight: Font.Bold } }
            }
            Text { anchors.verticalCenter: parent.verticalCenter; text: "sparkyfetch.sh"; color: ui.fg; font { family: ui.font; pixelSize: 14 * ui.s } }
        }

        Row {
            anchors.centerIn: parent
            anchors.verticalCenterOffset: 4 * ui.s
            spacing: 24 * ui.s

            Item {
                anchors.verticalCenter: parent.verticalCenter
                width: 86 * ui.s; height: width
                Image {
                    id: logo
                    anchors.fill: parent
                    source: "file:///usr/share/icons/cachyos.svg"
                    sourceSize: Qt.size(width * 2, height * 2)
                    visible: false
                }
                MultiEffect { anchors.fill: logo; source: logo; brightness: 1; colorization: 1; colorizationColor: ui.fg }
            }

            Grid {
                anchors.verticalCenter: parent.verticalCenter
                columns: 2
                columnSpacing: 10 * ui.s
                rowSpacing: 5 * ui.s
                Repeater {
                    model: [
                        { text: "OS", key: true }, { text: ui.info.os ?? "…", key: false },
                        { text: "KERNEL", key: true }, { text: ui.info.kernel ?? "…", key: false },
                        { text: "HOST", key: true }, { text: ui.info.host ?? "…", key: false },
                        { text: "UP", key: true }, { text: ui.info.uptime ?? "…", key: false }
                    ]
                    Text {
                        required property var modelData
                        text: modelData.text
                        color: modelData.key ? ui.dim : ui.fg
                        elide: Text.ElideRight
                        width: modelData.key ? implicitWidth : Math.min(implicitWidth, 190 * ui.s)
                        font {
                            family: ui.font
                            pixelSize: (modelData.key ? 11 : 14) * ui.s
                            weight: modelData.key ? Font.DemiBold : Font.Normal
                            letterSpacing: modelData.key ? 1.2 * ui.s : 0
                        }
                    }
                }
            }
        }

        Row {
            anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: 18 * ui.s }
            spacing: 10 * ui.s
            Repeater {
                model: 8
                Rectangle {
                    required property int index
                    width: 18 * ui.s; height: width; radius: width / 2
                    color: Qt.rgba(1, 1, 1, 0.08 + index * 0.13)
                }
            }
        }
    }

    component MediaCard: Card {
        id: mc

        Text {
            x: 20 * ui.s; y: 18 * ui.s
            text: "Now playing"
            color: ui.dim
            font { family: ui.font; pixelSize: 13 * ui.s; weight: Font.DemiBold }
        }

        Text {
            anchors.centerIn: parent
            visible: players.count === 0
            text: "Nothing playing"
            color: ui.dim
            font { family: ui.font; pixelSize: 14 * ui.s }
        }

        Repeater {
            id: players
            model: Mpris.MultiplexerModel {}

            Item {
                required property var model
                anchors.fill: parent

                Rounded {
                    id: art
                    anchors { left: parent.left; leftMargin: 20 * ui.s; verticalCenter: parent.verticalCenter; verticalCenterOffset: 10 * ui.s }
                    width: Math.min(parent.height - 90 * ui.s, parent.width * 0.42)
                    height: width
                    radius: 18 * ui.s
                    Rectangle { anchors.fill: parent; color: Qt.rgba(1, 1, 1, 0.08) }
                    Icon { anchors.centerIn: parent; size: 40 * ui.s; name: "music_note"; color: ui.dim; visible: cover.status !== Image.Ready }
                    Image { id: cover; anchors.fill: parent; source: model.artUrl || ""; fillMode: Image.PreserveAspectCrop; asynchronous: true }
                }

                Column {
                    anchors { left: art.right; leftMargin: 18 * ui.s; right: parent.right; rightMargin: 20 * ui.s; verticalCenter: art.verticalCenter }
                    spacing: 4 * ui.s

                    Text {
                        width: parent.width
                        text: model.track || model.identity || ""
                        elide: Text.ElideRight
                        maximumLineCount: 2
                        wrapMode: Text.Wrap
                        color: ui.fg
                        font { family: ui.font; pixelSize: 17 * ui.s; weight: Font.Medium }
                    }
                    Text {
                        width: parent.width
                        text: model.artist || model.identity || ""
                        elide: Text.ElideRight
                        color: ui.dim
                        font { family: ui.font; pixelSize: 13 * ui.s }
                    }

                    Item { width: 1; height: 10 * ui.s }

                    Row {
                        spacing: 8 * ui.s
                        IconButton { icon: "skip_previous"; enabled: model.canGoPrevious; opacity: enabled ? 1 : 0.35; onClicked: model.container.Previous() }
                        IconButton {
                            icon: model.playbackStatus === Mpris.PlaybackStatus.Playing ? "pause" : "play_arrow"
                            solid: true
                            onClicked: model.container.PlayPause()
                        }
                        IconButton { icon: "skip_next"; enabled: model.canGoNext; opacity: enabled ? 1 : 0.35; onClicked: model.container.Next() }
                    }
                }
            }
        }
    }

    component ResourcesCard: Card {
        id: rc
        Row {
            anchors { fill: parent; margins: 12 * ui.s }
            spacing: 12 * ui.s
            Repeater {
                model: [
                    { label: "CPU", value: ui.info.cpu ?? 0, temp: ui.info.temp },
                    { label: "RAM", value: ui.info.mem ?? 0 },
                    { label: "DISK", value: ui.info.disk ?? 0 }
                ]
                Rounded {
                    id: tile
                    required property var modelData
                    width: (parent.width - 24 * ui.s) / 3
                    height: parent.height
                    radius: ui.cardRadius - 12 * ui.s

                    Rectangle { anchors.fill: parent; color: Qt.rgba(1, 1, 1, 0.05) }
                    Rectangle {
                        anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                        height: parent.height * Math.max(0.04, tile.modelData.value)
                        color: Qt.rgba(1, 1, 1, 0.16)
                        Behavior on height { NumberAnimation { duration: 900; easing.type: Easing.OutCubic } }
                    }
                    Column {
                        anchors.centerIn: parent
                        spacing: 2 * ui.s
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: Math.round(tile.modelData.value * 100) + "%"
                            color: ui.fg
                            font { family: ui.font; pixelSize: 30 * ui.s; weight: Font.Medium }
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: tile.modelData.label
                            color: ui.dim
                            font { family: ui.font; pixelSize: 11 * ui.s; weight: Font.DemiBold; letterSpacing: 1.5 * ui.s }
                        }
                    }
                    Rectangle {
                        visible: tile.modelData.temp !== undefined && tile.modelData.temp !== null
                        anchors { top: parent.top; right: parent.right; margins: 8 * ui.s }
                        width: tempText.implicitWidth + 14 * ui.s
                        height: 22 * ui.s
                        radius: height / 2
                        color: Qt.rgba(0, 0, 0, 0.3)
                        Text {
                            id: tempText
                            anchors.centerIn: parent
                            text: (tile.modelData.temp ?? "") + "°C"
                            color: ui.fg
                            font { family: ui.font; pixelSize: 11 * ui.s; weight: Font.Medium }
                        }
                    }
                }
            }
        }
    }

    component CalendarCard: Card {
        id: cal
        readonly property int year: ui.now.getFullYear()
        readonly property int month: ui.now.getMonth()
        readonly property date first: new Date(year, month, 1)
        readonly property real cell: Math.min((width - 40 * ui.s) / 7, (height - 110 * ui.s) / 7)

        Column {
            anchors { fill: parent; margins: 20 * ui.s }
            spacing: 14 * ui.s

            Row {
                Text { id: monthName; text: Qt.formatDate(ui.now, "MMMM"); color: ui.fg; font { family: ui.font; pixelSize: 22 * ui.s; weight: Font.Medium } }
                Text { anchors.baseline: monthName.baseline; leftPadding: 8 * ui.s; text: cal.year; color: ui.dim; font { family: ui.font; pixelSize: 22 * ui.s } }
            }

            Grid {
                anchors.horizontalCenter: parent.horizontalCenter
                columns: 7
                Repeater {
                    model: ["S", "M", "T", "W", "T", "F", "S"]
                    Text {
                        required property string modelData
                        width: cal.cell; height: cal.cell * 0.8
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        text: modelData
                        color: ui.dim
                        font { family: ui.font; pixelSize: 12 * ui.s; weight: Font.DemiBold }
                    }
                }
                Repeater {
                    model: 42
                    Item {
                        id: day
                        required property int index
                        readonly property date d: new Date(cal.year, cal.month, 1 - cal.first.getDay() + index)
                        readonly property bool inMonth: d.getMonth() === cal.month
                        readonly property bool isToday: inMonth && d.getDate() === ui.now.getDate()
                        width: cal.cell; height: cal.cell
                        Rectangle { anchors.centerIn: parent; width: parent.width * 0.78; height: width; radius: width / 2; color: ui.fg; visible: day.isToday }
                        Text {
                            anchors.centerIn: parent
                            text: day.d.getDate()
                            color: day.isToday ? "black" : (day.inMonth ? ui.fg : Qt.rgba(1, 1, 1, 0.22))
                            font { family: ui.font; pixelSize: 14 * ui.s; weight: day.isToday ? Font.Bold : Font.Normal }
                        }
                    }
                }
            }
        }
    }

    component IconButton: Rectangle {
        id: btn
        property string icon
        property string label
        property bool solid: false
        signal clicked()

        width: 40 * ui.s; height: width; radius: width / 2
        color: solid ? (area.pressed ? Qt.rgba(1, 1, 1, 0.8) : ui.fg)
                     : (area.pressed ? Qt.rgba(1, 1, 1, 0.22) : (area.containsMouse ? ui.raised : "transparent"))
        Behavior on color { ColorAnimation { duration: 110 } }

        Icon { anchors.centerIn: parent; name: btn.icon; size: 20 * ui.s; fill: 1; color: btn.solid ? "black" : Qt.rgba(1, 1, 1, 0.85) }

        Rectangle {
            visible: btn.label !== ""
            anchors { horizontalCenter: parent.horizontalCenter; top: parent.bottom; topMargin: 8 * ui.s }
            width: tip.implicitWidth + 18 * ui.s
            height: 24 * ui.s
            radius: height / 2
            color: Qt.rgba(0.04, 0.04, 0.05, 0.86)
            opacity: area.containsMouse ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 110 } }
            Text { id: tip; anchors.centerIn: parent; text: btn.label; color: ui.fg; font { family: ui.font; pixelSize: 12 * ui.s } }
        }

        MouseArea { id: area; anchors.fill: parent; hoverEnabled: true; onClicked: btn.clicked() }
    }
}
