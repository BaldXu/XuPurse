"""从 userdata 原始分区里按命中偏移捞取疑似 SQLite 库并校验。
只读：adb exec-out dd if=/dev/block/sda33（不写设备），结果落本地。
用法: python carve_hits.py 94b6bc78 xp_hits.txt out_dir [前后窗口MB]
"""
import os, subprocess, sys, sqlite3, struct, tempfile

SERIAL = sys.argv[1]
HITS = sys.argv[2]
OUT = sys.argv[3]
WIN_MB = int(sys.argv[4]) if len(sys.argv) > 4 else 2
os.makedirs(OUT, exist_ok=True)

def adb_dd(sector, count_sectors, dest):
    with open(dest, "wb") as f:
        p = subprocess.run(
            ["adb", "-s", SERIAL, "exec-out",
             f"su -c 'dd if=/dev/block/sda33 bs=512 skip={sector} count={count_sectors} 2>/dev/null'"],
            stdout=f, stderr=subprocess.DEVNULL)
    return os.path.getsize(dest)

def db_len(buf, p):
    """从 SQLite 头推算整库字节数（页大小*页数），失败返回 None"""
    hdr = buf[p:p + 100]
    if len(hdr) < 100 or hdr[:16] != b"SQLite format 3\x00":
        return None
    ps = struct.unpack(">H", hdr[16:18])[0]
    if ps == 1:
        ps = 65536
    if ps < 512 or ps & (ps - 1):
        return None
    pages = struct.unpack(">I", hdr[28:32])[0]
    if pages == 0:
        return None
    return ps * pages

def try_open(buf, p, dest):
    n = db_len(buf, p)
    if not n:
        return None
    data = buf[p:p + n]
    if len(data) < n:
        return None
    with open(dest, "wb") as f:
        f.write(data)
    try:
        c = sqlite3.connect(f"file:{dest}?mode=ro&immutable=1", uri=True)
        tabs = [r[0] for r in c.execute("select name from sqlite_master where type='table'")]
        if not tabs:
            return None
        info = {}
        for t in tabs:
            try:
                info[t] = c.execute(f'select count(*) from "{t}"').fetchone()[0]
            except Exception:
                info[t] = -1
        return tabs, info
    except Exception:
        return None
    finally:
        try: c.close()
        except Exception: pass

hits = sorted({int(x.strip()) for x in open(HITS) if x.strip().isdigit()})
# 去掉相距很近的重复命中
merged = []
for h in hits:
    if not merged or h - merged[-1] > 4 * 1024 * 1024:
        merged.append(h)
print(f"命中 {len(hits)} 个偏移，合并为 {len(merged)} 个窗口")

WIN = WIN_MB * 1024 * 1024
for i, h in enumerate(merged, 1):
    start = max(0, h - WIN) // 512 * 512
    blob = os.path.join(OUT, f"win_{i:03d}_{h}.bin")
    size = adb_dd(start // 512, (2 * WIN) // 512, blob)
    if size < 4096:
        print(f"[{i}/{len(merged)}] off={h} 读取失败({size}B)")
        continue
    buf = open(blob, "rb").read()
    found = 0
    pos = 0
    while True:
        pos = buf.find(b"SQLite format 3\x00", pos)
        if pos < 0:
            break
        found += 1
        dest = os.path.join(OUT, f"db_{i:03d}_{h}+{pos}.sqlite")
        got = try_open(buf, pos, dest)
        if got:
            tabs, info = got
            has = "year_reports" in tabs or "import_mappings" in tabs
            bills = info.get("bills", info.get("bill", 0))
            print(f"[{i}/{len(merged)}] off={h} pos={pos} tables={len(tabs)} bills={bills} xupurse_schema={has} -> {dest}")
        else:
            os.path.exists(dest) and os.remove(dest)
        pos += 1
    if found == 0:
        print(f"[{i}/{len(merged)}] off={h} 窗口内无 SQLite 头")
    os.remove(blob)
print("完成")
