# Mac mini exporters

Prometheus add-on 抓取的 Mac mini 端點。這些跑在 Mac 上，不是 Home Assistant
add-on，放這裡只是讓監控設定集中在同一個 repo。

機器：Apple M4 Mac mini（`Mac16,10`），LAN `192.168.31.248`。

## 端點一覽

| 埠 | 來源 | 內容 |
|---|---|---|
| 9100 | node_exporter（Homebrew） | macOS 系統指標 + 下面兩份 textfile |
| 9101 | `wywywywy/docker_stats_exporter`（容器） | 容器 CPU、網路、Block IO |
| 9102 | `docker-mem-exporter.py` | 容器記憶體的 cgroup v2 明細 |
| 9252 | gitlab-runner 內建 | CI job 數、並行度、API 延遲 |
| 4000 | LiteLLM 內建 | 花費、token、延遲、快取命中 |

全部綁 `0.0.0.0`。**不要綁單一 IP** —— 綁 Tailscale 位址時，介面斷線會讓
OrbStack 的埠轉發累積 CLOSE_WAIT socket（實測堆到 16,029 個），耗盡暫時埠
導致全機連線失敗。

## macmon-exporter.py

node_exporter 在 macOS 上拿不到 Apple Silicon 的溫度與功耗。`--collector.thermal`
回報的是節流壓力等級，而且沒發生節流時完全沒有輸出。溫度感測器走 IOReport，
node_exporter 讀不到。

改用 [macmon](https://github.com/vladkens/macmon)（`brew install macmon`，
Apple Silicon 專用，不需 sudo），輸出 18 個指標：CPU/GPU 溫度、CPU/GPU/ANE/RAM
功耗、整機功耗、核心頻率、活躍比例、風扇轉速。

### GPU 溫度的取樣問題

macmon 讀 M4 的 GPU 溫度會間歇失敗，回傳 0.8 這種明顯不合理的值。
實測 40 筆的失敗率 **60%**，CPU 溫度同期是 0%。

失敗不是隨機的，是叢集的：

```
#...###....###...###..........###...###.
   # = 讀到    . = 沒讀到
```

好的讀數三筆一組出現，中間隔 4~11 筆，最長連續失敗 10 筆。
所以取樣視窗必須長過最長失敗區間 —— 設 16 筆 × 300 ms = 4.8 秒，實測 10/10 成功。

上游 issue：
[#12 M4 :: CPU/GPU temperatures are wrong](https://github.com/vladkens/macmon/issues/12)（2024-12 開啟，未修）、
[#68 M2 Ultra: GPU temp sometimes reports 5°C](https://github.com/vladkens/macmon/issues/68)。
根因是 Apple 在 M4 換掉了溫度感測器的 key，社群還沒解出完整對應。

**三筆都失敗時不輸出該指標，不寫前一個值。** 寫假值的話，「感測器故障」和
「溫度很穩定」在圖上長得一樣。Grafana 那端用 `spanNulls: 180000` 讓線跨過
3 分鐘以內的空隙，資料層仍然誠實記錄缺值。

## docker-mem-exporter.py

`docker_stats_exporter` 的 `dockerstats_memory_usage_rss_bytes` 在 OrbStack 上
**恆為 0**（實測 16 個容器加總 = 0）。原因是 OrbStack 用 cgroup v2，`rss` 在 v2
已改名 `anon`，exporter 沒跟上。

這支直接讀 Docker API，補上 `anon` / `file` / `inactive_file` / `inactive_anon`
這些能判斷「多少記憶體還沒被回收」的欄位。

### 為什麼要背景取樣

Docker 的 `stats?stream=false` 每個容器要取兩個樣本才回應，單一容器約 2 秒。
17 個容器循序跑超過 30 秒，遠超 Prometheus 預設的 10 秒抓取逾時。

所以改成背景執行緒每 20 秒平行取樣（8 條執行緒），HTTP 請求只讀最後一份快取。
實測回應時間 2 毫秒。

## 安裝

```bash
brew install macmon node_exporter

mkdir -p ~/.local/bin ~/.node_exporter/textfile
cp macmon-exporter.py docker-mem-exporter.py ~/.local/bin/
chmod +x ~/.local/bin/macmon-exporter.py ~/.local/bin/docker-mem-exporter.py

cp launchd/*.plist ~/Library/LaunchAgents/
for p in ~/Library/LaunchAgents/com.weiting.{macmon,docker-mem,node}-exporter.plist; do
  launchctl unload "$p" 2>/dev/null
  launchctl load "$p"
done
```

plist 裡的路徑寫死 `/Users/weiting`，換機器要改。

`com.weiting.macmon-exporter` 每 30 秒跑一次寫入 textfile；
`com.weiting.docker-mem-exporter` 是常駐的 HTTP 服務（`KeepAlive`）。

## 驗證

```bash
curl -s http://192.168.31.248:9100/metrics | grep -c '^macmon_'   # 應為 18
curl -s http://192.168.31.248:9102/metrics | grep -c '^dockermem_'
```

Prometheus 那端在 add-on 的 `/addon_configs/<slug>_prometheus/prometheus.yml`，
`job_name` 必須與 Grafana 儀表板的 `job="..."` 過濾條件一致。
