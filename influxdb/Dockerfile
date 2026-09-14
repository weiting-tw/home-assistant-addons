ARG BUILD_FROM

# 官方 image 的 influxd / influx 是靜態連結的 Go 執行檔，可以直接搬到
# Alpine base 上跑（實測 InfluxDB v1.8.10 在 aarch64-base:3.22 正常執行）。
FROM influxdb:1.8 AS upstream

FROM ${BUILD_FROM}

COPY --from=upstream /usr/bin/influxd /usr/bin/influx /usr/local/bin/
COPY run.sh /run.sh
RUN chmod a+x /run.sh

CMD [ "/run.sh" ]
