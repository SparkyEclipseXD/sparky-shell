#!/usr/bin/env python3
import json
import os
import platform
import shutil
import time

def os_name():
    try:
        with open("/etc/os-release") as f:
            info = dict(l.rstrip().split("=", 1) for l in f if "=" in l)
        return info.get("NAME", "Linux").strip('"')
    except OSError:
        return "Linux"

def host():
    for p in ("/sys/devices/virtual/dmi/id/product_name", "/sys/devices/virtual/dmi/id/board_name"):
        try:
            with open(p) as f:
                name = f.read().strip()
            if name and "filled" not in name.lower():
                return name
        except OSError:
            pass
    return platform.node()

def cpu_times():
    with open("/proc/stat") as f:
        v = [int(x) for x in f.readline().split()[1:]]
    idle = v[3] + v[4]
    return idle, sum(v)

def mem():
    info = {}
    with open("/proc/meminfo") as f:
        for l in f:
            k, v = l.split(":", 1)
            info[k] = int(v.split()[0])
    total = info.get("MemTotal", 1)
    return 1 - info.get("MemAvailable", total) / total

def temp_sensor():
    base = "/sys/class/hwmon"
    for h in sorted(os.listdir(base)):
        try:
            with open(f"{base}/{h}/name") as f:
                if f.read().strip() in ("k10temp", "coretemp", "zenpower"):
                    return f"{base}/{h}/temp1_input"
        except OSError:
            pass
    return None

def uptime():
    with open("/proc/uptime") as f:
        mins = int(float(f.read().split()[0]) // 60)
    h, m = divmod(mins, 60)
    if h == 0:
        return f"{m} min" + ("s" if m != 1 else "")
    return f"{h} hour{'s' if h != 1 else ''}, {m} min{'s' if m != 1 else ''}"

static = {"os": os_name(), "kernel": platform.release().split("-")[0], "host": host()}
sensor = temp_sensor()
prev = cpu_times()

while True:
    time.sleep(2)
    cur = cpu_times()
    didle, dtotal = cur[0] - prev[0], cur[1] - prev[1]
    prev = cur
    disk = shutil.disk_usage("/")
    temp = None
    if sensor:
        try:
            with open(sensor) as f:
                temp = round(int(f.read()) / 1000)
        except OSError:
            pass
    print(json.dumps({
        **static,
        "uptime": uptime(),
        "cpu": 1 - didle / dtotal if dtotal else 0,
        "mem": mem(),
        "disk": disk.used / disk.total,
        "temp": temp,
    }), flush=True)
