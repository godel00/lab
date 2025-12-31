#!/bin/sh
set -e

###############################################################################
# Color Handling (TTY-safe)
###############################################################################
if [ -t 1 ]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    NC='\033[0m'
else
    RED=''
    GREEN=''
    YELLOW=''
    NC=''
fi

###############################################################################
# Helper Functions
###############################################################################
info()  { printf "%s\n" "$1"; }
ok()    { printf "${GREEN}✓${NC} %s\n" "$1"; }
warn()  { printf "${YELLOW}!${NC} %s\n" "$1"; }
error() { printf "${RED}✗${NC} %s\n" "$1"; }

###############################################################################
# Paths
###############################################################################
CONFIG_DIR="/app/config"
DATA_DIR="/app/data"
CONFIG_FILE="${CONFIG_DIR}/config.ini"
CONFIG_EXAMPLE="/app/config.ini.example"
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

    # Copy example config for user reference
    if [ -f "$CONFIG_EXAMPLE" ] && [ ! -f "${CONFIG_DIR}/config.ini.example" ]; then
        cp "$CONFIG_EXAMPLE" "${CONFIG_DIR}/config.ini.example"
        chmod 644 "${CONFIG_DIR}/config.ini.example"
        ok "Copied config.ini.example to ${CONFIG_DIR}/config.ini.example"
    fi

    touch "$INIT_FLAG"
else
    ok "Persistent directories already initialized"
fi

###############################################################################
# Ensure config.ini Exists
###############################################################################
if [ -f "$CONFIG_FILE" ]; then
    ok "Using existing configuration: $CONFIG_FILE"
else
    warn "config.ini not found — creating from example"

    if [ -f "$CONFIG_EXAMPLE" ]; then
        cp "$CONFIG_EXAMPLE" "$CONFIG_FILE"
        chmod 644 "$CONFIG_FILE"
        ok "Created new config.ini at $CONFIG_FILE"

        warn "Please edit your configuration file:"
        info "  $CONFIG_FILE"
    else
        error "Missing config.ini.example — cannot create default config"
        exit 1
    fi
fi

###############################################################################
# Update Paths Inside config.ini
###############################################################################
if grep -q "BINARY = ./taptap" "$CONFIG_FILE"; then
    sed -i "s|BINARY = ./taptap|BINARY = ${TAPTAP_BIN}|g" "$CONFIG_FILE"
    ok "Updated BINARY path in config.ini"
fi

if grep -q "STATE_FILE = ./taptap.json" "$CONFIG_FILE"; then
    sed -i "s|STATE_FILE = ./taptap.json|STATE_FILE = ${STATE_FILE}|g" "$CONFIG_FILE"
    ok "Updated STATE_FILE path in config.ini"
fi

###############################################################################
# Environment Variable Overrides (Optional)
###############################################################################
apply_env_override() {
    KEY="$1"
    VALUE="$2"
    if [ -n "$VALUE" ]; then
        sed -i "s|^${KEY} = .*|${KEY} = ${VALUE}|g" "$CONFIG_FILE"
        ok "Applied env override: ${KEY}=${VALUE}"
    fi
}

apply_env_override "SERVER" "$MQTT_SERVER"
apply_env_override "PORT" "$MQTT_PORT"
apply_env_override "USER" "$MQTT_USER"
apply_env_override "PASS" "$MQTT_PASS"

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
# Start Application
###############################################################################
exec python3 "$MQTT_SCRIPT" --config "$CONFIG_FILE"