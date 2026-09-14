#!/usr/bin/with-contenv bashio
set -e

CONFIG=/config/prometheus.yml
SECRET_DIR=/data/secrets

# 憑證由 add-on 選項提供，每次啟動重寫。先清空，避免刪掉某筆選項後
# 舊檔案還留在磁碟上。
rm -rf "${SECRET_DIR}"
mkdir -p "${SECRET_DIR}"
chmod 700 "${SECRET_DIR}"

if bashio::config.has_value 'secrets'; then
    for index in $(bashio::config 'secrets|keys'); do
        NAME=$(bashio::config "secrets[${index}].name")
        VALUE=$(bashio::config "secrets[${index}].value")
        printf '%s' "${VALUE}" > "${SECRET_DIR}/${NAME}"
        chmod 600 "${SECRET_DIR}/${NAME}"
        bashio::log.info "已寫入憑證 ${SECRET_DIR}/${NAME}"
    done
fi

if ! bashio::fs.file_exists "${CONFIG}"; then
    bashio::log.info "首次啟動，建立預設設定 ${CONFIG}"
    cp /defaults/prometheus.yml "${CONFIG}"
fi

# 設定寫錯就不要啟動。Prometheus 自己也會退出，但錯誤埋在日誌深處，
# 先檢查一次把原因講清楚。credentials_file 指到不存在的檔案也會在這裡擋下。
if ! promtool check config "${CONFIG}"; then
    bashio::exit.nok "prometheus.yml 有問題，修正後重新啟動 add-on"
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
