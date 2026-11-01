#!/usr/bin/env python3
import os
import struct

SRC = "/usr/share/icons/breeze_cursors/cursors"
OUT = os.path.expanduser("~/.local/share/icons/breeze-sparky")
FRAMES = 7
FRAME_MS = 22
HOLD_MS = 0x7FFFFFFF

IMAGE = 0xFFFD0002

def read(name):
    d = open(os.path.join(SRC, name), "rb").read()
    _, _, _, ntoc = struct.unpack_from("<4sIII", d, 0)
    out = {}
    for i in range(ntoc):
        typ, size, pos = struct.unpack_from("<III", d, 16 + 12 * i)
        if typ != IMAGE or size in out:
            continue
        _, _, _, _, w, h, xh, yh, _ = struct.unpack_from("<9I", d, pos)
        px = list(struct.unpack_from(f"<{w * h}I", d, pos + 36))
        out[size] = (w, h, xh, yh, px)
    return out

def channels(p):
    return (p >> 24) & 255, (p >> 16) & 255, (p >> 8) & 255, p & 255

def blend(arrow, hand, t):
    aw, ah, ax, ay, apx = arrow
    hw, hh, hx, hy, hpx = hand
    hot_x, hot_y = max(ax, hx), max(ay, hy)
    w = hot_x + max(aw - ax, hw - hx)
    h = hot_y + max(ah - ay, hh - hy)
    out = [0] * (w * h)
    for img, k in ((arrow, 1 - t), (hand, t)):
        iw, ih, ix, iy, ipx = img
        ox, oy = hot_x - ix, hot_y - iy
        for y in range(ih):
            for x in range(iw):
                p = ipx[y * iw + x]
                if not p:
                    continue
                a, r, g, b = (c * k for c in channels(p))
                i = (y + oy) * w + x + ox
                A, R, G, B = channels(out[i])
                out[i] = (min(255, round(A + a)) << 24 | min(255, round(R + r)) << 16
                          | min(255, round(G + g)) << 8 | min(255, round(B + b)))
    return w, h, hot_x, hot_y, out

def write(path, frames):
    header = 16 + 12 * len(frames)
    toc, chunks, pos = b"", b"", header
    for size, w, h, xh, yh, delay, px in frames:
        chunk = struct.pack("<9I", 36, IMAGE, size, 1, w, h, xh, yh, delay) + struct.pack(f"<{len(px)}I", *px)
        toc += struct.pack("<III", IMAGE, size, pos)
        chunks += chunk
        pos += len(chunk)
    with open(path, "wb") as f:
        f.write(struct.pack("<4sIII", b"Xcur", 16, 0x10000, len(frames)) + toc + chunks)

def main():
    arrow, hand = read("left_ptr"), read("dnd-move")
    frames = []
    for size in sorted(set(arrow) & set(hand)):
        for i in range(FRAMES):
            t = (i + 1) / FRAMES
            t = 1 - (1 - t) ** 2
            w, h, xh, yh, px = blend(arrow[size], hand[size], t)
            last = i == FRAMES - 1
            frames.append((size, w, h, xh, yh, HOLD_MS if last else FRAME_MS, px))
    os.makedirs(os.path.join(OUT, "cursors"), exist_ok=True)
    write(os.path.join(OUT, "cursors", "closedhand"), frames)
    for alias in ("grabbing", "dnd-move", "4498f0e0c1937ffe01fd06f973665830", "9081237383d90e509aa00f00170e968f",
                  "fcf21c00b30f7e3f83fe0dfd12e71cff"):
        link = os.path.join(OUT, "cursors", alias)
        if os.path.lexists(link):
            os.unlink(link)
        os.symlink("closedhand", link)
    for name in os.listdir(SRC):
        link = os.path.join(OUT, "cursors", name)
        if not os.path.lexists(link):
            os.symlink(os.path.join(SRC, name), link)
    with open(os.path.join(OUT, "index.theme"), "w") as f:
        f.write("[Icon Theme]\nName=Breeze Sparky\n"
                "Comment=Breeze, with the grab hand fading in smoothly\nInherits=breeze_cursors\n")
    print(f"{len(frames)} frames written to {OUT}")

if __name__ == "__main__":
    main()
