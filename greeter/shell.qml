import Quickshell
import Quickshell.Io
import Quickshell.Services.Greetd
import QtQuick
import "theme"

ShellRoot {
    id: root

    readonly property bool live: Greetd.available
    readonly property string statePath: live ? "/var/lib/sparky-greeter/state.json"
                                             : Quickshell.env("HOME") + "/.cache/sparky/greeter-state.json"

    property var users: []
    property int userIndex: 0
    property var sessions: []
    property int sessionIndex: 0
    property bool hasVideo: false

    readonly property var user: users[userIndex] ?? { name: "", real: "" }
    readonly property var session: sessions[sessionIndex] ?? null

    property bool busy: false
    property bool leaving: false
    property string message: ""
    property string pending: ""
    signal failed()

    function login(password) {
        if (busy || leaving || !user.name) return;
        if (!live) { fail("Preview only, not connected to greetd"); return; }
        busy = true;
        message = "";
        pending = password;
        Greetd.createSession(user.name);
    }

    function fail(text) {
        pending = "";
        busy = false;
        message = text;
        if (live && Greetd.state !== GreetdState.Inactive) Greetd.cancelSession();
        failed();
    }

    function launch() {
        const s = session;
        if (!s) { fail("No desktop session found"); return; }
        state.setText(JSON.stringify({ user: user.name, session: s.id }) + "\n");
        const cmd = s.exec.split(/\s+/).filter(w => w && !/^%[a-zA-Z]$/.test(w));
        Greetd.launch(cmd, [
            "XDG_SESSION_TYPE=wayland",
            "XDG_SESSION_DESKTOP=" + s.id,
            "XDG_CURRENT_DESKTOP=" + s.desktop
        ], true);
    }

    function power(action) {
        if (live) Quickshell.execDetached(["systemctl", action]);
        else message = "Preview: would run systemctl " + action;
    }

    Connections {
        target: Greetd
        function onAuthMessage(text, error, responseRequired, echoResponse) {
            if (responseRequired) {
                Greetd.respond(root.pending);
                root.pending = "";
            } else if (error) {
                root.message = text;
            } else {
                Greetd.respond("");
            }
        }
        function onAuthFailure(text) { root.fail("Wrong password, try again") }
        function onError(text) { root.fail(text) }
        function onReadyToLaunch() {
            root.busy = false;
            root.leaving = true;
            handover.start();
        }
    }

    Timer { id: handover; interval: 640; onTriggered: root.launch() }

    Process {
        running: true
        command: ["getent", "passwd"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.users = text.split("\n").map(l => l.split(":"))
                    .filter(f => f.length >= 7 && +f[2] >= 1000 && +f[2] < 60000
                                 && !/(nologin|false)$/.test(f[6]))
                    .map(f => ({ name: f[0], real: f[4].split(",")[0] || f[0] }));
                root.restore();
            }
        }
    }

    Process {
        running: true
        command: ["python3", "-I", "-c", `
import configparser, glob, json, os
out = []
for f in sorted(glob.glob("/usr/share/wayland-sessions/*.desktop")):
    c = configparser.ConfigParser(interpolation=None, strict=False)
    try: c.read(f)
    except Exception: continue
    e = c["Desktop Entry"] if "Desktop Entry" in c else {}
    if e.get("Hidden") == "true" or e.get("NoDisplay") == "true" or not e.get("Exec"): continue
    out.append({"id": os.path.basename(f)[:-8], "name": e.get("Name", ""), "exec": e["Exec"],
                "desktop": e.get("DesktopNames", "").rstrip(";").replace(";", ":")})
print(json.dumps(out))`]
        stdout: StdioCollector {
            onStreamFinished: {
                try { root.sessions = JSON.parse(text) } catch (e) { console.warn("greeter: sessions:", e) }
                const plasma = root.sessions.findIndex(s => s.id === "plasma");
                if (plasma >= 0) root.sessionIndex = plasma;
                root.restore();
            }
        }
    }

    FileView {
        id: state
        path: root.statePath
        atomicWrites: true
        onLoaded: root.restore()
    }

    function restore() {
        let saved = {};
        try { saved = JSON.parse(state.text() || "{}") } catch (e) {}
        const u = users.findIndex(x => x.name === saved.user);
        if (u >= 0) userIndex = u;
        const s = sessions.findIndex(x => x.id === saved.session);
        if (s >= 0) sessionIndex = s;
    }

    FileView {
        path: Qt.resolvedUrl("assets/config.json")
        onLoaded: { try { root.hasVideo = !!JSON.parse(text()).video } catch (e) {} }
    }

    property var stats: ({})
    property var weather: null
    readonly property bool imperial: Qt.locale().measurementSystem !== Locale.MetricSystem

    Process {
        running: true
        command: ["python3", "-I", Qt.resolvedUrl("stats.py").toString().replace("file://", "")]
        stdout: SplitParser {
            onRead: line => { try { root.stats = JSON.parse(line) } catch (e) {} }
        }
    }

    Process {
        id: weatherFetch
        running: true
        command: ["curl", "-sf", "-m", "10", "https://wttr.in/?format=j1"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const d = JSON.parse(text);
                    const c = d.current_condition[0], day = d.weather[0];
                    const u = root.imperial ? "F" : "C";
                    root.weather = {
                        temp: c["temp_" + u], feels: c["FeelsLike" + u],
                        high: day["maxtemp" + u], low: day["mintemp" + u],
                        desc: c.weatherDesc[0].value.trim(), code: +c.weatherCode
                    };
                } catch (e) {}
            }
        }
    }
    Timer {
        interval: root.weather ? 30 * 60 * 1000 : 60 * 1000
        repeat: true
        running: true
        onTriggered: weatherFetch.running = true
    }

    FontLoader { source: Qt.resolvedUrl("assets/GoogleSansFlex.ttf") }

    Variants {
        model: Quickshell.screens
        Greeter { required property var modelData; screen: modelData; greeter: root }
    }
}
