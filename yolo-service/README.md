# YOLO Detection Service

Microservice for AI-powered object detection and OCR processing.

## 🚀 Quick Start

### Local Development

```bash
cd yolo-service

# Create virtual environment
python -m venv venv
source venv/bin/activate  # Windows: .\venv\Scripts\Activate.ps1

# Install dependencies
pip install -r requirements.txt

# Run service
python main.py
```

Service runs on `http://localhost:8000`

### Docker

```bash
# Build
docker build -t yolo-service ../ -f Dockerfile

# Run
docker run -p 8000:8000 yolo-service
```

### Deploy to Railway

1. Create new project on Railway
2. Deploy from GitHub (select `yolo-service` directory)
3. Railway auto-detects Dockerfile
4. Service deploys automatically!

## 📡 API Endpoints

### `GET /`
Health check

### `GET /health`
Detailed health status

### `POST /detect`
Process video frames with YOLO

**Request:**
```json
{
  "frames_dir": "/path/to/frames",
  "output_json": "/path/to/output.json",
  "total_frames": 100,
  "preview_file": "/path/to/preview.jpg",
  "model_path": "/app/models/best.pt",
  "confidence": 0.5
}
```

**Response:**
```json
{
  "success": true,
  "detected_frames": 45,
  "message": "Successfully processed 45 frames"
}
```

### `POST /test-detect`
Test YOLO model loading

## 🔧 Configuration

Environment variables:

- `PORT` - Port to run on (default: 8000)
- `YOLO_MODEL_PATH` - Path to YOLO model weights
- `MIN_CONFIDENCE` - Detection confidence threshold

## 📊 Resource Requirements

- **CPU:** 1-2 vCPU
- **RAM:** 2GB minimum, 4GB recommended
- **Storage:** 500MB for model + processed files

## 🐛 Debugging

View logs:
```bash
railway logs --service yolo-service
```

Test locally:
```bash
curl http://localhost:8000/health
curl -X POST http://localhost:8000/test-detect
```

