#!/usr/bin/env python3
"""把 macmon 的一次取樣轉成 Prometheus textfile 格式。

node_exporter 在 macOS 上拿不到 Apple Silicon 的溫度與功耗（thermal collector
回報的是節流壓力，且沒發生節流時完全沒有輸出），所以用 macmon 補。
由 launchd 每 30 秒執行一次，寫進 node_exporter 的 textfile collector 目錄。
"""
import json
import os
import subprocess
import sys
import tempfile

OUT = os.path.expanduser('~/.node_exporter/textfile/macmon.prom')

# (macmon 的欄位路徑, 指標名稱, 型別, 說明)
SCALARS = [
    ('temp.cpu_temp_avg',  'macmon_cpu_temperature_celsius', 'gauge', 'CPU 平均溫度'),
    ('temp.gpu_temp_avg',  'macmon_gpu_temperature_celsius', 'gauge', 'GPU 平均溫度'),
    ('cpu_power',          'macmon_cpu_power_watts',         'gauge', 'CPU 功耗'),
    ('gpu_power',          'macmon_gpu_power_watts',         'gauge', 'GPU 功耗'),
    ('ane_power',          'macmon_ane_power_watts',         'gauge', 'Neural Engine 功耗'),
    ('ram_power',          'macmon_ram_power_watts',         'gauge', '記憶體功耗'),
    ('all_power',          'macmon_package_power_watts',     'gauge', 'CPU+GPU+ANE 合計功耗'),
    ('sys_power',          'macmon_system_power_watts',      'gauge', '整機功耗'),
    ('ecpu_freq_mhz',      'macmon_ecpu_frequency_mhz',      'gauge', '節能核心頻率'),
    ('pcpu_freq_mhz',      'macmon_pcpu_frequency_mhz',      'gauge', '效能核心頻率'),
    ('gpu_freq_mhz',       'macmon_gpu_frequency_mhz',       'gauge', 'GPU 頻率'),
    ('cpu_usage_pct',      'macmon_cpu_usage_ratio',         'gauge', 'CPU 使用率 0-1'),
    ('ecpu_active_ratio',  'macmon_ecpu_active_ratio',       'gauge', '節能核心活躍比例 0-1'),
    ('pcpu_active_ratio',  'macmon_pcpu_active_ratio',       'gauge', '效能核心活躍比例 0-1'),
    ('gpu_active_ratio',   'macmon_gpu_active_ratio',        'gauge', 'GPU 活躍比例 0-1'),
]


def dig(obj, path):
    for part in path.split('.'):
        if not isinstance(obj, dict) or part not in obj:
            return None
        obj = obj[part]
    return obj


# macmon 讀 GPU 溫度約有一半機率失敗，回傳 0.8 這種明顯不合理的值
# （實測 12 次取樣有 6 次是 0.8，CPU 溫度同時是正常的 55 度上下）。
# 所以一次取多筆，挑出合理的那筆；全部不合理就不輸出該指標，
# Prometheus 會沿用前一個值。
# 失敗不是隨機分佈，是叢集的：實測 40 筆的序列為
#   #...###....###...###..........###...###.
# 好的讀數三筆一組出現，中間最長連續失敗 10 筆（300ms 間隔約 3 秒）。
# 取樣視窗必須長過最長失敗區間，否則整段都落在壞區間。
# 16 筆 × 300ms = 4.8 秒，落在 30 秒排程裡佔比可接受。
SAMPLES = 16
INTERVAL_MS = 300
TEMP_FLOOR = 10.0       # 攝氏。低於此值視為感測器沒讀到。


def sample():
    out = subprocess.run(['macmon', 'pipe', '-s', str(SAMPLES), '-i', str(INTERVAL_MS)],
                         capture_output=True, text=True, timeout=60)
    if out.returncode != 0:
        sys.exit('macmon 失敗: ' + out.stderr.strip()[:200])
    rows = [json.loads(l) for l in out.stdout.splitlines() if l.strip()]
    if not rows:
        sys.exit('macmon 沒有輸出')

    merged = rows[-1]
    # 溫度欄位另外挑：取最後一筆讀得到的值，讀不到就刪掉，不要輸出假資料。
    for key in ('cpu_temp_avg', 'gpu_temp_avg'):
        good = [r['temp'][key] for r in rows
                if isinstance(r.get('temp', {}).get(key), (int, float))
                and r['temp'][key] >= TEMP_FLOOR]
        if good:
            merged['temp'][key] = good[-1]
        else:
            merged['temp'].pop(key, None)
    return merged


def render(d):
    lines = []
    for path, name, kind, help_text in SCALARS:
        v = dig(d, path)
        if v is None:
            continue
        lines.append('# HELP %s %s' % (name, help_text))
        lines.append('# TYPE %s %s' % (name, kind))
        lines.append('%s %s' % (name, float(v)))

    fans = d.get('fans') or []
    if fans:
        lines.append('# HELP macmon_fan_rpm 風扇轉速')
        lines.append('# TYPE macmon_fan_rpm gauge')
        for f in fans:
            lines.append('macmon_fan_rpm{fan="%s"} %s' % (f.get('name', '?'), float(f.get('rpm', 0))))
        lines.append('# HELP macmon_fan_max_rpm 風扇最高轉速')
        lines.append('# TYPE macmon_fan_max_rpm gauge')
        for f in fans:
            lines.append('macmon_fan_max_rpm{fan="%s"} %s' % (f.get('name', '?'), float(f.get('max_rpm', 0))))

    lines.append('# HELP macmon_scrape_success 上一次取樣是否成功')
    lines.append('# TYPE macmon_scrape_success gauge')
    lines.append('macmon_scrape_success 1')
    return '\n'.join(lines) + '\n'


def main():
    text = render(sample())
    # node_exporter 會讀到寫到一半的檔案，所以先寫暫存檔再原子換名。
    d = os.path.dirname(OUT)
    fd, tmp = tempfile.mkstemp(dir=d, suffix='.tmp')
    try:
        with os.fdopen(fd, 'w') as f:
            f.write(text)
        os.replace(tmp, OUT)
    except BaseException:
        os.path.exists(tmp) and os.unlink(tmp)
        raise


if __name__ == '__main__':
    main()
