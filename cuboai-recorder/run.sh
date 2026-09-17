#!/usr/bin/with-contenv bashio
set -o pipefail

SOURCE_URL=$(bashio::config 'source_url')
OUTPUT_DIR=$(bashio::config 'output_dir')
SEGMENT_SECONDS=$(bashio::config 'segment_seconds')
RETENTION_DAYS=$(bashio::config 'retention_days')
LOG_LEVEL=$(bashio::config 'log_level')
SWITCH_ENTITY=""
if bashio::config.has_value 'switch_entity'; then
    SWITCH_ENTITY=$(bashio::config 'switch_entity')
fi

CORE_API="http://supervisor/core/api"
FFMPEG_PID=""
LAST_PRUNE=0
PRUNE_INTERVAL=3600     # 每小時清一次過期檔
POLL_INTERVAL=30        # 每 30 秒看一次開關

mkdir -p "${OUTPUT_DIR}"

bashio::log.info "來源     ${SOURCE_URL%%\?*}?src=…"
bashio::log.info "輸出     ${OUTPUT_DIR}"
bashio::log.info "分段     每 ${SEGMENT_SECONDS} 秒一個檔"
bashio::log.info "保留     ${RETENTION_DAYS} 天"
if [ -n "${SWITCH_ENTITY}" ]; then
    bashio::log.info "開關     ${SWITCH_ENTITY}（每 ${POLL_INTERVAL} 秒檢查）"
else
    bashio::log.info "開關     未設定，持續錄影"
fi

# 讀 HA 的 entity 狀態。查不到（尚未建立、API 暫時無回應）一律回 'on'，
# 寧可多錄也不要因為一次查詢失敗就靜默停錄。
read_switch() {
    local state
    state=$(curl -s -m 10 \
        -H "Authorization: Bearer ${SUPERVISOR_TOKEN}" \
        -H "Content-Type: application/json" \
        "${CORE_API}/states/${SWITCH_ENTITY}" 2>/dev/null | jq -r '.state // empty')
    if [ -z "${state}" ] || [ "${state}" = "null" ]; then
        bashio::log.warning "讀不到 ${SWITCH_ENTITY}，本輪視為開啟"
        echo "on"
    else
        echo "${state}"
    fi
}

start_ffmpeg() {
    [ -n "${FFMPEG_PID}" ] && kill -0 "${FFMPEG_PID}" 2>/dev/null && return
    bashio::log.info "開始錄影"
    # -c copy：不轉碼，CPU 幾乎不動。
    # frag_keyframe+empty_moov：寫成分段 mp4，行程被砍時最後一個檔仍可播放。
    # reconnect*：來源斷線時自動重連，不讓整個 ffmpeg 退出。
    ffmpeg -nostdin -hide_banner -loglevel "${LOG_LEVEL}" \
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

stop_ffmpeg() {
    [ -z "${FFMPEG_PID}" ] && return
    if kill -0 "${FFMPEG_PID}" 2>/dev/null; then
        bashio::log.info "停止錄影"
        kill -TERM "${FFMPEG_PID}" 2>/dev/null
        # 給 ffmpeg 收尾寫完 moov 的時間
        for _ in 1 2 3 4 5; do
            kill -0 "${FFMPEG_PID}" 2>/dev/null || break
            sleep 1
        done
        kill -KILL "${FFMPEG_PID}" 2>/dev/null
    fi
    wait "${FFMPEG_PID}" 2>/dev/null
    FFMPEG_PID=""
}

prune() {
    local n
    n=$(find "${OUTPUT_DIR}" -name 'cuboai-*.mp4' -type f -mmin "+$((RETENTION_DAYS * 1440))" -print -delete 2>/dev/null | wc -l)
    [ "${n}" -gt 0 ] && bashio::log.info "刪除 ${n} 個超過 ${RETENTION_DAYS} 天的檔案"
    return 0
}

cleanup() {
    bashio::log.info "收到停止訊號"
    stop_ffmpeg
    exit 0
}
trap cleanup SIGTERM SIGINT

while true; do
    if [ -z "${SWITCH_ENTITY}" ] || [ "$(read_switch)" = "on" ]; then
        start_ffmpeg
    else
        stop_ffmpeg
    fi

    # ffmpeg 自己死掉（來源長時間不可用、重連次數用盡）時下一輪會重開
    if [ -n "${FFMPEG_PID}" ] && ! kill -0 "${FFMPEG_PID}" 2>/dev/null; then
        bashio::log.warning "ffmpeg 已結束，下一輪重新啟動"
        FFMPEG_PID=""
    fi

    NOW=$(date +%s)
    if [ $((NOW - LAST_PRUNE)) -ge "${PRUNE_INTERVAL}" ]; then
        prune
        LAST_PRUNE=${NOW}
    fi

    sleep "${POLL_INTERVAL}"
done
