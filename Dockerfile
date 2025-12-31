# TapTap MQTT Docker Image
FROM alpine:latest

ARG TAPTAP_VERSION=latest
ARG TAPTAP_MQTT_VERSION=latest
ARG TARGETARCH
ARG TAPTAP_REPO=https://github.com/litinoveweedle/taptap
ARG TAPTAP_MQTT_REPO=https://github.com/litinoveweedle/taptap-mqtt
ARG DOCKER_FILES_REPO=https://raw.githubusercontent.com/godel00/taptap-mqtt/main

WORKDIR /app

# Install dependencies
RUN apk update && apk add --no-cache \
    python3 \
    py3-pip \
    curl \
    tar \
    gzip

# Determine architecture and download taptap binary
RUN \
    if [ "$TARGETARCH" = "arm64" ]; then \
        TAPTAP_ARCH="musl-arm64"; \
    elif [ "$TARGETARCH" = "amd64" ]; then \
        TAPTAP_ARCH="musl-x86_64"; \
    else \
        echo "Unsupported architecture: $TARGETARCH"; \
        exit 1; \
    fi \
    && mkdir -p /app/taptap \
    && curl -sSLf -o /tmp/taptap.tgz \
        "${TAPTAP_REPO}/releases/download/v${TAPTAP_VERSION}/taptap-Linux-${TAPTAP_ARCH}.tar.gz" \
    && tar -xzvf /tmp/taptap.tgz -C /tmp \
    && cp /tmp/taptap /app/taptap/ \
    && chmod 755 /app/taptap/taptap \
    && rm -rf /tmp/*

# Download and install taptap-mqtt bridge
RUN \
    mkdir -p /app/taptap-mqtt \
    && curl -sSLf -o /tmp/taptap-mqtt.tgz \
        "${TAPTAP_MQTT_REPO}/archive/refs/tags/v${TAPTAP_MQTT_VERSION}.tar.gz" \
    && tar -xzvf /tmp/taptap-mqtt.tgz -C /tmp \
    && cp /tmp/taptap-mqtt-*/taptap-mqtt.py /app/taptap-mqtt/ \
    && chmod 755 /app/taptap-mqtt/taptap-mqtt.py \
    && rm -rf /tmp/*

# Install Python requirements
RUN curl -sSLf -o /tmp/requirements.txt \
        "${TAPTAP_MQTT_REPO}/raw/main/requirements.txt" \
    && pip install -q -r /tmp/requirements.txt \
    && rm /tmp/requirements.txt

# Download config example
RUN curl -sSLf -o /app/config.ini.example \
    "${TAPTAP_MQTT_REPO}/raw/main/config.ini.example"

# Download entrypoint script
RUN mkdir -p /app/scripts \
    && curl -sSLf -o /app/scripts/entrypoint.sh \
        "${DOCKER_FILES_REPO}/entrypoint.sh" \
    && chmod 755 /app/scripts/entrypoint.sh

# Environment
ENV PATH="/app/taptap:/app/taptap-mqtt:${PATH}"
ENV PYTHONUNBUFFERED=1

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD python3 -c "import sys; sys.exit(0)" || exit 1

ENTRYPOINT ["/app/scripts/entrypoint.sh"]