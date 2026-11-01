#define _GNU_SOURCE
#include <dlfcn.h>
#include <stdarg.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <wayland-client-core.h>

extern const struct wl_interface wl_region_interface;

typedef struct wl_proxy *(*marshal_fn)(struct wl_proxy *, uint32_t, const struct wl_interface *,
                                       uint32_t, uint32_t, ...);
static marshal_fn real;

#define MAX_RECTS 512
typedef struct Region { struct wl_proxy *p; int n; int r[MAX_RECTS][4]; struct Region *next; } Region;
typedef struct Link { struct wl_proxy *k; struct wl_proxy *v; int x, y; struct Link *next; } Link;

static Region *regions;
static Link *xdg_to_surface;
static Link *surface_offset;
static Link *effect_to_surface;
static struct wl_proxy *compositor;

static Link *find(Link *l, struct wl_proxy *k) { for (; l; l = l->next) if (l->k == k) return l; return NULL; }
static Link *put(Link **l, struct wl_proxy *k) {
    Link *e = find(*l, k);
    if (!e) { e = calloc(1, sizeof *e); e->k = k; e->next = *l; *l = e; }
    return e;
}
static void drop(Link **l, struct wl_proxy *k) {
    for (Link **p = l; *p; p = &(*p)->next)
        if ((*p)->k == k) { Link *d = *p; *p = d->next; free(d); return; }
}
static Region *region(struct wl_proxy *p, int create) {
    for (Region *r = regions; r; r = r->next) if (r->p == p) return r;
    if (!create) return NULL;
    Region *r = calloc(1, sizeof *r); r->p = p; r->next = regions; regions = r;
    return r;
}
static void drop_region(struct wl_proxy *p) {
    for (Region **q = &regions; *q; q = &(*q)->next)
        if ((*q)->p == p) { Region *d = *q; *q = d->next; free(d); return; }
}

struct wl_proxy *wl_proxy_marshal_flags(struct wl_proxy *proxy, uint32_t opcode, const struct wl_interface *iface,
                                        uint32_t version, uint32_t flags, ...) {
    if (!real) real = (marshal_fn)dlsym(RTLD_NEXT, "wl_proxy_marshal_flags");
    va_list ap;
    va_start(ap, flags);
    long a[8];
    for (int i = 0; i < 8; i++) a[i] = va_arg(ap, long);
    va_end(ap);

    const char *cls = wl_proxy_get_class(proxy);

    if (!strcmp(cls, "wl_region")) {
        if (opcode == 1) {
            Region *r = region(proxy, 1);
            if (r->n < MAX_RECTS) { for (int i = 0; i < 4; i++) r->r[r->n][i] = (int)a[i]; r->n++; }
        } else if (opcode == 0) {
            drop_region(proxy);
        }
    } else if (!strcmp(cls, "wl_compositor")) {
        compositor = proxy;
    } else if (!strcmp(cls, "xdg_surface")) {
        if (opcode == 3) {
            Link *s = find(xdg_to_surface, proxy);
            if (s) { Link *o = put(&surface_offset, s->v); o->x = (int)a[0]; o->y = (int)a[1]; }
        } else if (opcode == 0) {
            drop(&xdg_to_surface, proxy);
        }
    } else if (!strcmp(cls, "ext_background_effect_surface_v1") && opcode == 1 && a[0] && compositor) {
        Link *e = find(effect_to_surface, proxy);
        Link *o = e ? find(surface_offset, e->v) : NULL;
        Region *src = region((struct wl_proxy *)a[0], 0);
        if (o && src && (o->x || o->y)) {
            uint32_t cv = wl_proxy_get_version(compositor);
            struct wl_proxy *moved = real(compositor, 1, &wl_region_interface, cv, 0, NULL);
            uint32_t rv = wl_proxy_get_version(moved);
            for (int i = 0; i < src->n; i++)
                real(moved, 1, NULL, rv, 0, src->r[i][0] - o->x, src->r[i][1] - o->y, src->r[i][2], src->r[i][3]);
            real(proxy, 1, NULL, version, flags, moved);
            real(moved, 0, NULL, rv, WL_MARSHAL_FLAG_DESTROY);
            return NULL;
        }
    } else if (!strcmp(cls, "ext_background_effect_surface_v1") && opcode == 0) {
        drop(&effect_to_surface, proxy);
    }

    struct wl_proxy *ret = real(proxy, opcode, iface, version, flags, a[0], a[1], a[2], a[3], a[4], a[5], a[6], a[7]);

    if (!strcmp(cls, "xdg_wm_base") && opcode == 2 && ret)
        put(&xdg_to_surface, ret)->v = (struct wl_proxy *)a[1];
    else if (!strcmp(cls, "ext_background_effect_manager_v1") && opcode == 1 && ret)
        put(&effect_to_surface, ret)->v = (struct wl_proxy *)a[1];
    return ret;
}
