function eligible(w) { return w.normalWindow && !w.skipTaskbar; }

function info(w, z) {
    const g = w.frameGeometry, o = w.output ? w.output.geometry : null;
    return {
        id: w.internalId.toString(),
        appId: w.desktopFileName || w.resourceClass || "",
        cls: w.resourceClass || "",
        caption: w.caption || "",
        active: w === workspace.activeWindow,
        minimized: !!w.minimized,
        maximized: w.maximizeMode === 3,
        fullscreen: !!w.fullScreen,
        output: w.output ? w.output.name : "",
        desktops: w.onAllDesktops ? [] : w.desktops.map(d => d.id),
        geometry: o ? { x: (g.x - o.x) / o.width, y: (g.y - o.y) / o.height,
                        w: g.width / o.width, h: g.height / o.height } : null,
        z: z,
    };
}

function push() {
    const order = workspace.stackingOrder;
    callDBus("org.sparky.Windows", "/", "org.sparky.Windows", "Update",
             JSON.stringify(workspace.windowList().filter(eligible).map(w => info(w, order.indexOf(w)))));
}

function pushDesktops() {
    callDBus("org.sparky.Windows", "/", "org.sparky.Windows", "UpdateDesktops",
             JSON.stringify({
                 current: workspace.currentDesktop.id,
                 desktops: workspace.desktops.map(d => ({ id: d.id, name: d.name })),
             }));
}

function moved(w) { if (!w.move && !w.resize) push(); }

function watch(w) {
    if (!eligible(w)) return;
    w.captionChanged.connect(push);
    w.minimizedChanged.connect(push);
    w.desktopFileNameChanged.connect(push);
    w.maximizedChanged.connect(push);
    w.fullScreenChanged.connect(push);
    w.outputChanged.connect(push);
    w.desktopsChanged.connect(push);
    w.frameGeometryChanged.connect(() => moved(w));
    w.interactiveMoveResizeFinished.connect(push);
}

workspace.windowList().forEach(watch);
workspace.windowAdded.connect(w => { watch(w); push(); });
workspace.windowRemoved.connect(push);
workspace.windowActivated.connect(push);
workspace.currentDesktopChanged.connect(pushDesktops);
workspace.desktopsChanged.connect(() => { pushDesktops(); push(); });
for (const d of workspace.desktops) d.nameChanged.connect(pushDesktops);
workspace.desktopsChanged.connect(() => { for (const d of workspace.desktops) d.nameChanged.connect(pushDesktops); });
push();
pushDesktops();
