# TapTap‑MQTT Docker Image (Testing Repository)

This repository contains a Dockerized build of the **TapTap MQTT bridge**, which connects the TapTap RS485 controller to an MQTT broker.  
This repo is used for testing multi‑arch builds, GHCR publishing, and container runtime behavior before moving the final version into the main `taptap-mqtt` project.

---

## 🚀 Features

- Multi‑architecture Docker image (amd64 + arm64)
- Automatic builds and publishing to GitHub Container Registry (GHCR)
- Persistent configuration and state storage
- First‑run initialization with automatic config generation
- Clean, robust entrypoint script
- Compatible with Linux, macOS, Windows, and Unraid

---

## 📦 Pulling the Image (GHCR)

Once the workflow builds successfully, you can pull the image with:

```bash
docker pull ghcr.io/godel00/lab:latest
```

If the repo is private, authenticate first:

```bash
echo $GITHUB_TOKEN | docker login ghcr.io -u godel00 --password-stdin
```

---

## 🗂 Directory Structure

The container expects two persistent directories:

```
/app/config   → configuration files (config.ini)
/app/data     → runtime state (taptap.json)
```

On your host machine, you can store them anywhere.  
Recommended cross‑platform layout:

```
~/taptap-mqtt/config
~/taptap-mqtt/data
```

---

## 🐳 Running the Container

### **Linux / macOS**

```bash
mkdir -p ~/taptap-mqtt/config
mkdir -p ~/taptap-mqtt/data

docker run -d \
  --name taptap-mqtt \
  -v ~/taptap-mqtt/config:/app/config \
  -v ~/taptap-mqtt/data:/app/data \
  ghcr.io/godel00/lab:latest
```

### **Windows (PowerShell)**

```powershell
mkdir $HOME\taptap-mqtt\config
mkdir $HOME\taptap-mqtt\data

docker run `
  --name taptap-mqtt `
  -v $HOME\taptap-mqtt\config:/app/config `
  -v $HOME\taptap-mqtt\data:/app/data `
  ghcr.io/godel00/lab:latest
```

### **Unraid**

Map these paths in the template:

```
/mnt/user/appdata/taptap-mqtt/config → /app/config
/mnt/user/appdata/taptap-mqtt/data   → /app/data
```

---

## 📝 Configuration

On first run, the container will:

- Create `/app/config/config.ini` if missing  
- Copy `config.ini.example` for reference  
- Update paths inside the config automatically  
- Initialize `/app/data/taptap.json`  

You must edit `config.ini` to set:

- MQTT server, port, username, password  
- TapTap serial port or TCP address  
- TapTap modules  

---

## ⚙️ Environment Variable Overrides (Optional)

You can override config.ini values using environment variables:

| Variable      | Description |
|---------------|-------------|
| `MQTT_SERVER` | MQTT broker hostname/IP |
| `MQTT_PORT`   | MQTT port |
| `MQTT_USER`   | Username |
| `MQTT_PASS`   | Password |

Example:

```bash
docker run -d \
  -e MQTT_SERVER=192.168.1.10 \
  -e MQTT_PORT=1883 \
  -e MQTT_USER=admin \
  -e MQTT_PASS=secret \
  -v ~/taptap-mqtt/config:/app/config \
  -v ~/taptap-mqtt/data:/app/data \
  ghcr.io/godel00/lab:latest
```

---

## 🛠 Development

### Build locally:

```bash
docker build -t taptap-mqtt .
```

### Run locally:

```bash
docker run -it --rm \
  -v $(pwd)/config:/app/config \
  -v $(pwd)/data:/app/data \
  taptap-mqtt
```

---

## 🔄 GitHub Actions (GHCR Build)

This repo includes:

```
.github/workflows/ghcr-build.yml
```

It automatically:

- Builds multi‑arch images  
- Tags them (`latest`, `main`, `sha`, semver)  
- Pushes to GHCR  

Triggered on:

- Push to `main`
- Push of tags like `v1.0.0`
- Pull requests (build only)

---

## 📚 License

This repository is for testing and development purposes.  
The TapTap and TapTap‑MQTT projects belong to their respective authors.

---

## 🙌 Contributing

This repo is experimental, but PRs and suggestions are welcome.  
The final production container will live in the `taptap-mqtt` repository.

```

---
