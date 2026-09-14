# InfluxDB

## 接 Home Assistant

`configuration.yaml`：

```yaml
influxdb:
  include:
    domains:
      - sensor
      - binary_sensor
```

不填 `host` 時預設連 `localhost:8086`。Home Assistant Core 走主機網路，
所以會連到這個 add-on 對外開的 8086。

## 接 Grafana

Grafana add-on 與這個 add-on 在同一個 supervisor 網路上，datasource URL 用
容器主機名比走主機埠穩：

```
http://<repo-hash>-influxdb:8086
```

`<repo-hash>` 是儲存庫網址的 SHA-1 前 8 碼，可以在 add-on 的 slug 裡看到。

## 保留期限

預設保留政策 `autogen` 沒有上限，資料會一直累積。要設上限：

```sql
ALTER RETENTION POLICY autogen ON home_assistant DURATION 365d
```

實測參考：1,680 條序列、19 個 domain，約每月 390 MB。

## 從舊的 Community add-on 搬移

兩者 slug 不同（儲存庫網址不同），所以安裝這個之後是一個全新的空實例，
舊資料留在舊 add-on 的 volume 裡。搬移步驟：

1. 舊 add-on 的選項加上 envvar `INFLUXDB_BIND_ADDRESS=0.0.0.0:8088`，重啟
2. `influxd backup -portable -host <ha>:8088 -database home_assistant ./backup`
3. 停掉舊 add-on（釋出 8086 / 8088）
4. 安裝並啟動這個 add-on
5. `influxd restore -portable -host <ha>:8088 -db home_assistant ./backup`
6. 更新 Grafana 的 datasource URL
7. 確認無誤後再移除舊 add-on

備份與還原都走網路，不需要主機的 root 權限。
