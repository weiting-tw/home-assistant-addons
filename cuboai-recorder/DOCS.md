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

`switch_entity` 填一個 `input_boolean`，add-on 每 30 秒讀一次：`on` 就錄，`off` 就停。留空則永遠錄。

讀不到該 entity 時視為開啟——寧可多錄，也不要因為一次 API 失敗就靜默停錄。
