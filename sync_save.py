"""存档同步 — Supabase Storage 免费持久化
启动: 从 Supabase 下载存档 → /app/data/
退出: /app/data/ → 上传到 Supabase
"""
import os, sys, json, time, signal, glob
from urllib.request import Request, urlopen
from urllib.error import HTTPError

SUPABASE_URL = os.environ.get("SUPABASE_URL", "")
SUPABASE_KEY = os.environ.get("SUPABASE_SERVICE_ROLE_KEY", "")
BUCKET = os.environ.get("SUPABASE_BUCKET", "fishing-saves")
DATA_DIR = "/app/data"

def supabase_request(method, path, data=None):
    url = f"{SUPABASE_URL}/storage/v1/object/{path}"
    headers = {
        "Authorization": f"Bearer {SUPABASE_KEY}",
        "apikey": SUPABASE_KEY,
    }
    if data is not None:
        req = Request(url, data=data, headers=headers, method=method)
    else:
        req = Request(url, headers=headers, method=method)
    try:
        resp = urlopen(req, timeout=30)
        return resp.read()
    except HTTPError as e:
        if e.code == 404:
            return None
        print(f"[sync] HTTP {e.code}: {e.reason}")
        return None

def upload_saves():
    """上传所有存档文件"""
    if not SUPABASE_URL or not SUPABASE_KEY:
        print("[sync] Supabase 未配置，跳过上传")
        return
    for f in glob.glob(f"{DATA_DIR}/*"):
        name = os.path.basename(f)
        with open(f, "rb") as fp:
            data = fp.read()
        result = supabase_request("POST", f"{BUCKET}/{name}", data)
        if result is not None:
            print(f"[sync] ⬆ 上传: {name} ({len(data)} bytes)")

def download_saves():
    """下载所有存档文件"""
    if not SUPABASE_URL or not SUPABASE_KEY:
        print("[sync] Supabase 未配置，跳过下载")
        return
    # 列出桶内文件
    listing = supabase_request("POST", f"{BUCKET}/list?prefix=", b"{}")
    if listing:
        files = json.loads(listing)
        for f in files:
            name = f.get("name", "")
            data = supabase_request("GET", f"{BUCKET}/{name}")
            if data:
                path = os.path.join(DATA_DIR, name)
                with open(path, "wb") as fp:
                    fp.write(data)
                print(f"[sync] ⬇ 下载: {name} ({len(data)} bytes)")

def sync_loop():
    """每 10 分钟自动上传一次（防止崩溃丢档）"""
    while True:
        time.sleep(600)
        upload_saves()

def main():
    download_saves()
    # 定时自动上传
    import threading
    t = threading.Thread(target=sync_loop, daemon=True)
    t.start()
    # 退出时上传
    signal.signal(signal.SIGTERM, lambda *a: (upload_saves(), sys.exit(0)))
    signal.signal(signal.SIGINT, lambda *a: (upload_saves(), sys.exit(0)))
    # 启动 MCP server
    os.execv(sys.executable, [sys.executable, "server.py"])

if __name__ == "__main__":
    main()
