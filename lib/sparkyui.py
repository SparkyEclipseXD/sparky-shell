import os
import sys

_GLASS = os.path.expanduser("~/.local/lib/sparky/libsparkyglass.so")
if os.path.exists(_GLASS) and _GLASS not in os.environ.get("LD_PRELOAD", ""):
    os.environ["LD_PRELOAD"] = ":".join(x for x in (_GLASS, os.environ.get("LD_PRELOAD")) if x)
    os.execv(sys.executable, [sys.executable] + sys.argv)

import gi

gi.require_version("Gtk", "4.0")
gi.require_version("Adw", "1")
from gi.repository import Adw, Gdk, GLib, Graphene, Gtk, Pango, PangoCairo
import math

CSS = """
window, .background, toolbarview, navigation-view, navigation-split-view {
    background: #0c0c0e; color: #f2f2f2; font-family: "Google Sans Flex"; }
window.background { background: rgba(10,10,12,0.68); backdrop-filter: blur(30px); }
window.background.maximized { background: rgba(10,10,12,0.82); }
window toolbarview, window navigation-view, window navigation-split-view,
window navigation-split-view > .content-pane { background: transparent; }
headerbar { background: transparent; box-shadow: none; min-height: 44px; }
headerbar windowcontrols button { background: transparent; color: rgba(255,255,255,0.55); }
headerbar windowcontrols button:hover { background: rgba(255,255,255,0.12); color: #f2f2f2; }
navigation-split-view > .sidebar-pane, .sidebar-pane { background: rgba(255,255,255,0.035); }
navigation-split-view > .sidebar-pane, navigation-split-view > widget.sidebar-pane,
navigation-split-view > .content-pane, navigation-split-view > widget.content-pane {
    border: none; box-shadow: none; outline: none; }
scrollbar, scrollbar trough, scrollbar contents { background: transparent; border: none; box-shadow: none; outline: none; }
scrollbar slider { background: rgba(255,255,255,0.16); border: none; box-shadow: none; outline: none;
    border-radius: 999px; min-width: 4px; min-height: 4px; margin: 3px; transition: background 160ms ease-out; }
scrollbar slider:hover { background: rgba(255,255,255,0.3); }
scrollbar slider:active { background: rgba(255,255,255,0.45); }

.app-title { font-size: 20px; font-weight: 500; margin: 2px 26px 18px; }
list.nav { background: transparent; }
list.nav row { border-radius: 999px; margin: 2px 12px; padding: 0; color: rgba(255,255,255,0.55);
    transition: background 180ms ease-out, color 180ms ease-out; }
list.nav row > box { padding: 11px 16px; }
list.nav row:hover { background: rgba(255,255,255,0.07); color: #f2f2f2; }
list.nav row:selected { background: rgba(255,255,255,0.15); color: #f2f2f2; }
list.nav row label { font-size: 15px; }
.badge { background: #f2f2f2; color: #0c0c0e; border-radius: 999px; padding: 0 8px;
    font-size: 11px; font-weight: 700; min-height: 18px; }
.sidebar-footer { margin: 12px; padding: 14px 16px; border-radius: 18px; background: rgba(255,255,255,0.04); }

.page { padding: 4px 28px 22px 28px; }
.page-title { font-size: 26px; font-weight: 500; }
.page-sub { color: rgba(255,255,255,0.5); font-size: 13px; }
.section-title { color: rgba(255,255,255,0.5); font-size: 13px; font-weight: 600; letter-spacing: 0.4px; }
.dim { color: rgba(255,255,255,0.5); }
.faint { color: rgba(255,255,255,0.3); }
.mono { font-feature-settings: "tnum"; }
.code { font-family: "JetBrainsMono Nerd Font", monospace; font-size: 12px; }

.card { background: rgba(255,255,255,0.05); border-radius: 22px; padding: 18px; }
.card.flush { padding: 0; }
.card.hoverable { transition: background 180ms ease-out; }
.card.hoverable:hover { background: rgba(255,255,255,0.08); }
.card.selected, .card.hoverable.selected { background: rgba(255,255,255,0.13); }
.tile { background: rgba(255,255,255,0.08); border-radius: 16px; }
.chip { background: rgba(255,255,255,0.08); color: rgba(255,255,255,0.75); border-radius: 999px;
    padding: 3px 11px; font-size: 11px; font-weight: 600; }
.stat { background: rgba(255,255,255,0.04); border-radius: 14px; padding: 10px 14px; }
.stat-key { color: rgba(255,255,255,0.5); font-size: 11px; font-weight: 600; letter-spacing: 0.4px; }
.stat-val { font-size: 15px; font-weight: 500; }
.big-value { font-size: 40px; font-weight: 500; }
.log { font-family: "JetBrainsMono Nerd Font", monospace; font-size: 11px; background: rgba(0,0,0,0.35);
    border-radius: 14px; padding: 12px; color: rgba(255,255,255,0.75); }
textview.log text { background: transparent; color: rgba(255,255,255,0.75); }

button { border-radius: 999px; box-shadow: none; transition: background 160ms ease-out, color 160ms ease-out; }
button.soft { background: rgba(255,255,255,0.08); color: #f2f2f2; padding: 8px 18px; font-weight: 500; }
button.soft:hover { background: rgba(255,255,255,0.15); }
button.soft:active { background: rgba(255,255,255,0.22); }
button.primary { background: #f2f2f2; color: #0c0c0e; padding: 8px 20px; font-weight: 600; }
button.primary:hover { background: #ffffff; }
button.primary:active { background: rgba(255,255,255,0.8); }
button.primary:disabled, button.soft:disabled { background: rgba(255,255,255,0.05); color: rgba(255,255,255,0.28); }
button.danger:hover { background: rgba(220,60,60,0.9); color: #ffffff; }
button.circle { background: transparent; color: rgba(255,255,255,0.6); min-width: 34px; min-height: 34px; padding: 0; }
button.circle:hover { background: rgba(255,255,255,0.12); color: #f2f2f2; }
button.circle.danger:hover { background: rgba(220,60,60,0.9); color: #ffffff; }
.reveal { opacity: 0; transition: opacity 160ms ease-out; }
row:hover .reveal, .reveal:focus { opacity: 1; }

button.toggle.filter { background: rgba(255,255,255,0.06); color: rgba(255,255,255,0.6); border-radius: 999px;
    border: none; box-shadow: none; outline: none; min-height: 24px;
    padding: 6px 16px; font-weight: 500; }
button.toggle.filter:hover { background: rgba(255,255,255,0.11); color: #f2f2f2; }
button.toggle.filter:checked { background: #f2f2f2; color: #0c0c0e; }

entry.search, searchentry { background: rgba(255,255,255,0.07); border-radius: 999px; min-height: 40px;
    padding: 0 16px; box-shadow: none; outline: none; color: #f2f2f2; }
searchentry:focus-within, entry.search:focus-within { background: rgba(255,255,255,0.12); }
searchentry > image { color: rgba(255,255,255,0.45); }
searchentry.smooth text { color: transparent; caret-color: transparent; }
searchentry.smooth text placeholder { color: rgba(255,255,255,0.45); }
searchentry.smooth text selection { background: rgba(255,255,255,0.22); color: transparent; }

switch { background: rgba(255,255,255,0.1); border-radius: 999px; }
switch:checked { background: rgba(255,255,255,0.34); }
switch slider { background: #f2f2f2; box-shadow: none; }

progressbar trough { background: rgba(255,255,255,0.08); border-radius: 999px; min-height: 4px; }
progressbar progress { background: #f2f2f2; border-radius: 999px; min-height: 4px; }

list.cards { background: transparent; }
list.cards > row { border-radius: 18px; padding: 0; margin-bottom: 0; background: transparent;
    transition: background 160ms ease-out; }
list.cards > row:hover { background: rgba(255,255,255,0.05); }
list.cards > row > box, list.cards > row > revealer > box { padding: 10px 14px; }
list.plain { background: transparent; }
list.plain > row { padding: 0; background: transparent; }
list.plain > row:hover { background: transparent; }

columnview, columnview listview { background: transparent; }
columnview listview row { border-radius: 12px; margin: 1px 8px; padding: 4px 0; transition: background 120ms ease-out; }
columnview listview row:hover { background: rgba(255,255,255,0.05); }
columnview listview row:selected { background: rgba(255,255,255,0.13); color: #f2f2f2; }
columnview > header { padding: 0 8px; }
columnview > header > button { background: transparent; color: rgba(255,255,255,0.45); font-size: 12px;
    font-weight: 600; letter-spacing: 0.4px; padding: 12px 10px 8px; border: none; box-shadow: none; }
columnview > header > button:hover { color: #f2f2f2; }
columnview > header > button sort-indicator { color: rgba(255,255,255,0.6); }

toast { background: #1b1b1f; color: #f2f2f2; border-radius: 999px; }
dialog.alert sheet, dialog.alert .dialog-contents { background: #141417; border-radius: 28px; }
dialog.alert .message-area .heading { font-weight: 600; }
dialog.alert .response-area button { border-radius: 999px; background: rgba(255,255,255,0.08); margin: 4px; }
dialog.alert .response-area button:hover { background: rgba(255,255,255,0.15); }
dialog.alert .response-area button.destructive { background: rgba(220,60,60,0.85); color: #ffffff; }
popover.background { background: transparent; }
popover > contents { background: rgba(20,20,24,0.97); border-radius: 18px; box-shadow: 0 8px 28px rgba(0,0,0,0.45); }
button.menu-row { border-radius: 12px; padding: 6px 10px; min-width: 190px; }
button.menu-row:hover { background: rgba(255,255,255,0.08); }
menubutton.soft > button, button.soft.popup { background: rgba(255,255,255,0.08); color: #f2f2f2;
    border-radius: 999px; padding: 6px 14px; font-weight: 500; }
menubutton.soft > button:hover { background: rgba(255,255,255,0.15); }
checkbutton check { border-radius: 999px; background: rgba(255,255,255,0.1); box-shadow: none; border: none; }
checkbutton check:checked { background: #f2f2f2; color: #0c0c0e; }
"""

