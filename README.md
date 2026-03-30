# HTTP Requester

A lightweight monitoring service that fetches targets from an API, performs periodic HTTP requests, and reports results via MQTT.

---

## 🚀 Overview

**HTTP Requester** is a background service designed to:

- Retrieve a list of websites (targets) from an external API  
- Perform HTTP requests to those targets at defined intervals  
- Send the results back to a backend system using MQTT  
- Dynamically update its configuration by listening to incoming MQTT messages

---

## ⚙️ How It Works

1. The service fetches a list of targets from an API  
2. Each target includes:
   - URL  
   - Request interval  
3. The service periodically sends HTTP requests to each target  
4. Results are published as MQTT messages  
5. The service listens for incoming MQTT messages to:
   - Add/remove targets  
   - Change configuration in real-time  
---

## 📡 MQTT Communication

### Publish

The service publishes request results:

- Status codes  
- Response times  

### Subscribe

The service listens for updates:

- Add/remove targets  
