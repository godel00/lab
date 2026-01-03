#!/bin/sh
set -e

###############################################################################
# Helper Functions (plain text)
###############################################################################
info()  { printf "%s\n" "$1"; }
ok()    { printf "OK: %s\n" "$1"; }
warn()  { printf "WARN: %s\n" "$1"; }
error() { printf "ERROR: %s\n" "$1"; }

###############################################################################
# Paths
###############################################################################
CONFIG_DIR="/app/config"
DATA_DIR="/app/data"
CONFIG_FILE="${CONFIG_DIR}/config.ini"
CONFIG_EXAMPLE="${CONFIG_DIR}/config.ini.example"
INIT_FLAG="${CONFIG_DIR}/.docker_initialized"
STATE_FILE="${DATA_DIR}/taptap.json"
TAPTAP_BIN="/app/taptap/taptap"
MQTT_SCRIPT="/app/taptap-mqtt/taptap-mqtt.py"

###############################################################################
# Banner
###############################################################################
info "========================================"
info "TapTap MQTT Docker Initialization"
info "========================================"

###############################################################################
# Validate Required Binaries
###############################################################################
command -v python3 >/dev/null 2>&1 || {
    error "python3 not found — container build is broken"
    exit 1
}

if [ ! -x "$TAPTAP_BIN" ]; then
    error "TapTap binary missing: $TAPTAP_BIN"
    exit 1
fi

if [ ! -f "$MQTT_SCRIPT" ]; then
    error "TapTap-MQTT script missing: $MQTT_SCRIPT"
    exit 1
fi

###############################################################################
# First-Run Initialization
###############################################################################
if [ ! -f "$INIT_FLAG" ]; then
    warn "First run detected — initializing persistent directories"

    mkdir -p "$CONFIG_DIR" "$DATA_DIR"
    chmod 755 "$CONFIG_DIR" "$DATA_DIR"
    ok "Created config and data directories"

    # Move example config into the config directory
    if [ -f "/app/config.ini.example" ] && [ ! -f "$CONFIG_EXAMPLE" ]; then
        cp "/app/config.ini.example" "$CONFIG_EXAMPLE"
        chmod 644 "$CONFIG_EXAMPLE"
        ok "Placed config.ini.example into $CONFIG_EXAMPLE"
    fi

    # Create config.ini from example
    if [ ! -f "$CONFIG_FILE" ]; then
        cp "$CONFIG_EXAMPLE" "$CONFIG_FILE"
        chmod 644 "$CONFIG_FILE"
        ok "Created new config.ini at $CONFIG_FILE"

        # FIRST-RUN ONLY: Replace BINARY and STATE_FILE regardless of value
        sed -i "s|^BINARY *=.*|BINARY = ${TAPTAP_BIN}|g" "$CONFIG_FILE"
        ok "Set BINARY path to ${TAPTAP_BIN}"

        sed -i "s|^STATE_FILE *=.*|STATE_FILE = ${STATE_FILE}|g" "$CONFIG_FILE"
        ok "Set STATE_FILE path to ${STATE_FILE}"

        warn "Please edit your configuration file:"
        info "  $CONFIG_FILE"
    fi

    touch "$INIT_FLAG"
else
    ok "Persistent directories already initialized"
fi

###############################################################################
# Symlink config.ini into working directory for TapTap-MQTT auto-detection
###############################################################################
ln -sf "$CONFIG_FILE" /app/config.ini
ok "Linked config.ini into /app/config.ini for TapTap-MQTT auto-detection"

###############################################################################
# Startup Summary
###############################################################################
info ""
info "========================================"
info "Starting TapTap MQTT Bridge"
info "========================================"
info "Config file: $CONFIG_FILE"
info "State file:  $STATE_FILE"
info "Binary:      $TAPTAP_BIN"
info ""

###############################################################################
# Graceful Shutdown Handler
###############################################################################
trap "info 'Stopping TapTap MQTT...'; exit 0" SIGTERM SIGINT

###############################################################################
# Start Application (no --config)
###############################################################################
exec python3 "$MQTT_SCRIPT"