def install():
    Adw.StyleManager.get_default().set_color_scheme(Adw.ColorScheme.FORCE_DARK)
    Gtk.Settings.get_default().set_property("gtk-icon-theme-name", "Adwaita")
    css = Gtk.CssProvider()
    css.load_from_string(CSS)
    Gtk.StyleContext.add_provider_for_display(Gdk.Display.get_default(), css,
                                              Gtk.STYLE_PROVIDER_PRIORITY_USER + 1)

def label(text="", *classes, xalign=0.0, ellipsize=False, wrap=False, **kw):
    lbl = Gtk.Label(label=text, xalign=xalign, **kw)
    if ellipsize:
        lbl.set_ellipsize(Pango.EllipsizeMode.END)
    if wrap:
        lbl.set_wrap(True)
        lbl.set_wrap_mode(Pango.WrapMode.WORD_CHAR)
    for c in classes:
        lbl.add_css_class(c)
    return lbl

def button(text=None, icon=None, *classes, tooltip=None, on_click=None):
    if text and icon:
        b = Gtk.Button(child=Adw.ButtonContent(label=text, icon_name=icon))
    elif icon:
        b = Gtk.Button(icon_name=icon)
    else:
        b = Gtk.Button(label=text or "")
    for c in classes:
        b.add_css_class(c)
    if tooltip:
        b.set_tooltip_text(tooltip)
    if on_click:
        b.connect("clicked", lambda *_: on_click())
    b.set_valign(Gtk.Align.CENTER)
    return b

