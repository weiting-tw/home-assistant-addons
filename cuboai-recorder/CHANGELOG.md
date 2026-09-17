# 變更紀錄

## 1.0.0

- 首版。ffmpeg stream copy 分段錄影，寫入 `/media/cuboai`。
- 以 `input_boolean` 控制開關，每 30 秒輪詢。
- 每小時清除超過保留天數的檔案。
- 分段用 `frag_keyframe+empty_moov`，行程被中止時最後一個檔仍可播放。
