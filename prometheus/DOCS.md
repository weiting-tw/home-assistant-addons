# Prometheus

## 抓取設定

設定檔在 `/addon_configs/<slug>_prometheus/prometheus.yml`，可用 File editor、
Samba 或 SSH 編輯。add-on 首次啟動會放一份預設檔進去。

改完有兩種套用方式：

- 在 add-on 頁面按「重新啟動」
- `curl -X POST http://<HA 位址>:9090/-/reload`（`--web.enable-lifecycle` 已開啟）

## 需要驗證的目標

用 `authorization` 區塊。例如 LiteLLM：

```yaml
  - job_name: 'litellm'
    metrics_path: /metrics/
    authorization:
      type: Bearer
      credentials: '<key>'
    static_configs:
      - targets: ['192.168.31.248:4000']
```

`metrics_path` 結尾的斜線不能省，LiteLLM 的 `/metrics` 會回 307 轉址。

## job_name 與 Grafana 儀表板

儀表板的 PromQL 用 `job="..."` 過濾。改了 `job_name` 而沒同步改儀表板，
面板就會變成空的。

## 保留期限與磁碟

`retention_time` 預設 90 天。四個 target、約 260 種指標、30 秒間隔，
一天約 50-100 MB。90 天約 5-9 GB。

## 疑難排解

**add-on 啟不起來** —— 看日誌。啟動前會跑 `promtool check config`，
語法錯誤會明確指出。

**target 顯示 DOWN** —— 開 `http://<HA 位址>:9090/targets` 看錯誤原因。
常見是對方服務只綁在特定介面，HA 連不到。
