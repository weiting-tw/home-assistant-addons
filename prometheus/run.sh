#!/usr/bin/with-contenv bashio
set -e

CONFIG=/config/prometheus.yml

if ! bashio::fs.file_exists "${CONFIG}"; then
    bashio::log.info "首次啟動，建立預設設定 ${CONFIG}"
    cp /defaults/prometheus.yml "${CONFIG}"
fi

# 設定寫錯就不要啟動。Prometheus 自己也會退出，但錯誤埋在日誌深處，
# 先檢查一次把原因講清楚。
if ! promtool check config "${CONFIG}"; then
    bashio::exit.nok "prometheus.yml 語法有誤，修正後重新啟動 add-on"
fi

# 選項在 UI 被清空時 bashio 會回空字串，直接帶給 Prometheus 會得到
# "empty duration string" 這種看不出原因的錯誤，所以補上預設值。
RETENTION=$(bashio::config 'retention_time')
if [ -z "${RETENTION}" ] || [ "${RETENTION}" = "null" ]; then
    RETENTION="90d"
fi

LOG_LEVEL=$(bashio::config 'log_level')
if [ -z "${LOG_LEVEL}" ] || [ "${LOG_LEVEL}" = "null" ]; then
    LOG_LEVEL="info"
fi

bashio::log.info "保留期限 ${RETENTION}，資料目錄 /data"

exec /usr/local/bin/prometheus \
    --config.file="${CONFIG}" \
    --storage.tsdb.path=/data \
    --storage.tsdb.retention.time="${RETENTION}" \
    --web.listen-address=0.0.0.0:9090 \
    --web.enable-lifecycle \
    --log.level="${LOG_LEVEL}"
