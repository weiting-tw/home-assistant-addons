#!/usr/bin/with-contenv bashio
set -o pipefail

SOURCE_URL=$(bashio::config 'source_url')
OUTPUT_DIR=$(bashio::config 'output_dir')
SEGMENT_SECONDS=$(bashio::config 'segment_seconds')
RETENTION_DAYS=$(bashio::config 'retention_days')
LOG_LEVEL=$(bashio::config 'log_level')

FFMPEG_PID=""
PRUNE_INTERVAL=3600     # 每小時清一次過期檔
WATCH_INTERVAL=15       # 每 15 秒確認 ffmpeg 還活著
LAST_PRUNE=0

mkdir -p "${OUTPUT_DIR}"

bashio::log.info "來源   ${SOURCE_URL%%\?*}?src=…"
bashio::log.info "輸出   ${OUTPUT_DIR}"
bashio::log.info "分段   每 ${SEGMENT_SECONDS} 秒一個檔"
bashio::log.info "保留   ${RETENTION_DAYS} 天"
bashio::log.info "開關   由 HA 啟停這個 add-on 控制（input_boolean → hassio.addon_start/stop）"

start_ffmpeg() {
    bashio::log.info "開始錄影"
    # -c copy：不轉碼，CPU 幾乎不動。
    # frag_keyframe+empty_moov：寫成分段 mp4，行程被砍時最後一個檔仍可播放。
    # reconnect*：來源斷線時自動重連，不讓整個 ffmpeg 退出。
    # -nostats：不然進度列會把 add-on 日誌洗掉。
    ffmpeg -nostdin -nostats -hide_banner -loglevel "${LOG_LEVEL}" \
        -reconnect 1 -reconnect_streamed 1 -reconnect_delay_max 10 \
        -i "${SOURCE_URL}" \
        -c copy \
        -f segment \
        -segment_time "${SEGMENT_SECONDS}" \
        -segment_format mp4 \
        -segment_format_options movflags=+frag_keyframe+empty_moov+default_base_moof \
        -reset_timestamps 1 \
        -strftime 1 \
        "${OUTPUT_DIR}/cuboai-%Y%m%d-%H%M%S.mp4" &
    FFMPEG_PID=$!
}

prune() {
    local n
    n=$(find "${OUTPUT_DIR}" -name 'cuboai-*.mp4' -type f -mmin "+$((RETENTION_DAYS * 1440))" -print -delete 2>/dev/null | wc -l)
    [ "${n}" -gt 0 ] && bashio::log.info "刪除 ${n} 個超過 ${RETENTION_DAYS} 天的檔案"
    return 0
}

cleanup() {
    bashio::log.info "收到停止訊號，收尾中"
    if [ -n "${FFMPEG_PID}" ] && kill -0 "${FFMPEG_PID}" 2>/dev/null; then
        kill -TERM "${FFMPEG_PID}" 2>/dev/null
        # 給 ffmpeg 時間把最後一段寫完
        for _ in 1 2 3 4 5 6 7 8 9 10; do
            kill -0 "${FFMPEG_PID}" 2>/dev/null || break
            sleep 1
        done
        kill -KILL "${FFMPEG_PID}" 2>/dev/null
    fi
    exit 0
}
trap cleanup SIGTERM SIGINT

prune
LAST_PRUNE=$(date +%s)
start_ffmpeg

while true; do
    # ffmpeg 自己死掉（來源長時間不可用、重連次數用盡）就重開。
    # HA 剛重啟時 go2rtc 還沒起來，第一次一定會失敗，靠這裡補。
    if ! kill -0 "${FFMPEG_PID}" 2>/dev/null; then
        bashio::log.warning "ffmpeg 已結束，重新啟動"
        start_ffmpeg
    fi

    NOW=$(date +%s)
    if [ $((NOW - LAST_PRUNE)) -ge "${PRUNE_INTERVAL}" ]; then
        prune
        LAST_PRUNE=${NOW}
    fi

    sleep "${WATCH_INTERVAL}" &
    wait $!
done
