# CuboAI Recorder

把 CuboAI 攝影機的即時串流連續錄成分段 mp4，存進 Home Assistant 的 `/media`，並自動刪除超過保留天數的檔案。

不需要 CuboAI 訂閱——串流來自 CuboAI 整合在本機跑的 go2rtc，訂閱賣的是雲端存放。

## 實測數據（1080p h264 35fps + AAC 16kHz）

| 項目 | 數值 |
|---|---|
| 碼率 | 1.25 Mbps |
| 每小時 | 0.52 GB |
| 每天 | 12.6 GB |
| 保留 7 天 | 88 GB |

## 檔案

```
/media/cuboai/cuboai-20260918-001000.mp4
/media/cuboai/cuboai-20260918-002000.mp4
```

檔名是該段的起始時間。預設 10 分鐘一段，每檔約 87 MB。

## 開關

由 Home Assistant 啟停這個 add-on 來控制，不需要權杖也不需要輪詢：

```yaml
automation:
  - alias: CuboAI 錄影開
    triggers: [{ trigger: state, entity_id: input_boolean.cuboai_recording, to: "on" }]
    actions: [{ action: hassio.addon_start, data: { addon: 341a84dc_cuboai-recorder } }]
  - alias: CuboAI 錄影關
    triggers: [{ trigger: state, entity_id: input_boolean.cuboai_recording, to: "off" }]
    actions: [{ action: hassio.addon_stop, data: { addon: 341a84dc_cuboai-recorder } }]
```

`boot: manual`，所以重開機不會無視開關自己開錄；另外掛一條 HA 啟動時的同步自動化即可。

停止時 add-on 會攔 SIGTERM，給 ffmpeg 最多 10 秒把最後一段寫完。
