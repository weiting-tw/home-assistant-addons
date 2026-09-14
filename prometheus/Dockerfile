ARG BUILD_FROM

# 只取官方 image 的兩個 binary。Prometheus 3.x 已移除 consoles，不需其他檔案。
FROM prom/prometheus:v3.14.0 AS upstream

FROM ${BUILD_FROM}

COPY --from=upstream /bin/prometheus /bin/promtool /usr/local/bin/
COPY defaults/prometheus.yml /defaults/prometheus.yml
COPY run.sh /run.sh
RUN chmod a+x /run.sh

CMD [ "/run.sh" ]
