#!/usr/bin/env python3
"""輸出容器記憶體的 cgroup v2 明細。

現有的 docker_stats_exporter 只給 usage / rss / limit，而 rss 在 cgroup v2
已改名 anon，所以它回報的 rss 恆為 0（實測 16 個容器總和 = 0）。
這支直接讀 Docker API，補上 anon / file / inactive_* 這些真正能判斷
「多少記憶體還沒被回收」的欄位。

以 HTTP 提供 /metrics，由 launchd 常駐，Prometheus 併入 macmini-containers job。
"""
import concurrent.futures
import http.client
import http.server
import json
import socket
import threading
import time

SOCKET_PATH = '/var/run/docker.sock'
PORT = 9102
REFRESH = 20            # 秒。背景執行緒的取樣間隔。
WORKERS = 8             # 平行呼叫 Docker stats 的執行緒數。

# cgroup v2 的欄位 -> (指標名, 說明)
FIELDS = {
    'anon':          ('dockermem_anon_bytes', '匿名頁（程式實際佔用，不可直接回收）'),
    'file':          ('dockermem_file_bytes', '檔案快取（可回收）'),
    'inactive_file': ('dockermem_inactive_file_bytes', '閒置檔案快取（記憶體吃緊時第一個被回收）'),
    'inactive_anon': ('dockermem_inactive_anon_bytes', '閒置匿名頁（可被換出到 swap）'),
    'active_anon':   ('dockermem_active_anon_bytes', '活躍匿名頁'),
}

# Docker 的 stats?stream=false 每次要取兩個樣本才回應，單一容器約 2 秒。
# 16 個容器循序跑要 30 秒以上，遠超過 Prometheus 預設的 10 秒抓取逾時。
# 所以改成背景執行緒定期更新，HTTP 請求永遠只讀最後一份快取。
_cache = {'at': 0.0, 'text': '# 尚未取樣\n'}
_lock = threading.Lock()


def dget(path):
    """走 unix socket 呼叫 Docker API。"""
    conn = http.client.HTTPConnection('localhost')
    conn.sock = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    conn.sock.settimeout(20)
    conn.sock.connect(SOCKET_PATH)
    conn.request('GET', path)
    r = conn.getresponse()
    body = r.read()
    conn.close()
    return json.loads(body)


def collect():
    lines = []
    per_metric = {name: [] for name, _ in FIELDS.values()}
    usage, limit = [], []

    containers = [(c['Names'][0].lstrip('/'), c['Id']) for c in dget('/containers/json')]

    def one(item):
        name, cid = item
        try:
            return name, dget('/containers/%s/stats?stream=false' % cid).get('memory_stats')
        except Exception:
            return name, None

    with concurrent.futures.ThreadPoolExecutor(max_workers=WORKERS) as pool:
        results = list(pool.map(one, containers))

    for name, m in results:
        if not m:
            continue
        usage.append((name, m.get('usage', 0)))
        limit.append((name, m.get('limit', 0)))
        st = m.get('stats', {})
        for key, (metric, _) in FIELDS.items():
            if key in st:
                per_metric[metric].append((name, st[key]))

    def emit(metric, help_text, rows):
        if not rows:
            return
        lines.append('# HELP %s %s' % (metric, help_text))
        lines.append('# TYPE %s gauge' % metric)
        for n, v in rows:
            lines.append('%s{name="%s"} %d' % (metric, n.replace('"', ''), v))

    emit('dockermem_usage_bytes', '容器記憶體用量（含快取）', usage)
    emit('dockermem_limit_bytes', '容器記憶體上限；未設限時等於主機可用量', limit)
    for key, (metric, help_text) in FIELDS.items():
        emit(metric, help_text, per_metric[metric])

    lines.append('# HELP dockermem_containers 取樣到的容器數')
    lines.append('# TYPE dockermem_containers gauge')
    lines.append('dockermem_containers %d' % len(usage))
    return '\n'.join(lines) + '\n'


def refresher():
    while True:
        try:
            text = collect()
            with _lock:
                _cache['text'] = text
                _cache['at'] = time.time()
        except Exception:
            pass
        time.sleep(REFRESH)


def cached():
    with _lock:
        return _cache['text']


class Handler(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path.rstrip('/') not in ('/metrics', ''):
            self.send_error(404)
            return
        try:
            body = cached().encode()
        except Exception as e:
            self.send_error(500, str(e)[:100])
            return
        self.send_response(200)
        self.send_header('Content-Type', 'text/plain; version=0.0.4')
        self.send_header('Content-Length', str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def log_message(self, *a):
        pass


if __name__ == '__main__':
    threading.Thread(target=refresher, daemon=True).start()
    http.server.ThreadingHTTPServer(('0.0.0.0', PORT), Handler).serve_forever()
