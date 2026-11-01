"use strict";

const OPEN = 260, CLOSE = 170, MINIMIZE = 300, RESTORE = 320;

function animated(window) {
    if (window.popupWindow || window.lockScreen || window.outline || !window.managed) return false;
    return window.normalWindow || window.dialog;
}

function forceBlur(window, on) {
    window.setData(Effect.WindowForceBlurRole, on ? true : null);
    window.setData(Effect.WindowForceBackgroundContrastRole, on ? true : null);
}

function dockPoint(window) {
    const s = window.screen ? window.screen.geometry : effects.virtualScreenGeometry;
    return { x: s.x + s.width / 2, y: s.y + s.height - 38 };
}

function dropAnimation(window, name) {
    if (window[name]) {
        cancel(window[name]);
        delete window[name];
    }
}

effect.animationEnded.connect(window => forceBlur(window, false));

effects.windowAdded.connect(window => {
    if (effects.hasActiveFullScreenEffect || !animated(window) || !window.visible) return;
    if (effect.isGrabbed(window, Effect.WindowAddedGrabRole)) return;
    forceBlur(window, true);
    window.openAnimation = animate({
        window: window,
        duration: animationTime(OPEN),
        curve: QEasingCurve.OutQuint,
        animations: [
            { type: Effect.Scale, from: 0.92 },
            { type: Effect.Translation, from: { value1: 0, value2: 16 }, to: { value1: 0, value2: 0 } },
            { type: Effect.Opacity, from: 0, curve: QEasingCurve.OutCubic, duration: animationTime(OPEN * 0.7) }
        ]
    });
});

effects.windowClosed.connect(window => {
    if (effects.hasActiveFullScreenEffect || !animated(window) || !window.visible || window.skipsCloseAnimation) return;
    if (effect.isGrabbed(window, Effect.WindowClosedGrabRole)) return;
    dropAnimation(window, "openAnimation");
    forceBlur(window, true);
    window.closeAnimation = animate({
        window: window,
        duration: animationTime(CLOSE),
        curve: QEasingCurve.InCubic,
        animations: [
            { type: Effect.Scale, to: 0.94 },
            { type: Effect.Translation, from: { value1: 0, value2: 0 }, to: { value1: 0, value2: 10 } },
            { type: Effect.Opacity, to: 0 }
        ]
    });
});

effects.windowDataChanged.connect((window, role) => {
    if (role === Effect.WindowAddedGrabRole && effect.isGrabbed(window, role)) dropAnimation(window, "openAnimation");
    if (role === Effect.WindowClosedGrabRole && effect.isGrabbed(window, role)) dropAnimation(window, "closeAnimation");
});

function intoDock(window) {
    const g = window.geometry, p = dockPoint(window);
    return { value1: p.x - (g.x + g.width / 2), value2: p.y - (g.y + g.height / 2) };
}

function minimized(window) {
    if (effects.hasActiveFullScreenEffect || !animated(window)) return;
    if (window.restoreAnimation && redirect(window.restoreAnimation, Effect.Backward)) return;
    dropAnimation(window, "restoreAnimation");
    dropAnimation(window, "minimizeAnimation");
    forceBlur(window, true);
    window.minimizeAnimation = animate({
        window: window,
        duration: animationTime(MINIMIZE),
        curve: QEasingCurve.InOutCubic,
        keepAlive: false,
        animations: [
            { type: Effect.Scale, to: 0.12 },
            { type: Effect.Translation, from: { value1: 0, value2: 0 }, to: intoDock(window) },
            { type: Effect.Opacity, to: 0, curve: QEasingCurve.InCubic }
        ]
    });
}

function restored(window) {
    if (effects.hasActiveFullScreenEffect || !animated(window)) return;
    if (window.minimizeAnimation && redirect(window.minimizeAnimation, Effect.Backward)) return;
    dropAnimation(window, "minimizeAnimation");
    dropAnimation(window, "restoreAnimation");
    forceBlur(window, true);
    window.restoreAnimation = animate({
        window: window,
        duration: animationTime(RESTORE),
        curve: QEasingCurve.OutQuint,
        keepAlive: false,
        animations: [
            { type: Effect.Scale, from: 0.12 },
            { type: Effect.Translation, from: intoDock(window), to: { value1: 0, value2: 0 } },
            { type: Effect.Opacity, from: 0, curve: QEasingCurve.OutCubic }
        ]
    });
}

function watch(window) {
    window.minimizedChanged.connect(() => window.minimized ? minimized(window) : restored(window));
}

effects.stackingOrder.forEach(watch);
effects.windowAdded.connect(watch);

function desktopsChanged(window) {
    const was = window.wasHere;
    window.wasHere = window.isOnCurrentDesktop;
    if (was || !window.isOnCurrentDesktop || window.minimized) return;
    if (effects.hasActiveFullScreenEffect || !animated(window)) return;
    restored(window);
}

function watchDesktops(window) {
    window.wasHere = window.isOnCurrentDesktop;
    if (window.windowDesktopsChanged) window.windowDesktopsChanged.connect(() => desktopsChanged(window));
}

effects.desktopChanged.connect(() => effects.stackingOrder.forEach(w => { w.wasHere = w.isOnCurrentDesktop; }));
effects.stackingOrder.forEach(watchDesktops);
effects.windowAdded.connect(watchDesktops);
