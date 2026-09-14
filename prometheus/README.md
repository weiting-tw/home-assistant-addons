# Prometheus

Prometheus 時序資料庫，抓取 exporter 指標供 Grafana 查詢。

官方 `prom/prometheus:v3.14.0` 的 binary，包在 Home Assistant base image 上。

## 安裝

1. 附加元件商店 → 右上角 → 重新整理
2. 找到 **Prometheus** → 安裝 → 啟動

## 設定抓取目標

首次啟動會產生 `/addon_configs/<slug>_prometheus/prometheus.yml`。
編輯它，然後重新啟動 add-on。

語法錯誤時 add-on 不會啟動，日誌會直接指出問題行。

## 選項

| 選項 | 預設 | 說明 |
|---|---|---|
| `retention_time` | `90d` | 資料保留期限 |
| `log_level` | `info` | `debug` / `info` / `warn` / `error` |

## 接到 Grafana

新增 Prometheus datasource，URL 填 `http://<HA 位址>:9090`。

## 資料位置

TSDB 寫在 add-on 的 `/data` volume，包含在 Home Assistant 的備份裡。
