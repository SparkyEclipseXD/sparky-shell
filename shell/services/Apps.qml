pragma Singleton
import Quickshell
import QtQuick

Singleton {
    id: root

    function keyOf(id, entry): string {
        return (entry?.id ?? id ?? "").toLowerCase();
    }

    readonly property var items: {
        const byKey = new Map();

        for (const id of Config.pinned) {
            const entry = DesktopEntries.heuristicLookup(id);
            byKey.set(keyOf(id, entry), { id, entry, windows: [], pinned: true });
        }

        for (const w of Windows.list) {
            const entry = DesktopEntries.heuristicLookup(w.appId) ?? DesktopEntries.heuristicLookup(w.cls);
            const key = keyOf(w.appId, entry);
            let item = byKey.get(key);
            if (!item) {
                item = { id: w.appId, entry, windows: [], pinned: false };
                byKey.set(key, item);
            }
            item.windows.push(w);
        }
        return [...byKey.values()];
    }

    readonly property var pinnedItems: items.filter(i => i.pinned)
    readonly property var openItems: items.filter(i => i.windows.length > 0)

    function iconFor(item): string {
        const w = item.windows[0];
        return Icons.find(item.entry, item.id, w?.appId, w?.cls);
    }

    function activate(item) {
        if (item.windows.length > 0)
            Windows.activate(item.windows[0].id);
        else
            item.entry?.execute();
    }

    function pinnedIdFor(id, entry): string {
        const key = keyOf(id, entry);
        return Config.pinned.find(p => keyOf(p, DesktopEntries.heuristicLookup(p)) === key) ?? "";
    }

    function itemForEntry(entry) {
        return { id: entry.id, entry, windows: [], pinned: pinnedIdFor(entry.id, entry) !== "" };
    }

    function togglePin(item) {
        const pinnedId = pinnedIdFor(item.id, item.entry);
        if (pinnedId !== "")
            Config.unpin(pinnedId);
        else
            Config.pin(item.entry?.id ?? item.id);
    }
}
