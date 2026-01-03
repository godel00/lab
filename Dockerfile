FROM python:3.12-alpine

ARG TAPTAP_VERSION
ARG TAPTAP_MQTT_VERSION
ARG TARGETARCH

RUN apk add --no-cache curl tar

RUN mkdir -p /app/taptap /app/taptap-mqtt /app/config /app/data

###############################################################################
# Install TapTap binary with auto-detected version + architecture fallback
###############################################################################
ARG TAPTAP_VERSION=""

RUN set -eux; \
    \
    # Auto-detect version if not provided
    if [ -z "$TAPTAP_VERSION" ]; then \
        echo "Auto-detecting latest TapTap version..."; \
        TAPTAP_VERSION=$(curl -sSL https://api.github.com/repos/litinoveweedle/taptap/releases/latest \
            | grep -oP '"tag_name": "\K(.*)(?=")' \
            || true); \
        echo "Detected version: ${TAPTAP_VERSION:-none}"; \
    fi; \
    \
    # If detection failed, fallback immediately
    if [ -z "$TAPTAP_VERSION" ]; then \
        echo "Failed to auto-detect version — falling back to 0.2.6"; \
        TAPTAP_VERSION="0.2.6"; \
    fi; \
    \
    # Determine architecture
    if [ "$TARGETARCH" = "amd64" ]; then \
        TAPTAP_ARCH="musl-x86_64"; \
    elif [ "$TARGETARCH" = "arm64" ]; then \
        TAPTAP_ARCH="musl-arm64"; \
    elif [ "$TARGETARCH" = "arm" ]; then \
        TAPTAP_ARCH="musleabihf-armv7"; \
    else \
        echo "Unsupported architecture: $TARGETARCH"; \
        exit 1; \
    fi; \
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
    curl -sSLf -o /tmp/taptap.tgz "$TAPTAP_URL"; \
    tar -xzvf /tmp/taptap.tgz -C /tmp; \
    cp /tmp/taptap /app/taptap/; \
    chmod 755 /app/taptap/taptap; \
    rm -rf /tmp/*

###############################################################################
# Install TapTap-MQTT Python script with auto-detected version + fallback
###############################################################################
ARG TAPTAP_MQTT_VERSION=""

RUN set -eux; \
    \
    # Auto-detect version if not provided
    if [ -z "$TAPTAP_MQTT_VERSION" ]; then \
        echo "Auto-detecting latest TapTap-MQTT version..."; \
        TAPTAP_MQTT_VERSION=$(curl -sSL https://api.github.com/repos/litinoveweedle/taptap-mqtt/releases/latest \
            | grep -oP '"tag_name": "\K(.*)(?=")' \
            || true); \
        echo "Detected TapTap-MQTT version: ${TAPTAP_MQTT_VERSION:-none}"; \
    fi; \
    \
    # If detection failed, fallback immediately
    if [ -z "$TAPTAP_MQTT_VERSION" ]; then \
        echo "Failed to auto-detect TapTap-MQTT version — falling back to 0.2.1"; \
        TAPTAP_MQTT_VERSION="0.2.1"; \
    fi; \
    \
    # Construct download URL (source tarball)
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
    curl -sSLf -o /tmp/taptap-mqtt.tgz "$TAPTAP_MQTT_URL"; \
    tar -xzvf /tmp/taptap-mqtt.tgz -C /tmp; \
    \
    # Copy Python script
    cp /tmp/taptap-mqtt-*/taptap-mqtt.py /app/taptap-mqtt/; \
    chmod 755 /app/taptap-mqtt/taptap-mqtt.py; \
    \
    # Copy example config from the extracted tarball
    cp /tmp/taptap-mqtt-*/config.ini.example /app/config.ini.example; \
    \
    # Install Python dependencies
    pip install -r /tmp/taptap-mqtt-*/requirements.txt; \
    \
    # Cleanup
    rm -rf /tmp/*

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

WORKDIR /app
ENTRYPOINT ["/entrypoint.sh"]