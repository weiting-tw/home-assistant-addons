# Changelog

## 3.14.0

- 首次發布，內含 Prometheus 3.14.0
- 抓取設定放在 `/addon_configs`，首次啟動產生預設檔
- 啟動前以 `promtool check config` 驗證設定
- 可設定 `retention_time` 與 `log_level`
