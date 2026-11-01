#!/usr/bin/env bash
set -euo pipefail

here="$(cd "$(dirname "$0")" && pwd)"
cfg="${XDG_CONFIG_HOME:-$HOME/.config}"
data="${XDG_DATA_HOME:-$HOME/.local/share}"

say() { printf '\033[1m%s\033[0m\n' "$*"; }
fill() { sed "s|@HOME@|$HOME|g" "$1" > "$2"; }

say "shell → $cfg/quickshell/sparky"
mkdir -p "$cfg/quickshell"
rsync -a "$here/shell/" "$cfg/quickshell/sparky/"
rsync -a --copy-links "$here/greeter/" "$cfg/quickshell/sparky-greeter/"

say "helpers → ~/.local/bin, ~/.local/lib/sparky"
install -Dm755 -t "$HOME/.local/bin" "$here"/bin/*
install -Dm644 -t "$HOME/.local/lib/sparky" "$here"/lib/*

say "blur fix for the GTK apps (libsparkyglass)"
make -C "$here/src/sparky-glass" >/dev/null

say "KWin: window motion, raise script, Alt+Tab theme"
mkdir -p "$data/kwin/effects" "$data/kwin/scripts" "$data/kwin/tabbox" "$data/sparky"
rsync -a "$here/kwin/effects/" "$data/kwin/effects/"
rsync -a "$here/kwin/scripts/" "$data/kwin/scripts/"
rsync -a "$here/kwin/tabbox/" "$data/kwin/tabbox/"
install -Dm644 "$here/kwin/windows/windows.kwinscript.js" "$data/sparky/windows.kwinscript.js"
kwriteconfig6 --file kwinrc --group Plugins --key sparky-motionEnabled true
kwriteconfig6 --file kwinrc --group Plugins --key scaleEnabled false
kwriteconfig6 --file kwinrc --group Plugins --key magiclampEnabled false
kwriteconfig6 --file kwinrc --group Plugins --key sparky-raiseEnabled true
kwriteconfig6 --file kwinrc --group TabBox --key LayoutName sparky
qdbus6 org.kde.KWin /KWin reconfigure >/dev/null 2>&1 || true

say "screen-share picker (portal backend)"
mkdir -p "$data/dbus-1/services" "$data/sparky/portals" "$cfg/xdg-desktop-portal" \
         "$cfg/systemd/user/xdg-desktop-portal.service.d"
fill "$here/dbus/org.freedesktop.impl.portal.desktop.sparky.service" \
     "$data/dbus-1/services/org.freedesktop.impl.portal.desktop.sparky.service"
for f in /usr/share/xdg-desktop-portal/portals/*.portal; do ln -sfn "$f" "$data/sparky/portals/"; done
install -Dm644 "$here/portal/sparky.portal" "$data/sparky/portals/sparky.portal"
install -Dm644 "$here/portal/kde-portals.conf" "$data/sparky/portals/kde-portals.conf"
install -Dm644 "$here/portal/kde-portals.conf" "$cfg/xdg-desktop-portal/kde-portals.conf"
fill "$here/systemd/xdg-desktop-portal-sparky.conf" "$cfg/systemd/user/xdg-desktop-portal.service.d/sparky.conf"
systemctl --user daemon-reload

say "lock screen (KDE shell package) and lock-when-idle"
mkdir -p "$data/plasma/shells"
rsync -a "$here/lockscreen/sparky.desktop/" "$data/plasma/shells/sparky.desktop/"
mkdir -p "$data/plasma/shells/sparky.desktop/contents/fonts"
cp "$here/shell/assets/fonts/MaterialSymbolsRounded.ttf" "$data/plasma/shells/sparky.desktop/contents/fonts/"
f=$(fc-list : file family | grep -m1 'Google Sans Flex' | cut -d: -f1 || true)
[ -n "$f" ] && cp "$f" "$data/plasma/shells/sparky.desktop/contents/fonts/GoogleSansFlex.ttf"
kwriteconfig6 --file plasmashellrc --group Shell --key ShellPackage sparky.desktop
kwriteconfig6 --file kscreenlockerrc --group Daemon --key Autolock true
kwriteconfig6 --file kscreenlockerrc --group Daemon --key Timeout 5
kwriteconfig6 --file kscreenlockerrc --group Daemon --key LockOnResume true

say "login-to-desktop splash"
mkdir -p "$data/plasma/look-and-feel"
rsync -a "$here/splash/sparky.splash/" "$data/plasma/look-and-feel/sparky.splash/"
python3 "$HOME/.local/bin/sparky-splash-sync" || true
kwriteconfig6 --file ksplashrc --group KSplash --key Engine KSplashQML
kwriteconfig6 --file ksplashrc --group KSplash --key Theme sparky.splash

say "launcher entries and autostart"
mkdir -p "$data/applications" "$cfg/autostart"
for f in "$here"/apps/*.desktop; do fill "$f" "$data/applications/$(basename "$f")"; done
install -Dm644 "$here/autostart/sparky.desktop" "$cfg/autostart/sparky.desktop"

say "cursor theme (Breeze Sparky)"
python3 "$here/cursors/make.py"
XCURSOR_PATH="$data/icons:$HOME/.icons:/usr/share/icons" plasma-apply-cursortheme breeze-sparky || true

say "done. Log out and back in, or start it now: qs -c sparky"
