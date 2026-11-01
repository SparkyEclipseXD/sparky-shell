pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    readonly property var items: ({
        desktops: { label: "Desktops", icon: "view_week" },
        clock: { label: "Clock", icon: "schedule" },
        date: { label: "Date", icon: "calendar_today" },
        wifi: { label: "Wi-Fi", icon: "wifi" },
        bluetooth: { label: "Bluetooth", icon: "bluetooth" },
        notifications: { label: "Notifications", icon: "notifications" }
    })
    readonly property var defaults: ({ left: ["desktops"], center: ["clock", "date"], right: ["wifi", "bluetooth", "notifications"], hidden: [] })
    property var layout: defaults
    property bool enabled: true
    property int spacing: 4

    function setEnabled(on) {
        enabled = on;
        write();
    }

    function setSpacing(px) {
        spacing = Math.max(0, Math.min(24, Math.round(px)));
        write();
    }

    function zoneOf(id): string {
        for (const z of ["left", "center", "right", "hidden"]) if ((layout[z] ?? []).includes(id)) return z;
        return "";
    }

    function place(id, zone, index) {
        const next = { left: [...layout.left], center: [...layout.center], right: [...layout.right],
                       hidden: [...(layout.hidden ?? [])] };
        for (const z in next) next[z] = next[z].filter(x => x !== id);
        const list = next[zone];
        list.splice(Math.max(0, Math.min(list.length, index)), 0, id);
        save(next);
    }

    function reset() {
        enabled = true;
        spacing = 4;
        save(defaults);
    }

    function save(l) {
        layout = l;
        write();
    }

    function write() {
        file.setText(JSON.stringify(Object.assign({ enabled, spacing }, layout), null, 2) + "\n");
    }

    FileView {
        id: file
        path: Quickshell.env("HOME") + "/.config/sparky/topbar.json"
        atomicWrites: true
        onLoaded: {
            try {
                const d = JSON.parse(text());
                const l = { left: d.left || [], center: d.center || [], right: d.right || [], hidden: d.hidden || [] };
                for (const z in root.defaults)
                    for (const id of root.defaults[z])
                        if (!["left", "center", "right", "hidden"].some(k => l[k].includes(id))) l[z].push(id);
                root.layout = l;
                if (typeof d.enabled === "boolean") root.enabled = d.enabled;
                if (typeof d.spacing === "number") root.spacing = d.spacing;
            } catch (e) { console.warn("sparky: bad topbar.json:", e) }
        }
        onLoadFailed: root.save(root.defaults)
    }
}
