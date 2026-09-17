# 變更紀錄

## 1.1.0

- 改由 HA 啟停 add-on 來控制錄影，移除 Core API 輪詢。
  Supervisor 的 `/core/api/` 代理在 HAOS 上回 502，`/supervisor/ping` 卻正常，
  代理層不可靠；改用 `hassio.addon_start` / `hassio.addon_stop` 沒有這個依賴，
  也不必在 add-on 選項裡存長期權杖。
- `boot` 改為 `manual`，避免重開機時無視開關直接開錄。
- ffmpeg 加 `-nostats`，進度列不再洗版 add-on 日誌。
- 啟動時先清一次過期檔。

## 1.0.0

- 首版。ffmpeg stream copy 分段錄影，寫入 `/media/cuboai`。
- 以 `input_boolean` 控制開關，每 30 秒輪詢。
- 每小時清除超過保留天數的檔案。
- 分段用 `frag_keyframe+empty_moov`，行程被中止時最後一個檔仍可播放。
