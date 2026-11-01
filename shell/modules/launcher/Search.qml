pragma Singleton
import Quickshell
import QtQuick

Singleton {
    readonly property int maxResults: 30

    function score(q, text): real {
        const s = (text || "").toLowerCase();
        if (s.startsWith(q)) return 100 - (s.length - q.length) * 0.1;
        const i = s.indexOf(q);
        if (i >= 0) return 70 - i * 0.5;
        let p = 0;
        for (const c of s)
            if (c === q[p] && ++p === q.length) return 30;
        return -1;
    }

    function entryScore(q, e): real {
        const name = score(q, e.name);
        if (name >= 0) return name;
        const extra = Math.max(score(q, e.genericName), score(q, (e.keywords || []).join(" ")),
                               score(q, e.comment));
        return extra >= 0 ? extra * 0.5 : -1;
    }

    function query(text): var {
        const q = text.trim().toLowerCase();
        const apps = DesktopEntries.applications.values.filter(e => !e.noDisplay);

        if (q === "")
            return apps.sort((a, b) => a.name.localeCompare(b.name)).slice(0, maxResults);

        return apps
            .map(e => ({ e, s: entryScore(q, e) }))
            .filter(r => r.s >= 0)
            .sort((a, b) => b.s - a.s || a.e.name.localeCompare(b.e.name))
            .slice(0, maxResults)
            .map(r => r.e);
    }
}
