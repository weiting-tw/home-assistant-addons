#!/usr/bin/with-contenv bashio
set -e

# 全部資料放 add-on 的 /data volume，會被 Home Assistant 的備份涵蓋。
export INFLUXDB_DATA_DIR=/data/data
export INFLUXDB_META_DIR=/data/meta
export INFLUXDB_DATA_WAL_DIR=/data/wal
mkdir -p "${INFLUXDB_DATA_DIR}" "${INFLUXDB_META_DIR}" "${INFLUXDB_DATA_WAL_DIR}"

AUTH=$(bashio::config 'auth')
if [ "${AUTH}" = "true" ]; then
    export INFLUXDB_HTTP_AUTH_ENABLED=true
else
    export INFLUXDB_HTTP_AUTH_ENABLED=false
fi

REPORTING=$(bashio::config 'reporting')
if [ "${REPORTING}" = "true" ]; then
    export INFLUXDB_REPORTING_DISABLED=false
else
    export INFLUXDB_REPORTING_DISABLED=true
fi

# 選項被清空時 bashio 回空字串，帶空值進去 influxd 會綁到隨機埠。
HTTP_BIND=$(bashio::config 'http_bind_address')
if [ -z "${HTTP_BIND}" ] || [ "${HTTP_BIND}" = "null" ]; then
    HTTP_BIND="0.0.0.0:8086"
fi
export INFLUXDB_HTTP_BIND_ADDRESS="${HTTP_BIND}"

RPC_BIND=$(bashio::config 'rpc_bind_address')
if [ -z "${RPC_BIND}" ] || [ "${RPC_BIND}" = "null" ]; then
    RPC_BIND="0.0.0.0:8088"
fi
export INFLUXDB_BIND_ADDRESS="${RPC_BIND}"

bashio::log.info "HTTP ${INFLUXDB_HTTP_BIND_ADDRESS}，RPC ${INFLUXDB_BIND_ADDRESS}，驗證 ${INFLUXDB_HTTP_AUTH_ENABLED}"

exec /usr/local/bin/influxd
