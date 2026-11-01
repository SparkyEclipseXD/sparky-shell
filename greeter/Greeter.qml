import Quickshell
import Quickshell.Widgets
import QtQuick
import QtQuick.Effects
import QtMultimedia
import "theme"

FloatingWindow {
    id: win

    required property var greeter

    implicitWidth: screen?.width ?? 1920
    implicitHeight: screen?.height ?? 1080
    color: "black"
    title: "Sparky Login"

    readonly property real s: Math.min(width, height) / 1080
    readonly property real panelW: Math.min(width - 48, Math.min(width, height) * 0.7 * 16 / 9)
    readonly property real panelH: Math.min(width, height) * 0.7
    readonly property real outerRadius: 42 * s
    readonly property real margin: 16 * s
    readonly property real cardRadius: outerRadius - margin
    readonly property real gap: 16 * s
    readonly property real centreW: 400 * s

    readonly property color cardColor: Qt.rgba(1, 1, 1, 0.065)
    readonly property color raised: Qt.rgba(1, 1, 1, 0.11)
    readonly property color dim: Qt.rgba(1, 1, 1, 0.55)

    property real intro: 0
    NumberAnimation on intro { from: 0; to: 1; duration: 1100; easing.type: Easing.OutQuint }
    function stagger(delay): real { return Math.max(0, Math.min(1, (intro - delay) / (1 - delay))) }

    SystemClock { id: now; precision: SystemClock.Seconds }

    Item {
        id: wallpaper
        anchors.fill: parent

        Image {
            anchors.fill: parent
            source: Qt.resolvedUrl("assets/wallpaper.jpg")
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
        }

        Video {
            anchors.fill: parent
            source: win.greeter.hasVideo ? Qt.resolvedUrl("assets/wallpaper.mp4") : ""
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
        readonly property real t: win.stagger(0)
        width: win.panelW
        height: win.panelH
        anchors.centerIn: parent
        opacity: t * (win.greeter.leaving ? 0 : 1)
        scale: (0.97 + 0.03 * t) * (win.greeter.leaving ? 1.06 : 1)
        Behavior on opacity { enabled: win.greeter.leaving; NumberAnimation { duration: 280; easing.type: Easing.InCubic } }
        Behavior on scale { enabled: win.greeter.leaving; NumberAnimation { duration: 320; easing.type: Easing.InCubic } }

        ClippingRectangle {
            anchors.fill: parent
            radius: win.outerRadius
            color: "transparent"

            ShaderEffectSource {
                id: behind
                anchors.fill: parent
                sourceItem: wallpaper
                sourceRect: Qt.rect((win.width - panel.width) / 2, (win.height - panel.height) / 2, panel.width, panel.height)
                live: true
                visible: false
            }

            MultiEffect {
                anchors.fill: parent
                source: behind
                blurEnabled: true
                blur: 1
                blurMax: 64
                saturation: -0.2
            }

            Rectangle { anchors.fill: parent; color: Qt.rgba(0.02, 0.02, 0.03, 0.42) }
        }

        Column {
            id: left
            readonly property real t: win.stagger(0.15)
            readonly property real pool: panel.height - 2 * win.margin - 2 * win.gap
            x: win.margin - (1 - t) * 30
            y: win.margin
            width: (panel.width - 2 * win.margin - win.centreW - 2 * 40 * win.s) / 2
            spacing: win.gap
            opacity: t

            WeatherCard { width: left.width; height: Math.round(left.pool * 0.18) }
            FetchCard { width: left.width; height: Math.round(left.pool * 0.35) }
            SessionCard { width: left.width; height: left.pool - Math.round(left.pool * 0.18) - Math.round(left.pool * 0.35) }
        }

        Column {
            id: right
            readonly property real t: win.stagger(0.15)
            readonly property real pool: panel.height - 2 * win.margin - win.gap
            x: panel.width - win.margin - width + (1 - t) * 30
            y: win.margin
            width: left.width
            spacing: win.gap
            opacity: t

            ResourcesCard { width: right.width; height: Math.round(right.pool * 0.23) }
            CalendarCard { width: right.width; height: right.pool - Math.round(right.pool * 0.23) }
        }

        Column {
            id: centre
            readonly property real t: win.stagger(0.08)
            readonly property real avatarSize: Math.min(win.centreW * 0.85, (panel.height - 2 * win.margin) * 0.36)
            anchors.horizontalCenter: parent.horizontalCenter
            y: (panel.height - implicitHeight) / 2 + (1 - t) * 24
            width: win.centreW
            spacing: 18 * win.s
            opacity: t

            Column {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 6 * win.s

                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 10 * win.s

                    Text {
                        id: hours
                        text: Qt.formatTime(now.date, "hh AP").split(" ")[0]
                        color: Theme.fg
                        font { family: Theme.font; pixelSize: 132 * win.s; weight: Font.Medium; letterSpacing: -4 * win.s }
                    }

                    Column {
                        anchors.verticalCenter: hours.verticalCenter
                        anchors.verticalCenterOffset: 4 * win.s
                        spacing: 6 * win.s

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: Qt.formatTime(now.date, "mm")
                            color: Qt.rgba(1, 1, 1, 0.82)
                            font { family: Theme.font; pixelSize: 56 * win.s; weight: Font.Medium }
                        }

                        Rectangle {
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: ampm.implicitWidth + 16 * win.s
                            height: 34 * win.s
                            radius: 10 * win.s
                            color: win.raised

                            Text {
                                id: ampm
                                anchors.centerIn: parent
                                text: now.date.getHours() >= 12 ? "PM" : "AM"
                                color: Theme.fg
                                font { family: Theme.font; pixelSize: 24 * win.s; weight: Font.Medium }
                            }
                        }
                    }
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Qt.formatDate(now.date, "dddd  •  d MMM").toUpperCase()
                    color: Qt.rgba(1, 1, 1, 0.85)
                    font { family: Theme.font; pixelSize: 19 * win.s; weight: Font.DemiBold; letterSpacing: 2.5 * win.s }
                }
            }

            Item {
                anchors.horizontalCenter: parent.horizontalCenter
                width: centre.avatarSize
                height: centre.avatarSize

                ClippingRectangle {
                    anchors.fill: parent
                    radius: width * 0.32
                    color: Qt.rgba(1, 1, 1, 0.1)

                    Text {
                        anchors.centerIn: parent
                        visible: face.status !== Image.Ready
                        text: (win.greeter.user.real || "?")[0].toUpperCase()
                        color: Theme.fg
                        font { family: Theme.font; pixelSize: centre.avatarSize * 0.42; weight: Font.Medium }
                    }

                    Image {
                        id: face
                        anchors.fill: parent
                        source: Qt.resolvedUrl("assets/avatar.png")
                        fillMode: Image.PreserveAspectCrop
                        sourceSize: Qt.size(width * 2, height * 2)
                        smooth: true
                        mipmap: true
                    }
                }
            }

            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                width: greetRow.implicitWidth + 32 * win.s
                height: 38 * win.s
                radius: height / 2
                color: greetArea.containsMouse && win.greeter.users.length > 1 ? win.raised : win.cardColor
                Behavior on color { ColorAnimation { duration: Theme.animFast } }

                readonly property int hour: now.date.getHours()

                Row {
                    id: greetRow
                    anchors.centerIn: parent
                    spacing: 9 * win.s

                    Symbol {
                        anchors.verticalCenter: parent.verticalCenter
                        size: 16 * win.s
                        name: parent.parent.hour >= 6 && parent.parent.hour < 19 ? "weather-clear-symbolic" : "weather-clear-night-symbolic"
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        textFormat: Text.StyledText
                        text: {
                            const h = parent.parent.hour;
                            const part = h < 5 ? "Good night" : h < 12 ? "Good morning" : h < 18 ? "Good afternoon" : "Good evening";
                            return part + ", <b>" + (win.greeter.user.real || "").split(" ")[0] + "</b>";
                        }
                        color: Qt.rgba(1, 1, 1, 0.85)
                        font { family: Theme.font; pixelSize: 15 * win.s }
                    }
                }

                MouseArea {
                    id: greetArea
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: if (win.greeter.users.length > 1)
                        win.greeter.userIndex = (win.greeter.userIndex + 1) % win.greeter.users.length
                }
            }

            Rectangle {
                id: pill
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.horizontalCenterOffset: shakeX
                width: 300 * win.s
                height: 46 * win.s
                radius: height / 2
                color: field.activeFocus ? win.raised : win.cardColor
                border.width: win.greeter.message !== "" && !win.greeter.busy ? 1 : 0
                border.color: Qt.rgba(1, 0.55, 0.55, 0.55)
                Behavior on color { ColorAnimation { duration: Theme.animNormal } }

                property real shakeX: 0
                SequentialAnimation {
                    id: shake
                    NumberAnimation { target: pill; property: "shakeX"; to: -14; duration: 50; easing.type: Easing.OutQuad }
                    NumberAnimation { target: pill; property: "shakeX"; to: 12; duration: 70; easing.type: Easing.InOutQuad }
                    NumberAnimation { target: pill; property: "shakeX"; to: -8; duration: 60; easing.type: Easing.InOutQuad }
                    NumberAnimation { target: pill; property: "shakeX"; to: 4; duration: 50; easing.type: Easing.InOutQuad }
                    NumberAnimation { target: pill; property: "shakeX"; to: 0; duration: 60; easing.type: Easing.OutQuad }
                }
                Connections { target: win.greeter; function onFailed() { shake.restart(); field.text = ""; } }

                Symbol {
                    id: lock
                    anchors { left: parent.left; leftMargin: 18 * win.s; verticalCenter: parent.verticalCenter }
                    size: 15 * win.s
                    name: "object-locked-symbolic"
                    color: Qt.rgba(1, 1, 1, 0.75)
                }

                TextInput {
                    id: field
                    anchors { left: lock.right; leftMargin: 11 * win.s; right: go.left; rightMargin: 8 * win.s; verticalCenter: parent.verticalCenter }
                    focus: true
                    enabled: !win.greeter.busy && !win.greeter.leaving
                    echoMode: TextInput.Password
                    passwordMaskDelay: 0
                    color: "transparent"
                    selectionColor: "transparent"
                    cursorDelegate: Item {}
                    font { family: Theme.font; pixelSize: 14 * win.s; letterSpacing: 2 }
                    clip: true
                    onAccepted: win.greeter.login(text)
                    onTextChanged: if (text !== "") win.greeter.message = ""
                    Keys.onEscapePressed: {
                        if (!win.greeter.live) Qt.quit();
                        else text = "";
                    }

                    PasswordDots {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width
                        count: field.length
                        cursor: field.cursorPosition
                        caretVisible: field.activeFocus
                        dotSize: 8 * win.s
                        spacing: 6 * win.s
                        color: Theme.fg
                    }

                    Text {
                        x: 6 * win.s
                        visible: field.text === ""
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Enter your password"
                        color: Qt.rgba(1, 1, 1, 0.6)
                        font { family: Theme.font; pixelSize: 14 * win.s }
                    }
                }

                Rectangle {
                    id: go
                    anchors { right: parent.right; rightMargin: 6 * win.s; verticalCenter: parent.verticalCenter }
                    width: 34 * win.s; height: width; radius: width / 2
                    color: field.text !== "" ? Theme.fg : win.raised
                    Behavior on color { ColorAnimation { duration: Theme.animNormal } }

                    Symbol {
                        anchors.centerIn: parent
                        visible: !win.greeter.busy
                        name: "go-next-symbolic"
                        size: 16 * win.s
                        color: field.text !== "" ? "black" : Theme.fg
                    }

                    Rectangle {
                        anchors.centerIn: parent
                        visible: win.greeter.busy
                        width: 16 * win.s; height: width; radius: width / 2
                        color: "transparent"
                        border { width: 2; color: Qt.rgba(0, 0, 0, 0.25) }
                        Rectangle { width: 5 * win.s; height: width; radius: width / 2; x: parent.width / 2 - width / 2; y: -width / 3; color: "black" }
                        RotationAnimation on rotation { running: win.greeter.busy; from: 0; to: 360; duration: 800; loops: Animation.Infinite }
                    }

                    MouseArea { anchors.fill: parent; onClicked: win.greeter.login(field.text) }
                }
            }

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 8 * win.s

                Repeater {
                    model: [
                        { icon: "system-suspend-symbolic", label: "Sleep", action: "suspend" },
                        { icon: "system-reboot-symbolic", label: "Restart", action: "reboot" },
                        { icon: "system-shutdown-symbolic", label: "Shut down", action: "poweroff" }
                    ]

                    IconButton {
                        required property var modelData
                        icon: modelData.icon
                        label: modelData.label
                        onClicked: win.greeter.power(modelData.action)
                    }
                }
            }

            Text {
                width: parent.width
                height: 16 * win.s
                horizontalAlignment: Text.AlignHCenter
                text: win.greeter.message
                opacity: text !== "" ? 1 : 0
                elide: Text.ElideRight
                color: Qt.rgba(1, 0.8, 0.8, 1)
                font { family: Theme.font; pixelSize: 13 * win.s }
                Behavior on opacity { NumberAnimation { duration: Theme.animNormal } }
            }
        }
    }

    Rectangle {
        visible: !win.greeter.live
        anchors { top: parent.top; right: parent.right; margins: 20 }
        width: badge.implicitWidth + 28
        height: 30
        radius: 15
        color: Qt.rgba(0, 0, 0, 0.5)
        Text {
            id: badge
            anchors.centerIn: parent
            text: "Preview · Esc to close"
            color: Theme.fgDim
            font { family: Theme.font; pixelSize: 12 }
        }
    }

    TapHandler { onTapped: field.forceActiveFocus() }

    Rectangle {
        anchors.fill: parent
        color: "black"
        opacity: win.greeter.leaving ? 1 : 0
        Behavior on opacity { SequentialAnimation { PauseAnimation { duration: 260 } NumberAnimation { duration: 340; easing.type: Easing.InOutQuad } } }
    }
    }

    component Card: Rectangle {
        radius: win.cardRadius
        color: win.cardColor
    }

    component WeatherCard: Card {
        id: wc
        readonly property var w: win.greeter.weather

        function iconFor(code): string {
            const night = now.date.getHours() < 6 || now.date.getHours() >= 19;
            if (code === 113) return night ? "weather-clear-night-symbolic" : "weather-clear-symbolic";
            if (code === 116) return night ? "weather-few-clouds-night-symbolic" : "weather-few-clouds-symbolic";
            if (code === 119 || code === 122) return "weather-overcast-symbolic";
            if ([143, 248, 260].includes(code)) return "weather-fog-symbolic";
            if ([200, 386, 389, 392, 395].includes(code)) return "weather-storm-symbolic";
            if ([179, 182, 185, 227, 230, 281, 284, 311, 314, 317, 320, 323, 326, 329, 332, 335, 338, 350,
                 362, 365, 368, 371, 374, 377].includes(code)) return "weather-snow-symbolic";
            return "weather-showers-symbolic";
        }

        Row {
            anchors.centerIn: parent
            visible: wc.w !== null
            spacing: 18 * win.s

            Row {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 10 * win.s

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: (wc.w?.temp ?? "") + "°"
                    color: Theme.fg
                    font { family: Theme.font; pixelSize: 44 * win.s; weight: Font.Medium }
                }

                Symbol {
                    anchors.verticalCenter: parent.verticalCenter
                    size: 34 * win.s
                    name: wc.iconFor(wc.w?.code ?? 113)
                }
            }

            Rectangle { anchors.verticalCenter: parent.verticalCenter; width: 1; height: 50 * win.s; color: Qt.rgba(1, 1, 1, 0.14) }

            Column {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 3 * win.s

                Text {
                    text: wc.w?.desc ?? ""
                    color: Theme.fg
                    font { family: Theme.font; pixelSize: 15 * win.s; weight: Font.Medium }
                }
                Text {
                    text: "Feels like " + (wc.w?.feels ?? "") + "°"
                    color: win.dim
                    font { family: Theme.font; pixelSize: 12 * win.s }
                }
                Text {
                    text: "High " + (wc.w?.high ?? "") + "°  •  Low " + (wc.w?.low ?? "") + "°"
                    color: win.dim
                    font { family: Theme.font; pixelSize: 12 * win.s }
                }
            }
        }

        Text {
            anchors.centerIn: parent
            visible: wc.w === null
            text: "Weather unavailable"
            color: win.dim
            font { family: Theme.font; pixelSize: 14 * win.s }
        }
    }

    component FetchCard: Card {
        id: fc
        readonly property var st: win.greeter.stats

        Row {
            x: 16 * win.s; y: 16 * win.s
            spacing: 10 * win.s

            Rectangle {
                width: 26 * win.s; height: width; radius: 8 * win.s
                color: Theme.fg
                Text {
                    anchors.centerIn: parent
                    text: ">"
                    color: "black"
                    font { family: Theme.font; pixelSize: 14 * win.s; weight: Font.Bold }
                }
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "sparkyfetch.sh"
                color: Theme.fg
                font { family: Theme.font; pixelSize: 14 * win.s }
            }
        }

        Row {
            anchors.centerIn: parent
            anchors.verticalCenterOffset: 4 * win.s
            spacing: 24 * win.s

            Item {
                anchors.verticalCenter: parent.verticalCenter
                width: 86 * win.s; height: width

                Image {
                    id: logo
                    anchors.fill: parent
                    source: "file:///usr/share/icons/cachyos.svg"
                    sourceSize: Qt.size(width * 2, height * 2)
                    visible: false
                }
                MultiEffect {
                    anchors.fill: logo
                    source: logo
                    brightness: 1
                    colorization: 1
                    colorizationColor: Theme.fg
                }
            }

            Grid {
                anchors.verticalCenter: parent.verticalCenter
                columns: 2
                columnSpacing: 10 * win.s
                rowSpacing: 5 * win.s

                Repeater {
                    model: [
                        { text: "OS", key: true }, { text: fc.st.os ?? "…", key: false },
                        { text: "KERNEL", key: true }, { text: fc.st.kernel ?? "…", key: false },
                        { text: "HOST", key: true }, { text: fc.st.host ?? "…", key: false },
                        { text: "UP", key: true }, { text: fc.st.uptime ?? "…", key: false }
                    ]

                    Text {
                        required property var modelData
                        text: modelData.text
                        color: modelData.key ? win.dim : Theme.fg
                        elide: Text.ElideRight
                        width: modelData.key ? implicitWidth : Math.min(implicitWidth, 190 * win.s)
                        font {
                            family: Theme.font
                            pixelSize: (modelData.key ? 11 : 14) * win.s
                            weight: modelData.key ? Font.DemiBold : Font.Normal
                            letterSpacing: modelData.key ? 1.2 * win.s : 0
                        }
                    }
                }
            }
        }

        Row {
            anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: 18 * win.s }
            spacing: 10 * win.s

            Repeater {
                model: 8
                Rectangle {
                    required property int index
                    width: 18 * win.s; height: width; radius: width / 2
                    color: Qt.rgba(1, 1, 1, 0.08 + index * 0.13)
                }
            }
        }
    }

    component SessionCard: Card {
        id: sc

        Text {
            id: sessionTitle
            x: 20 * win.s; y: 18 * win.s
            text: "Session"
            color: win.dim
            font { family: Theme.font; pixelSize: 13 * win.s; weight: Font.DemiBold; letterSpacing: 0.5 * win.s }
        }

        Column {
            anchors { top: sessionTitle.bottom; topMargin: 12 * win.s; left: parent.left; right: parent.right; margins: 10 * win.s }
            spacing: 4 * win.s

            Repeater {
                model: win.greeter.sessions

                Rectangle {
                    id: option
                    required property var modelData
                    required property int index
                    readonly property bool current: index === win.greeter.sessionIndex
                    width: parent.width
                    height: 52 * win.s
                    radius: win.cardRadius - 10 * win.s
                    color: current ? Qt.rgba(1, 1, 1, 0.13) : (optArea.containsMouse ? Qt.rgba(1, 1, 1, 0.05) : "transparent")
                    Behavior on color { ColorAnimation { duration: Theme.animFast } }

                    Rectangle {
                        id: badgeIcon
                        anchors { left: parent.left; leftMargin: 10 * win.s; verticalCenter: parent.verticalCenter }
                        width: 34 * win.s; height: width; radius: 11 * win.s
                        color: option.current ? Theme.fg : Qt.rgba(1, 1, 1, 0.08)
                        Behavior on color { ColorAnimation { duration: Theme.animNormal } }

                        Text {
                            anchors.centerIn: parent
                            text: option.modelData.name[0]
                            color: option.current ? "black" : Theme.fg
                            font { family: Theme.font; pixelSize: 15 * win.s; weight: Font.Bold }
                        }
                    }

                    Column {
                        anchors { left: badgeIcon.right; leftMargin: 12 * win.s; verticalCenter: parent.verticalCenter }
                        spacing: 1

                        Text {
                            text: option.modelData.name
                            color: option.current ? Theme.fg : Qt.rgba(1, 1, 1, 0.78)
                            font { family: Theme.font; pixelSize: 14 * win.s; weight: option.current ? Font.Medium : Font.Normal }
                        }
                        Text {
                            text: option.modelData.id.includes("uwsm") ? "Managed by uwsm"
                                : option.modelData.id === "plasma" ? "KDE Plasma desktop" : "Wayland session"
                            color: win.dim
                            font { family: Theme.font; pixelSize: 11 * win.s }
                        }
                    }

                    Rectangle {
                        anchors { right: parent.right; rightMargin: 16 * win.s; verticalCenter: parent.verticalCenter }
                        width: 8 * win.s; height: width; radius: width / 2
                        color: Theme.fg
                        opacity: option.current ? 1 : 0
                        scale: option.current ? 1 : 0.3
                        Behavior on opacity { NumberAnimation { duration: Theme.animNormal } }
                        Behavior on scale { NumberAnimation { duration: 220; easing.type: Easing.OutBack } }
                    }

                    MouseArea {
                        id: optArea
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                            win.greeter.sessionIndex = option.index;
                            field.forceActiveFocus();
                        }
                    }
                }
            }
        }
    }

    component ResourcesCard: Card {
        id: rc
        readonly property var st: win.greeter.stats

        Row {
            anchors { fill: parent; margins: 12 * win.s }
            spacing: 12 * win.s

            Repeater {
                model: [
                    { label: "CPU", value: rc.st.cpu ?? 0, temp: rc.st.temp },
                    { label: "RAM", value: rc.st.mem ?? 0 },
                    { label: "DISK", value: rc.st.disk ?? 0 }
                ]

                ClippingRectangle {
                    id: tile
                    required property var modelData
                    width: (parent.width - 24 * win.s) / 3
                    height: parent.height
                    radius: win.cardRadius - 12 * win.s
                    color: Qt.rgba(1, 1, 1, 0.05)

                    Rectangle {
                        anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                        height: parent.height * Math.max(0.04, tile.modelData.value)
                        color: Qt.rgba(1, 1, 1, 0.16)
                        Behavior on height { NumberAnimation { duration: 900; easing.type: Easing.OutCubic } }
                    }

                    Column {
                        anchors.centerIn: parent
                        spacing: 2 * win.s

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: Math.round(tile.modelData.value * 100) + "%"
                            color: Theme.fg
                            font { family: Theme.font; pixelSize: 30 * win.s; weight: Font.Medium }
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: tile.modelData.label
                            color: win.dim
                            font { family: Theme.font; pixelSize: 11 * win.s; weight: Font.DemiBold; letterSpacing: 1.5 * win.s }
                        }
                    }

                    Rectangle {
                        visible: tile.modelData.temp !== undefined && tile.modelData.temp !== null
                        anchors { top: parent.top; right: parent.right; margins: 8 * win.s }
                        width: tempText.implicitWidth + 14 * win.s
                        height: 22 * win.s
                        radius: height / 2
                        color: Qt.rgba(0, 0, 0, 0.3)
                        Text {
                            id: tempText
                            anchors.centerIn: parent
                            text: (tile.modelData.temp ?? "") + "°C"
                            color: Theme.fg
                            font { family: Theme.font; pixelSize: 11 * win.s; weight: Font.Medium }
                        }
                    }
                }
            }
        }
    }

    component CalendarCard: Card {
        id: cal
        readonly property date today: now.date
        readonly property int year: today.getFullYear()
        readonly property int month: today.getMonth()
        readonly property date first: new Date(year, month, 1)
        readonly property real cell: Math.min((width - 40 * win.s) / 7, (height - 110 * win.s) / 7)

        Column {
            anchors { fill: parent; margins: 20 * win.s }
            spacing: 14 * win.s

            Row {
                width: parent.width
                Text {
                    text: Qt.formatDate(cal.today, "MMMM")
                    color: Theme.fg
                    font { family: Theme.font; pixelSize: 22 * win.s; weight: Font.Medium }
                }
                Text {
                    anchors.baseline: parent.children[0].baseline
                    leftPadding: 8 * win.s
                    text: cal.year
                    color: win.dim
                    font { family: Theme.font; pixelSize: 22 * win.s }
                }
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
                        color: win.dim
                        font { family: Theme.font; pixelSize: 12 * win.s; weight: Font.DemiBold }
                    }
                }

                Repeater {
                    model: 42

                    Item {
                        id: day
                        required property int index
                        readonly property date d: new Date(cal.year, cal.month, 1 - cal.first.getDay() + index)
                        readonly property bool inMonth: d.getMonth() === cal.month
                        readonly property bool isToday: inMonth && d.getDate() === cal.today.getDate()
                        width: cal.cell; height: cal.cell

                        Rectangle {
                            anchors.centerIn: parent
                            width: parent.width * 0.78; height: width; radius: width / 2
                            color: Theme.fg
                            visible: day.isToday
                        }

                        Text {
                            anchors.centerIn: parent
                            text: day.d.getDate()
                            color: day.isToday ? "black" : (day.inMonth ? Theme.fg : Qt.rgba(1, 1, 1, 0.22))
                            font { family: Theme.font; pixelSize: 14 * win.s; weight: day.isToday ? Font.Bold : Font.Normal }
                        }
                    }
                }
            }
        }
    }

    component Symbol: Item {
        id: sym
        property string name
        property color color: Theme.fg
        property real size: 18
        implicitWidth: size
        implicitHeight: size

        IconImage {
            id: img
            anchors.fill: parent
            implicitSize: sym.size
            source: Quickshell.iconPath(sym.name, true)
            visible: false
        }
        MultiEffect {
            anchors.fill: img
            source: img
            colorization: 1
            colorizationColor: sym.color
        }
    }

    component IconButton: Rectangle {
        id: btn
        property string icon
        property string label
        signal clicked()

        width: 40 * win.s; height: width; radius: width / 2
        color: area.pressed ? Qt.rgba(1, 1, 1, 0.22) : (area.containsMouse ? win.raised : "transparent")
        Behavior on color { ColorAnimation { duration: Theme.animFast } }

        Symbol { anchors.centerIn: parent; name: btn.icon; size: 17 * win.s; color: Qt.rgba(1, 1, 1, 0.85) }

        Rectangle {
            anchors { horizontalCenter: parent.horizontalCenter; top: parent.bottom; topMargin: 8 * win.s }
            width: tip.implicitWidth + 18 * win.s
            height: 24 * win.s
            radius: height / 2
            color: Qt.rgba(0.04, 0.04, 0.05, 0.86)
            opacity: area.containsMouse ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: Theme.animFast } }
            Text {
                id: tip
                anchors.centerIn: parent
                text: btn.label
                color: Theme.fg
                font { family: Theme.font; pixelSize: 12 * win.s }
            }
        }

        MouseArea {
            id: area
            anchors.fill: parent
            hoverEnabled: true
            onClicked: btn.clicked()
        }
    }
}
