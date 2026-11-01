pragma Singleton
import Quickshell

Singleton {
    property bool open: false
    property int tab: 0

    readonly property var tabs: ({ customization: 0, controls: 1, mouse: 2, notifications: 3, wifi: 4, bluetooth: 5 })

    function toggle() { open = !open }

    function showTab(name) {
        tab = tabs[name] ?? 0;
        open = true;
    }
}
