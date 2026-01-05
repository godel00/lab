# TapTap‑MQTT (Docker)


### Credits

Copyright belongs to the original TapTap and TapTap‑MQTT developers.  
This repository only provides a Docker implementation of their work.

This project is based on the work by Li Tin O’ve Weedle, the creator of TapTap‑MQTT:

https://github.com/litinoveweedle/taptap-mqtt

If you’re running **Home Assistant OS (Hass.io)** or **Home Assistant Supervised**, you should use the official add‑on instead of this Docker image:

https://github.com/litinoveweedle/hassio-addons/tree/main/taptap

### Not affiliated with upstream

This repository is an independent Docker packaging of the upstream TapTap‑MQTT project and is not officially associated with or endorsed by the original maintainers. 
It simply provides a clean, Docker‑first distribution for people running:

- Home Assistant **Core in Docker**
- Standalone Docker setups
- Unraid, Proxmox, Raspberry Pi, etc.

Huge thanks to the upstream authors — none of this would exist without their work.

---

# Installation Prerequisites (Summary)

Before running this container, you need:

### **1. MQTT Broker**
Any MQTT broker works (Mosquitto, EMQX, HiveMQ, etc.).

### **2. Home Assistant MQTT Integration**
Required for automatic sensor discovery.

### **3. Modbus RS485 → Serial/Ethernet Converter**
Examples: Waveshare RS485‑to‑Ethernet modules.

### **4. Correct Wiring**
The converter must be wired **in parallel** with the existing TAP wiring on the Tigo CCA “Gateway” RS485 port:

- A → A  
- B → B  
- Ground (⏚ / -) → Ground  

Keep wires short and mount the converter close to the CCA.

### **5. Converter Configuration**
Typical settings:

- Baud rate: **38400**
- Data bits: **8**
- Stop bits: **1**
- Flow control: **None**
- Mode: **Modbus TCP Server**
- Protocol: **None**  
  *(Waveshare: Web UI → Multi‑Host Settings → Protocol → None)*

### **6. Network Setup**
- Assign a reachable IP address (DHCP reservation recommended)
- Note the TCP port (usually 502)

---

# Configure TapTap‑MQTT

After the first container start, edit your config file:

```
~/taptap-mqtt/config/config.ini
```

Or on Unraid:

```
/mnt/user/appdata/taptap-mqtt/config/config.ini
```

Fill in:

- MQTT hostname, username, password  
- Modbus converter IP and port  
- Home Assistant discovery settings as needed 
- Optional behavior flags  

The file includes inline comments explaining each option.

Save the config and restart the container.

### **Recommended: Enable Debug Logging on First Run**

Set:

```
LOG_LEVEL = debug
```

This will show:

- raw TAP messages  
- Modbus connection attempts  
- module discovery  
- MQTT publishing  

Once confirmed working, change to:

```
LOG_LEVEL = info
```

or

```
LOG_LEVEL = warning
```

---

# Quick Start (Docker Run)

Create persistent folders:

```sh
mkdir -p ~/taptap-mqtt/config
mkdir -p ~/taptap-mqtt/data
```

Run the container:

```sh
docker run -d --name taptap-mqtt \
  --cap-add=SYS_RESOURCE \
  -v ~/taptap-mqtt/config:/app/config \
  -v ~/taptap-mqtt/data:/app/data \
  --restart unless-stopped \
  ghcr.io/godel00/taptap-mqtt-docker:latest
```

---

# Using docker‑compose

A `docker-compose.yml` file is included in this repository.

Start:

```sh
docker compose up -d
```

Stop:

```sh
docker compose down
```

Update:

```sh
docker compose pull
docker compose up -d
```

---

# Running on Unraid (GUI Method)

Unraid **does not automatically create folders** for volume mappings.  
Create them manually:

```sh
mkdir -p /mnt/user/appdata/taptap-mqtt/config
mkdir -p /mnt/user/appdata/taptap-mqtt/data
```

Then in **Docker → Add Container**:

- **Name:** `taptap-mqtt`
- **Repository:** `ghcr.io/godel00/taptap-mqtt-docker:latest`
- **Path:** `/app/config` → `/mnt/user/appdata/taptap-mqtt/config`
- **Path:** `/app/data` → `/mnt/user/appdata/taptap-mqtt/data`
- **Capability:** `SYS_RESOURCE`
- **Restart policy:** `Unless stopped`

Click **Apply**.

---

# Running on Unraid (Template XML Method)

Save the provided XML as:

```
/boot/config/plugins/dockerMan/templates-user/my-taptap-mqtt.xml
```

Then in Unraid:

**Docker → Add Container → Template dropdown → my-taptap-mqtt**

Click **Apply**.

---

# Folder Structure

### Host (persistent)

```
~/taptap-mqtt/
├── config/
│   ├── config.ini
│   └── config.ini.example
└── data/
    └── taptap.json
```

### Inside the container

```
/app
├── config/config.ini
├── config/config.ini.example
├── data/taptap.json
├── taptap/taptap
└── taptap-mqtt/taptap-mqtt.py
```

---

# How Config Discovery Works

TapTap‑MQTT expects `config.ini` in `/app`.

To support host‑mounted config, the container creates:

```
/app/config.ini → /app/config/config.ini
```

---

# Viewing Tigo Module Data in Home Assistant

Once the container is running correctly and your MQTT settings are valid, Home Assistant will automatically discover new MQTT entities for your Tigo modules.

You should see:

- Individual optimizer sensors  
- Module voltage and current  
- Module temperature  
- Module power  
- TAP/CCA status sensors  
- Availability sensors  

These appear under:

**Home Assistant → Settings → Devices & Services → MQTT → Devices**

Each optimizer will show up as its own device with multiple sensors.

If nothing appears:

- Check your MQTT credentials  
- Verify the Modbus converter IP/port  
- Ensure the converter protocol is set to **None**  
- Temporarily set `LOG_LEVEL = debug` to inspect messages  
