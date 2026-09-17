ARG BUILD_FROM
FROM ${BUILD_FROM}

# ffmpeg 做 stream copy 分段錄影；curl 讀 Core API 查開關狀態；
# jq 解析狀態 JSON。都用 Alpine 套件，不自行編譯。
RUN apk add --no-cache ffmpeg curl jq

COPY run.sh /run.sh
RUN chmod a+x /run.sh

CMD [ "/run.sh" ]
