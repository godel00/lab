# ============================
# Stage 1 — Builder
# ============================
FROM python:3.14-alpine AS builder

LABEL org.opencontainers.image.title="TapTap-MQTT"
LABEL org.opencontainers.image.description="Docker implementation of Tigo CCA Tap to MQTT bridge to get data from Tigo optimizers locally to Home Assistant."
LABEL org.opencontainers.image.source="https://github.com/godel00/lab"
LABEL org.opencontainers.image.url="https://github.com/godel00/lab"
LABEL org.opencontainers.image.licenses="MIT"

ARG TAPTAP_VERSION=""
ARG TAPTAP_MQTT_VERSION=""
ARG TARGETARCH

RUN apk add --no-cache curl tar git

WORKDIR /build

###############################################################################
# Install TapTap binary with auto-detected version + architecture fallback
###############################################################################
RUN set -eux; \
    \
    # Auto-detect version if not provided
    if [ -z "$TAPTAP_VERSION" ]; then \
        echo "Auto-detecting latest TapTap version..."; \
        TAPTAP_VERSION=$( \
            curl -sSL https://api.github.com/repos/litinoveweedle/taptap/releases/latest \
            | grep -oE '"tag_name":\s*"v?([0-9]+\.[0-9]+\.[0-9]+)"' \
            | sed -E 's/.*"v?([0-9]+\.[0-9]+\.[0-9]+)".*/\1/' \
            || true \
        ); \
        echo "Detected version: ${TAPTAP_VERSION:-none}"; \
    fi; \
    \
    # Fallback if detection failed
    if [ -z "$TAPTAP_VERSION" ]; then \
        echo "Failed to auto-detect version — falling back to 0.2.6"; \
        TAPTAP_VERSION="0.2.6"; \
    fi; \
    \
    # Determine architecture
    case "$TARGETARCH" in \
        amd64) TAPTAP_ARCH="musl-x86_64" ;; \
        arm64) TAPTAP_ARCH="musl-arm64" ;; \
        arm)   TAPTAP_ARCH="musleabihf-armv7" ;; \
        *) echo "Unsupported architecture: $TARGETARCH"; exit 1 ;; \
    esac; \
    \
    # Construct download URL
    TAPTAP_URL="https://github.com/litinoveweedle/taptap/releases/download/v${TAPTAP_VERSION}/taptap-Linux-${TAPTAP_ARCH}.tar.gz"; \
    echo "Checking URL: $TAPTAP_URL"; \
    \
    # Validate URL; fallback to 0.2.6 if missing
    if ! curl --head --silent --fail "$TAPTAP_URL" > /dev/null; then \
        echo "Version $TAPTAP_VERSION does not exist for $TARGETARCH — falling back to 0.2.6"; \
        TAPTAP_VERSION="0.2.6"; \
        TAPTAP_URL="https://github.com/litinoveweedle/taptap/releases/download/v0.2.6/taptap-Linux-${TAPTAP_ARCH}.tar.gz"; \
    fi; \
    \
    echo "Downloading TapTap from: $TAPTAP_URL"; \
    curl -sSLf -o taptap.tgz "$TAPTAP_URL"; \
    \
    # Extract into a temp dir to avoid macOS BuildKit path collision
    mkdir -p /tmp/taptap-extract; \
    tar -xzf taptap.tgz -C /tmp/taptap-extract; \
    \
    # Install binary
    install -m 755 /tmp/taptap-extract/taptap /build/taptap

###############################################################################
# Install TapTap-MQTT Python script with auto-detected version + fallback
###############################################################################
RUN set -eux; \
    \
    # Auto-detect version if not provided
    if [ -z "$TAPTAP_MQTT_VERSION" ]; then \
        echo "Auto-detecting latest TapTap-MQTT version..."; \
        TAPTAP_MQTT_VERSION=$( \
            curl -sSL https://api.github.com/repos/litinoveweedle/taptap-mqtt/releases/latest \
            | grep -oE '"tag_name":\s*"v?([0-9]+\.[0-9]+\.[0-9]+)"' \
            | sed -E 's/.*"v?([0-9]+\.[0-9]+\.[0-9]+)".*/\1/' \
            || true \
        ); \
        echo "Detected TapTap-MQTT version: ${TAPTAP_MQTT_VERSION:-none}"; \
    fi; \
    \
    # Fallback if detection failed
    if [ -z "$TAPTAP_MQTT_VERSION" ]; then \
        echo "Failed to auto-detect TapTap-MQTT version — falling back to 0.2.1"; \
        TAPTAP_MQTT_VERSION="0.2.1"; \
    fi; \
    \
    # Construct download URL
    TAPTAP_MQTT_URL="https://github.com/litinoveweedle/taptap-mqtt/archive/refs/tags/v${TAPTAP_MQTT_VERSION}.tar.gz"; \
    echo "Checking URL: $TAPTAP_MQTT_URL"; \
    \
    # Validate URL; fallback to 0.2.1 if missing
    if ! curl --head --silent --fail "$TAPTAP_MQTT_URL" > /dev/null; then \
        echo "Version $TAPTAP_MQTT_VERSION does not exist — falling back to 0.2.1"; \
        TAPTAP_MQTT_VERSION="0.2.1"; \
        TAPTAP_MQTT_URL="https://github.com/litinoveweedle/taptap-mqtt/archive/refs/tags/v0.2.1.tar.gz"; \
    fi; \
    \
    echo "Downloading TapTap-MQTT from: $TAPTAP_MQTT_URL"; \
    curl -sSLf -o taptap-mqtt.tgz "$TAPTAP_MQTT_URL"; \
    \
    mkdir -p /tmp/taptap-mqtt-extract; \
    tar -xzf taptap-mqtt.tgz -C /tmp/taptap-mqtt-extract; \
    \
    # Copy Python script + example config
    install -m 755 /tmp/taptap-mqtt-extract/*/taptap-mqtt.py /build/taptap-mqtt.py; \
    cp /tmp/taptap-mqtt-extract/*/config.ini.example /build/config.ini.example; \
    \
    # Install Python dependencies into a venv
    python -m venv /build/venv; \
    /build/venv/bin/pip install --no-cache-dir -r /tmp/taptap-mqtt-extract/*/requirements.txt

# ============================
# Stage 2 — Runtime
# ============================
FROM python:3.14-alpine

RUN apk add --no-cache bash

WORKDIR /app

# Copy TapTap binary
COPY --from=builder /build/taptap /app/taptap/taptap

# Copy TapTap-MQTT script
COPY --from=builder /build/taptap-mqtt.py /app/taptap-mqtt/taptap-mqtt.py

# Copy example config
COPY --from=builder /build/config.ini.example /app/config.ini.example

# Copy Python venv
COPY --from=builder /build/venv /app/venv

# Entrypoint
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENV PATH="/app/venv/bin:${PATH}"

ENTRYPOINT ["/entrypoint.sh"]