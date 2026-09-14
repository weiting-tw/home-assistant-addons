# InfluxDB

InfluxDB 1.8 時序資料庫。

官方 `influxdb:1.8` 的 binary，包在 Home Assistant base image 上。

## 為什麼會有這個 add-on

Home Assistant Community Add-ons 在 2026 年把 InfluxDB 從儲存庫移除，
已安裝的實例會變成 detached —— 還能跑，但拿不到更新，砍掉就裝不回來。
這份是自己維護的替代品。

## 與被移除的版本的差異

- **不含 Chronograf 與 Kapacitor。** 原本的 add-on 用 ingress 提供 Chronograf UI。
  查詢介面用 Grafana 就夠了，少兩個元件也少兩份維護。
- 沒有 ingress 面板，只開 8086 / 8088 兩個埠。

## 選項

| 選項 | 預設 | 說明 |
|---|---|---|
| `auth` | `false` | HTTP API 是否要驗證。改成 `true` 前要先建帳號 |
| `reporting` | `false` | 是否回報匿名使用統計給 InfluxData |
| `http_bind_address` | `0.0.0.0:8086` | 查詢與寫入 |
| `rpc_bind_address` | `0.0.0.0:8088` | 備份／還原 |

## 資料位置

`/data`（`data` / `meta` / `wal` 三個子目錄），包含在 Home Assistant 的備份裡。

## 備份與還原

```bash
influxd backup -portable -host <ha>:8088 -database home_assistant ./backup
influxd restore -portable -host <ha>:8088 -db home_assistant ./backup
```

`influxd` 可以用 `docker run --rm -v "$PWD:/backup" influxdb:1.8` 取得。
