# Base image
FROM python:3.12-alpine

# Build arguments (passed from GHCR workflow)
ARG TAPTAP_VERSION
ARG TAPTAP_MQTT_VERSION
ARG TARGETARCH

# Install dependencies
RUN apk add --no-cache curl tar

# Create application directories
RUN mkdir -p /app/taptap /app/taptap-mqtt /app/config /app/data

###############################################################################
# Install TapTap binary
###############################################################################
RUN \
    if [ "$TARGETARCH" = "amd64" ]; then \
        TAPTAP_ARCH="musl-x86_64"; \
    elif [ "$TARGETARCH" = "arm64" ]; then \
        TAPTAP_ARCH="musl-arm64"; \
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
# Install TapTap-MQTT bridge
###############################################################################
RUN \
    curl -sSLf -o /tmp/taptap-mqtt.tgz \
        "https://github.com/litinoveweedle/taptap-mqtt/archive/refs/tags/v${TAPTAP_MQTT_VERSION}.tar.gz" \
    && tar -xzvf /tmp/taptap-mqtt.tgz -C /tmp \
    && cp /tmp/taptap-mqtt-*/taptap-mqtt.py /app/taptap-mqtt/ \
    && pip install -r /tmp/taptap-mqtt-*/requirements.txt \
    && chmod 755 /app/taptap-mqtt/taptap-mqtt.py \
    && rm -rf /tmp/*

###############################################################################
# Copy entrypoint
###############################################################################
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

WORKDIR /app

ENTRYPOINT ["/entrypoint.sh"]