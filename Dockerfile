FROM python:3.12-alpine

ARG TAPTAP_VERSION
ARG TAPTAP_MQTT_VERSION
ARG TARGETARCH

RUN apk add --no-cache curl tar

RUN mkdir -p /app/taptap /app/taptap-mqtt /app/config /app/data

###############################################################################
# Install TapTap binary (multi-arch)
###############################################################################
RUN \
    if [ "$TARGETARCH" = "amd64" ]; then \
        TAPTAP_ARCH="musl-x86_64"; \
    elif [ "$TARGETARCH" = "arm64" ]; then \
        TAPTAP_ARCH="musl-arm64"; \
    elif [ "$TARGETARCH" = "arm" ]; then \
        TAPTAP_ARCH="musleabihf-armv7"; \
    else \
        echo "Unsupported architecture: $TARGETARCH"; \
        exit 1; \
    fi \
    && curl -sSLf -o /tmp/taptap.tgz \
        "https://github.com/litinoveweedle/taptap/releases/download/v${TAPTAP_VERSION}/taptap-Linux-${TAPTAP_ARCH}.tar.gz" \
    && tar -xzvf /tmp/taptap.tgz -C /tmp \
    && cp /tmp/taptap /app/taptap/ \
    && chmod 755 /app/taptap/taptap \
    && rm -rf /tmp/*

###############################################################################
# Install TapTap-MQTT
###############################################################################
RUN \
    curl -sSLf -o /tmp/taptap-mqtt.tgz \
        "https://github.com/litinoveweedle/taptap-mqtt/archive/refs/tags/v${TAPTAP_MQTT_VERSION}.tar.gz" \
    && tar -xzvf /tmp/taptap-mqtt.tgz -C /tmp \
    && cp /tmp/taptap-mqtt-*/taptap-mqtt.py /app/taptap-mqtt/ \
    && pip install -r /tmp/taptap-mqtt-*/requirements.txt \
    && chmod 755 /app/taptap-mqtt/taptap-mqtt.py \
    && rm -rf /tmp/*

# Download example config for first-run initialization
RUN curl -sSLf -o /app/config.ini.example \
    "https://raw.githubusercontent.com/litinoveweedle/taptap-mqtt/v${TAPTAP_MQTT_VERSION}/config.ini.example"

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

WORKDIR /app
ENTRYPOINT ["/entrypoint.sh"]