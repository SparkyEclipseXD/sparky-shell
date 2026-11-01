pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    readonly property string home: Quickshell.env("HOME")
    readonly property string libDir: home + "/.local/share/sparky/wallpapers"
    readonly property string thumbDir: home + "/.cache/sparky/thumbs"
    readonly property int maxHistory: 12
    readonly property var supported: ["png", "jpg", "jpeg", "gif", "mp4"]

    property string current: home + "/Pictures/Wallpapers/herobrine/herobrine-shrine-1080.mp4"
    property var history: []
    property var thumbReady: ({})

    function baseName(path): string { return path.split("/").pop() }
    function ext(path): string { return path.split(".").pop().toLowerCase() }
    function isMoving(path): bool { return ["gif", "mp4"].includes(ext(path)) }
    function kind(path): string { return ext(path) === "mp4" ? "Video" : ext(path) === "gif" ? "GIF" : "Image" }

    function clipFor(path): string {
        return ext(path) === "mp4" && thumbReady[path] ? "file://" + thumbDir + "/" + baseName(path) + ".preview.mp4" : "";
    }

    function previewFor(path): string {
        if (ext(path) === "mp4")
            return thumbReady[path] ? "file://" + thumbDir + "/" + baseName(path) + ".jpg" : "";
        return "file://" + path;
    }

    function pick() { picker.running = true }

    function add(src) {
        if (!supported.includes(ext(src))) return;
        const dest = libDir + "/" + Date.now() + "-" + baseName(src).replace(/\s+/g, "_");
        copier.command = ["sh", "-c",
            'mkdir -p "$1"; for f in "$1"/*; do [ -f "$f" ] && cmp -s -- "$2" "$f" && { echo "$f"; exit 0; }; done; ' +
            'cp -- "$2" "$3" && echo "$3"', "sh", libDir, src, dest];
        copier.running = true;
    }

    function apply(path) {
        if (path === current) return;
        const prev = current;
        history = [prev, ...history.filter(p => p !== prev && p !== path)].slice(0, maxHistory);
        current = path;
        dedupe();
        save();
        run(path);
    }

    property var hashes: ({})

    function same(a, b): bool {
        const ha = hashes[a], hb = hashes[b];
        if (!ha || !hb) return false;
        let diff = 0;
        for (let i = 0; i < 64; i++) if (ha[i] !== hb[i]) diff++;
        return diff <= 6;
    }

    function dedupe() {
        const kept = [];
        for (const p of history)
            if (p !== current && !same(p, current) && !kept.some(k => same(k, p))) kept.push(p);
        if (kept.length === history.length) return;
        history = kept;
        save();
    }

    function forget(path) {
        history = history.filter(p => p !== path);
        save();
    }

    function run(path, restore) {
        ensureThumb(path);
        splashSync.restart();
        const still = thumbDir + "/" + baseName(path) + ".jpg";
        const script = isMoving(path)
            ? (restore ? '[ "$(cat "$HOME/.config/sparky/wallpaper-video" 2>/dev/null)" = "$1" ] && ' +
                         'pgrep -x mpvpaper >/dev/null && exit 0; ' : '') +
              'pkill -x mpvpaper; sleep 0.2; rm -f "$HOME/.config/wallpaper-anim-off"; ' +
              'printf %s "$1" > "$HOME/.config/sparky/wallpaper-video"; ' +
              'setsid -f mpvpaper -l bottom -o "no-audio loop hwdec=auto panscan=1.0" ALL "$1" >/dev/null 2>&1; ' +
              'mkdir -p "$(dirname "$2")"; [ -f "$2" ] || ffmpeg -v error -y -ss 1 -i "$1" -frames:v 1 "$2" || ' +
              'ffmpeg -v error -y -i "$1" -frames:v 1 "$2"; [ -f "$2" ] && plasma-apply-wallpaperimage "$2"'
            : 'pkill -x mpvpaper; plasma-apply-wallpaperimage "$1"';
        Quickshell.execDetached(["sh", "-c", script, "sh", path, still]);
    }

    function save() {
        file.setText(JSON.stringify({ current, history }, null, 2) + "\n");
    }

    property var thumbQueue: []
    property bool thumbBusy: false

    function ensureThumb(path) {
        if ((ext(path) !== "mp4" || thumbReady[path]) && hashes[path]) return;
        if (thumbQueue.includes(path)) return;
        thumbQueue = [...thumbQueue, path];
        if (!thumbBusy) nextThumb();
    }

    function nextThumb() {
        if (thumbQueue.length === 0) return;
        thumbBusy = true;
        const path = thumbQueue[0];
        thumbQueue = thumbQueue.slice(1);
        thumber.path = path;
        thumber.command = ["sh", "-c",
            'mkdir -p "$1"; out="$1/$(basename "$2").jpg"; clip="$1/$(basename "$2").preview.mp4"; ' +
            'case "$2" in *.mp4|*.MP4) ' +
            '{ [ -f "$out" ] || ffmpeg -v error -y -ss 1 -i "$2" -frames:v 1 -vf scale=640:-1 "$out"; } && ' +
            '{ [ -f "$clip" ] || ffmpeg -v error -y -t 8 -i "$2" -an -vf scale=640:-2 ' +
            '-c:v libx264 -preset veryfast -crf 26 -pix_fmt yuv420p "$clip"; } && echo thumb ;; esac; ' +
            'src="$2"; [ -f "$out" ] && src="$out"; ' +
            'echo hash $(ffmpeg -v error -i "$src" -frames:v 1 -vf scale=9:8,format=gray -f rawvideo - | od -An -tu1 -v)',
            "sh", thumbDir, path];
        thumber.running = true;
    }

    Process {
        id: thumber
        property string path
        stdout: StdioCollector {
            onStreamFinished: {
                const path = thumber.path;
                const words = text.split(/\s+/);
                if (words.includes("thumb"))
                    root.thumbReady = Object.assign({}, root.thumbReady, { [path]: true });
                const px = words.slice(words.indexOf("hash") + 1).filter(w => w !== "").map(Number);
                if (words.includes("hash") && px.length === 72) {
                    let bits = "";
                    for (let y = 0; y < 8; y++)
                        for (let x = 0; x < 8; x++) bits += px[y * 9 + x] > px[y * 9 + x + 1] ? "1" : "0";
                    root.hashes = Object.assign({}, root.hashes, { [path]: bits });
                    root.dedupe();
                }
                root.thumbBusy = false;
                Qt.callLater(root.nextThumb);
            }
        }
    }

    Timer {
        id: splashSync
        interval: 8000
        onTriggered: Quickshell.execDetached(["python3", root.home + "/.local/bin/sparky-splash-sync"])
    }

    Process {
        id: copier
        stdout: StdioCollector {
            onStreamFinished: { const f = text.trim(); if (f) root.apply(f) }
        }
    }

    Process {
        id: picker
        command: ["zenity", "--file-selection", "--title=Choose a wallpaper",
                  "--file-filter=Wallpapers | *.png *.jpg *.jpeg *.gif *.mp4 *.PNG *.JPG *.JPEG *.GIF *.MP4"]
        stdout: StdioCollector {
            onStreamFinished: { const f = text.trim(); if (f) root.add(f) }
        }
    }

    FileView {
        id: file
        path: root.home + "/.config/sparky/wallpapers.json"
        atomicWrites: true
        onLoaded: {
            try {
                const d = JSON.parse(text());
                if (d.current) root.current = d.current;
                if (Array.isArray(d.history)) root.history = d.history;
            } catch (e) { console.warn("sparky: bad wallpapers.json:", e) }
            root.run(root.current, true);
            root.history.forEach(p => root.ensureThumb(p));
        }
        onLoadFailed: { root.save(); root.ensureThumb(root.current) }
    }
}
