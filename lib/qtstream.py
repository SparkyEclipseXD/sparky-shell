import struct

T_MAP, T_LIST, T_STRING, T_RECT, T_SIZE, T_USER = 8, 9, 10, 19, 21, 65536

def qstring(s):
    if s is None:
        return b"\xff\xff\xff\xff"
    data = s.encode("utf-16-be")
    return struct.pack(">I", len(data)) + data

def variant(type_id, payload, user_name=None):
    out = struct.pack(">Ib", T_USER if user_name else type_id, 0)
    if user_name:
        name = user_name.encode() + b"\0"
        out += struct.pack(">I", len(name)) + name
    return out + payload

def string_list(items):
    return variant(T_LIST, struct.pack(">I", len(items)) + b"".join(variant(T_STRING, qstring(s)) for s in items))

def window_list(windows):
    body = struct.pack(">I", len(windows)) + b"".join(qstring(a) + qstring(t) for a, t in windows)
    return variant(0, body, "QList<WindowRestoreInfo>")

def variant_map(entries):
    return struct.pack(">I", len(entries)) + b"".join(qstring(k) + v for k, v in sorted(entries.items()))

def kde_restore_payload(outputs=(), windows=()):
    entries = {}
    if outputs:
        entries["outputs"] = string_list(list(outputs))
    if windows:
        entries["windows"] = window_list(list(windows))
    return variant_map(entries)