def box(vertical=False, spacing=0, *children, **kw):
    b = Gtk.Box(orientation=Gtk.Orientation.VERTICAL if vertical else Gtk.Orientation.HORIZONTAL,
                spacing=spacing, **kw)
    for c in children:
        b.append(c)
    return b

def card(child=None, *classes):
    c = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)
    c.add_css_class("card")
    for cl in classes:
        c.add_css_class(cl)
    if child is not None:
        c.append(child)
    return c

def icon_tile(icon_name, size=48, icon_size=24):
    tile = Gtk.Box(halign=Gtk.Align.START, valign=Gtk.Align.CENTER)
    tile.add_css_class("tile")
    tile.set_size_request(size, size)
    img = Gtk.Image(icon_name=icon_name, pixel_size=icon_size, hexpand=True,
                    halign=Gtk.Align.CENTER, valign=Gtk.Align.CENTER)
    tile.append(img)
    tile.set_hexpand(False)
    tile.set_vexpand(False)
    return tile

class _Letter:
    __slots__ = ("ch", "x", "born", "dying", "died")

    def __init__(self, ch, x, now):
        self.ch, self.x, self.born, self.dying, self.died = ch, x, now, False, 0.0

def smooth(entry):
    entry.add_css_class("smooth")
    text = entry.get_delegate() if hasattr(entry, "get_delegate") else entry
    overlay = Gtk.Overlay(child=entry)
    overlay.set_hexpand(entry.get_hexpand())
    overlay.set_hexpand_set(True)
    area = Gtk.DrawingArea(can_target=False, hexpand=True, vexpand=True)
    overlay.add_overlay(area)
    st = {"letters": [], "caret": None, "blink": 0.0, "text": ""}
    APPEAR, VANISH, GLIDE = 0.18, 0.12, 0.16

    def now():
        return GLib.get_monotonic_time() / 1e6

    def positions(s):
        layout = text.create_pango_layout(s)
        xs, b = [], 0
        for ch in s:
            xs.append(layout.index_to_pos(b).x / Pango.SCALE)
            b += len(ch.encode())
        return xs, layout

    def changed(*_):
        new, old = entry.get_text(), st["text"]
        st["text"] = new
        live = [l for l in st["letters"] if not l.dying]
        start = 0
        while start < len(live) and start < len(new) and live[start].ch == new[start]:
            start += 1
        end = 0
        while end < len(live) - start and end < len(new) - start and live[-1 - end].ch == new[-1 - end]:
            end += 1
        t = now()
        xs, _ = positions(new)
        for l in live[start:len(live) - end]:
            l.dying, l.died = True, t
        fresh = [_Letter(ch, xs[start + i], t) for i, ch in enumerate(new[start:len(new) - end])]
        kept = live[:start] + fresh + live[len(live) - end:]
        dead = [l for l in st["letters"] if l.dying]
        st["letters"] = kept + dead
        st["targets"] = xs
        st["blink"] = t
        area.queue_draw()

    def tick(_w, _clock):
        area.queue_draw()
        return GLib.SOURCE_CONTINUE

    def draw(_a, cr, w, h):
        t = now()
        s = st["text"]
        xs, layout = positions(s)
        ok, origin = text.compute_point(area, Graphene.Point().init(0, 0))
        if not ok:
            return
        ox, oy = origin.x, origin.y
        lh = layout.get_pixel_extents()[1].height
        base_y = oy + (text.get_height() - lh) / 2
        if xs and layout.get_pixel_extents()[1].width > text.get_width() - 4:
            entry.remove_css_class("smooth")
            return
        entry.add_css_class("smooth")
        fg = text.get_color()
        live = [l for l in st["letters"] if not l.dying]
        for i, l in enumerate(live):
            if i < len(xs):
                l.x += (xs[i] - l.x) * min(1.0, 0.35)
        st["letters"] = [l for l in st["letters"] if not (l.dying and t - l.died > VANISH)]
        for l in st["letters"]:
            if l.dying:
                k = 1 - min(1.0, (t - l.died) / VANISH)
                rise, scale = 0, 0.7 + 0.3 * k
            else:
                p = min(1.0, (t - l.born) / APPEAR)
                k = 1 - (1 - p) ** 3
                rise, scale = 7 * (1 - k), 0.75 + 0.25 * k
            one = text.create_pango_layout(l.ch)
            cw = one.get_pixel_extents()[1].width
            cr.save()
            cr.translate(ox + l.x + cw / 2, base_y + lh / 2 + rise)
            cr.scale(scale, scale)
            cr.translate(-cw / 2, -lh / 2)
            cr.set_source_rgba(fg.red, fg.green, fg.blue, fg.alpha * k)
            PangoCairo.show_layout(cr, one)
            cr.restore()
        if text.has_focus() or entry.has_focus():
            pos = text.get_position() if hasattr(text, "get_position") else entry.get_position()
            b = len(s[:pos].encode())
            target = layout.index_to_pos(b).x / Pango.SCALE
            c = st["caret"] = target if st["caret"] is None else st["caret"] + (target - st["caret"]) * 0.3
            since = t - st["blink"]
            alpha = 1.0 if since < 0.5 else (0.5 + 0.5 * math.cos((since - 0.5) * math.pi * 2 / 1.1))
            cr.set_source_rgba(fg.red, fg.green, fg.blue, max(0.0, alpha))
            cr.rectangle(ox + c - 1, base_y + 1, 2, lh - 2)
            cr.fill()

    entry.connect("changed", changed)
    text.connect("notify::cursor-position", lambda *_: st.__setitem__("blink", now()))
    area.set_draw_func(draw)
    area.add_tick_callback(tick)
    return overlay

