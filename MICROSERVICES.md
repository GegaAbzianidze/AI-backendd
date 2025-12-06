# Microservices Architecture

This project is split into 2 independent services that communicate via HTTP:

## 🏗️ Architecture

```
┌─────────────────┐         HTTP API        ┌─────────────────┐
│                 │ ───────────────────────> │                 │
│  Backend API    │                          │  YOLO Service   │
│  (Node.js)      │ <─────────────────────── │  (Python)       │
│                 │         Results          │                 │
└─────────────────┘                          └─────────────────┘
     Port 3000                                    Port 8000
```

## 📦 Services

### 1. Backend API (Node.js + Express)
- **Purpose:** Main API, job management, file uploads
- **Technology:** Node.js, Express, TypeScript, FFmpeg
- **Port:** 3000 (or Railway assigned)
- **Repository:** Main project

### 2. YOLO Processing Service (Python)
- **Purpose:** AI detection, OCR processing
- **Technology:** Python, FastAPI, YOLO, EasyOCR
- **Port:** 8000 (or Railway assigned)
- **Repository:** `yolo-service/` subdirectory

## 🔗 Communication

The backend calls the YOLO service via HTTP:

```
POST http://yolo-service.railway.app/detect
Body: { "frames_dir": "/path", "output_json": "/path" }
Response: { "success": true, "detected_frames": 45 }
```

## 🚀 Deployment on Railway

### Deploy Both Services:

1. **Backend Service:**
   - Deploy from root directory
   - Uses `Dockerfile` or `package.json`
   - Set env: `YOLO_SERVICE_URL`

2. **YOLO Service:**
   - Deploy from `yolo-service/` directory
   - Uses `yolo-service/Dockerfile`
   - Lightweight Python-only image

### Advantages:

✅ **Smaller images** - Each service is focused
✅ **Independent scaling** - Scale AI processing separately
✅ **Faster builds** - Changes to one don't rebuild both
✅ **Better isolation** - Services don't interfere
✅ **Easier debugging** - Clear separation of concerns

## 📊 Estimated Costs

- **Backend:** ~$5-7/month (1GB RAM, 1 vCPU)
- **YOLO Service:** ~$8-10/month (2GB RAM, 2 vCPU)
- **Total:** ~$13-17/month

Still cheaper than a monolithic deployment!

