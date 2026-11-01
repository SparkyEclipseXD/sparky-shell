let boosted = null;

function release() {
    if (boosted && boosted.keepAbove) boosted.keepAbove = false;
    boosted = null;
}

workspace.windowActivated.connect(w => {
    if (w === boosted) return;
    release();
    if (!w || !(w.normalWindow || w.dialog) || w.keepAbove) {
        if (w) workspace.raiseWindow(w);
        return;
    }
    w.keepAbove = true;
    boosted = w;
    workspace.raiseWindow(w);
});

workspace.windowRemoved.connect(w => { if (w === boosted) boosted = null; });