class Page(Gtk.Box):

    def __init__(self, title, subtitle=""):
        super().__init__(orientation=Gtk.Orientation.VERTICAL, spacing=18)
        self.add_css_class("page")
        head = Gtk.Box(spacing=12)
        titles = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=2, hexpand=True, valign=Gtk.Align.CENTER)
        self.title = label(title, "page-title")
        self.subtitle = label(subtitle, "page-sub", ellipsize=True)
        titles.append(self.title)
        titles.append(self.subtitle)
        self.actions = Gtk.Box(spacing=8, valign=Gtk.Align.CENTER)
        head.append(titles)
        head.append(self.actions)
        self.append(head)
        self.body = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=14, vexpand=True)
        self.append(self.body)

    def set_subtitle(self, text):
        self.subtitle.set_text(text)

class Frame:

    def __init__(self, window, app_title, pages, on_switch=None):
        self.window = window
        self.on_switch = on_switch
        self.rows = {}
        self.badges = {}

        side = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)
        side.append(label(app_title, "app-title"))
        self.nav = Gtk.ListBox(selection_mode=Gtk.SelectionMode.SINGLE)
        self.nav.add_css_class("nav")
        for name, title, icon in pages:
            row = Gtk.ListBoxRow()
            row.name = name
            inner = Gtk.Box(spacing=14)
            inner.append(Gtk.Image(icon_name=icon, pixel_size=17))
            inner.append(label(title, hexpand=True))
            badge = label("", "badge", xalign=0.5, visible=False, valign=Gtk.Align.CENTER)
            inner.append(badge)
            self.badges[name] = badge
            row.set_child(inner)
            self.nav.append(row)
            self.rows[name] = row
        self.nav.connect("row-selected", self._on_row)
        side.append(self.nav)
        side.append(Gtk.Box(vexpand=True))
        self.footer = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=10, visible=False)
        self.footer.add_css_class("sidebar-footer")
        side.append(self.footer)

        side_bar = Adw.HeaderBar(show_title=False, show_end_title_buttons=False)
        side_view = Adw.ToolbarView(content=side)
        side_view.add_top_bar(side_bar)
        side_page = Adw.NavigationPage(title=app_title, child=side_view)

        self.stack = Gtk.Stack(transition_type=Gtk.StackTransitionType.SLIDE_UP_DOWN, transition_duration=320,
                               hexpand=True, vexpand=True)
        self.header = Adw.HeaderBar(show_title=False)
        self.toasts = Adw.ToastOverlay(child=self.stack)
        content_view = Adw.ToolbarView(content=self.toasts)
        content_view.add_top_bar(self.header)
        self.content_page = Adw.NavigationPage(title=app_title, child=content_view)

        self.split = Adw.NavigationSplitView(sidebar=side_page, content=self.content_page,
                                             min_sidebar_width=210, max_sidebar_width=250,
                                             sidebar_width_fraction=0.25, show_content=True)
        bp = Adw.Breakpoint.new(Adw.BreakpointCondition.parse("max-width: 640sp"))
        bp.add_setter(self.split, "collapsed", True)
        window.add_breakpoint(bp)
        window.set_content(self.split)
        self.current = None

    def _on_row(self, _lb, row):
        if row is not None and row.name != self.current:
            self.show(row.name)

    def set_page(self, name, widget):
        old = self.stack.get_child_by_name(name)
        if old is widget:
            return
        if old is not None:
            tmp = name + "-old"
            self.stack.get_page(old).set_name(tmp)
            self.stack.add_named(widget, name)
            if self.current == name:
                self.stack.set_visible_child(widget)
            GLib.timeout_add(250, lambda: (self.stack.remove(old), False)[1])
        else:
            self.stack.add_named(widget, name)

    def show(self, name):
        self.current = name
        row = self.rows.get(name)
        if row is not None and self.nav.get_selected_row() is not row:
            self.nav.select_row(row)
        if name not in self.rows:
            self.nav.unselect_all()
        if self.stack.get_child_by_name(name) is not None:
            self.stack.set_visible_child_name(name)
        self.split.set_show_content(True)
        if self.on_switch:
            self.on_switch(name)

    def set_badge(self, name, text):
        b = self.badges[name]
        b.set_text(text)
        b.set_visible(bool(text))

    def toast(self, text, timeout=3):
        self.toasts.add_toast(Adw.Toast(title=GLib.markup_escape_text(text), timeout=timeout))

    def hide_sidebar(self):
        self.split.set_collapsed(True)
        self.split.set_show_content(True)
        self.header.set_show_back_button(False)
