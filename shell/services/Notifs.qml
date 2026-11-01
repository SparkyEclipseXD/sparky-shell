pragma Singleton
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
import QtQuick

Singleton {
    id: root

    readonly property var defaults: ({
        dnd: false,
        criticalBreaksDnd: true,
        position: "top-right",
        timeout: 5,
        maxVisible: 3,
        showBody: true,
        sound: true
    })
    property var prefs: defaults

    readonly property string sound: "/usr/share/sounds/ocean/stereo/message-new-instant.oga"

    property var popups: []

    function set(key, value) {
        const next = Object.assign({}, prefs);
        next[key] = value;
        save(next);
    }

    function save(p) {
        prefs = p;
        file.setText(JSON.stringify(p, null, 2) + "\n");
    }

    function test() {
        Quickshell.execDetached(["notify-send", "-a", "Sparky", "-i", "notifications-symbolic",
                                 "-A", "ok=Looks good", "Notifications are on",
                                 "This is how they look. Change it in Settings → Notifications."]);
    }

    function isSymbolic(p): bool { return p.icon.endsWith("-symbolic") }

    function iconFor(p): string {
        const icon = p.icon;
        if (icon.startsWith("/")) return "file://" + icon;
        if (icon.includes("://")) return icon;
        const themed = icon ? Quickshell.iconPath(icon, true) : "";
        if (themed) return themed;
        const entry = DesktopEntries.heuristicLookup(p.desktopEntry || p.appName);
        return Icons.find(entry, p.desktopEntry, p.appName);
    }

    function show(n, fresh) {
        const critical = n.urgency === NotificationUrgency.Critical;
        if (prefs.dnd && !(critical && prefs.criticalBreaksDnd)) return;

        n.tracked = true;
        popups = [popupComponent.createObject(root, { notif: n }), ...popups];
        popups.filter(p => !p.leaving).slice(prefs.maxVisible).forEach(p => close(p, false));

        if (fresh && prefs.sound && n.urgency !== NotificationUrgency.Low && !n.hints["suppress-sound"])
            Quickshell.execDetached(["pw-play", sound]);
    }

    function close(p, dismissed) {
        if (p.leaving) return;
        p.leaving = true;
        if (p.notif) dismissed ? p.notif.dismiss() : p.notif.expire();
    }

    function closeAll() { popups.forEach(p => close(p, true)) }

    function remove(p) {
        popups = popups.filter(x => x !== p);
        p.destroy(1000);
    }

    function invoke(p, action) {
        if (p.leaving) return;
        action.invoke();
        close(p, true);
    }

    function activate(p) {
        const def = p.allActions.find(a => a.identifier === "default");
        if (def) invoke(p, def);
        else close(p, true);
    }

    component Popup: QtObject {
        id: p

        required property Notification notif
        property bool leaving: false
        property int revision: 0

        property string appName
        property string desktopEntry
        property string summary
        property string body
        property string icon
        property string image
        property bool critical
        property var allActions: []
        readonly property var actions: allActions.filter(a => a.identifier !== "default")

        function sync() {
            appName = notif.appName || "Notification";
            desktopEntry = notif.desktopEntry;
            summary = notif.summary;
            body = notif.body;
            const img = notif.image;
            const named = img.startsWith("image://icon/") ? img.slice(13) : "";
            icon = notif.appIcon || named;
            image = named || img === notif.appIcon ? "" : img;
            critical = notif.urgency === NotificationUrgency.Critical;
            allActions = Array.from(notif.actions);
        }

        Component.onCompleted: sync()

        property Connections watch: Connections {
            target: p.notif
            function onSummaryChanged() { p.sync(); p.revision++ }
            function onBodyChanged() { p.sync(); p.revision++ }
            function onAppIconChanged() { p.sync() }
            function onImageChanged() { p.sync() }
            function onActionsChanged() { p.sync() }
            function onUrgencyChanged() { p.sync() }
            function onClosed(reason) { p.leaving = true }
        }
    }

    Component { id: popupComponent; Popup {} }

    NotificationServer {
        id: server
        bodySupported: true
        bodyMarkupSupported: true
        bodyHyperlinksSupported: true
        actionsSupported: true
        imageSupported: true
        onNotification: n => root.show(n, true)
    }

    Component.onCompleted: server.trackedNotifications.values.forEach(n => show(n, false))

    FileView {
        id: file
        path: Quickshell.env("HOME") + "/.config/sparky/notifications.json"
        atomicWrites: true
        onLoaded: {
            try { root.prefs = Object.assign({}, root.defaults, JSON.parse(text())) }
            catch (e) { console.warn("sparky: bad notifications.json:", e) }
        }
        onLoadFailed: root.save(root.defaults)
    }
}
