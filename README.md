# AI Backend - Video Processing

AI-powered video processing backend with YOLO detection, OCR, and multi-job queue management.

## 🎯 Features

- **Multi-job processing** - Process up to 3 videos simultaneously
- **Automatic queueing** - Jobs auto-queue when at capacity
- **Job persistence** - Jobs saved to disk, survive restarts
- **Data management** - Delete jobs and all associated files
- **YOLO detection** - AI object detection on video frames
- **OCR processing** - Text extraction with EasyOCR
- **Real-time monitoring** - Live progress tracking and preview
- **Web dashboard** - Clean, modern UI for job management
- **RESTful API** - Complete API for integration
- **Docker ready** - Single container deployment

## 📁 Project Structure

```
AI backend/
├── src/                    # TypeScript backend source
│   ├── config/            # Configuration
│   ├── controllers/       # Request handlers
│   ├── routes/            # API routes
│   ├── services/          # Business logic
│   └── middleware/        # Auth & error handling
├── public/                 # Web dashboard
│   ├── index.html         # Job list page
│   └── job-detail.html    # Job detail page
├── python/                 # Python detection
│   ├── detector.py        # YOLO + OCR logic
│   └── requirements.txt   # Python dependencies
├── models/                 # YOLO model weights
├── data/                   # Job persistence (jobs.json)
├── uploads/                # Uploaded videos
├── frames/                 # Extracted frames & results
├── Dockerfile             # Docker configuration
├── package.json           # Node.js dependencies
├── tsconfig.json          # TypeScript config
└── .gitignore            # Git ignore rules
```

## 🚀 Quick Start

### Prerequisites

- Node.js 20+
- Python 3.12
- FFmpeg

### Local Development

**1. Install Node.js dependencies:**
```bash
npm install
```

**2. Set up Python environment:**
```bash
cd python
python -m venv venv

# Windows
.\venv\Scripts\Activate.ps1

# Linux/Mac
source venv/bin/activate

pip install -r requirements.txt
```

**3. Configure environment:**
Create `.env` file:
```env
API_KEY=your-secret-key
PORT=3000
NODE_ENV=development
```

**4. Build and run:**
```bash
npm run build
npm run dev
```

Open `http://localhost:3000`

### Docker

**Build:**
```bash
docker build -t ai-backend .
```

**Run:**
```bash
docker run -p 3000:3000 \
  -e API_KEY=your-secret-key \
  ai-backend
```

## 📡 API Endpoints

All endpoints require `X-API-Key` header.

### Videos

| Method | Path | Description |
|--------|------|-------------|
| `POST` | `/api/videos/upload` | Upload video and start processing |
| `GET` | `/api/videos/:id/items` | Get detected items |

### Jobs

| Method | Path | Description |
|--------|------|-------------|
| `GET` | `/api/jobs` | List all jobs with queue stats |
| `GET` | `/api/jobs/:id/status` | Get job status and progress |

### Skins

| Method | Path | Description |
|--------|------|-------------|
| `GET` | `/api/skins/refined?videoId=xxx` | Get refined detection results |

**Full API documentation:** [APIPath.md](./APIPath.md) or visit `/docs.html`

---

## 🚀 Deploy to Hetzner Cloud

**⚡ Quick Deploy (5 minutes):** [QUICK_DEPLOY.md](QUICK_DEPLOY.md)

**📖 Complete Guide:** [DEPLOYMENT.md](DEPLOYMENT.md)

**Auto-Deploy Script:** Run `deploy.sh` on your server for automated setup!

## 🧪 Testing

### Test API Key
```bash
curl http://localhost:3000/api/test-key \
  -H "X-API-Key: your-secret-key"
```

### Upload Video
```bash
curl -X POST http://localhost:3000/api/videos/upload \
  -H "X-API-Key: your-secret-key" \
  -F "video=@/path/to/video.mp4"
```

### Get All Jobs
```bash
curl http://localhost:3000/api/jobs \
  -H "X-API-Key: your-secret-key"
```

## 🎨 Web Interface

- **Landing Page** (`/`) - View all jobs, upload videos
- **Job Detail** (`/job-detail.html?jobId=xxx`) - Live progress, results

## ⚙️ Configuration

Environment variables:

| Variable | Default | Description |
|----------|---------|-------------|
| `API_KEY` | `change-me-in-production` | API authentication key |
| `PORT` | `3000` | Server port |
| `NODE_ENV` | `development` | Environment mode |
| `PYTHON_EXECUTABLE` | `auto-detected` | Python path |
| `YOLO_MODEL_PATH` | `models/.../best.pt` | YOLO model file |
| `MIN_CONFIDENCE` | `0.5` | Detection threshold |

## 🏗️ Architecture

```
┌─────────────────────────────────────────┐
│         Node.js Backend (Express)       │
│  - API endpoints                        │
│  - Job queue (3 concurrent)             │
│  - FFmpeg video processing              │
│  - Multer file uploads                  │
└──────────────┬──────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────┐
│      Python Detection (subprocess)      │
│  - YOLO object detection                │
│  - EasyOCR text extraction              │
│  - Frame-by-frame processing            │
└─────────────────────────────────────────┘
```

## 🔒 Security

- API key authentication required
- Non-root Docker container
- Environment-based secrets
- Input validation
- Rate limiting (3 concurrent jobs max)

## 🐛 Troubleshooting

### Python Not Found
Ensure Python 3.12 is installed and in PATH, or set `PYTHON_EXECUTABLE` env var.

### Model File Missing
Verify `models/my_model/train/weights/best.pt` exists and is not in `.gitignore`.

### FFmpeg Not Found
Install FFmpeg: `apt-get install ffmpeg` (Linux) or `brew install ffmpeg` (Mac).

### API 401 Error
Check API key is set and matches between server and client.

## 📦 Dependencies

### Node.js
- Express - Web framework
- TypeScript - Type safety
- Multer - File uploads
- FFmpeg - Video processing

### Python
- Ultralytics (YOLO) - Object detection
- EasyOCR - Text extraction
- OpenCV - Image processing
- NumPy - Array operations

## 🛠️ Development

```bash
# Install dependencies
npm install

# Build TypeScript
npm run build

# Run development server (watch mode)
npm run dev

# Run production server
npm start
```

## 📝 Scripts

| Command | Description |
|---------|-------------|
| `npm run dev` | Development server with auto-reload |
| `npm run build` | Build TypeScript to JavaScript |
| `npm start` | Run production server |

## 📄 License

MIT License

## 🙏 Acknowledgments

- YOLO (Ultralytics) for object detection
- EasyOCR for text extraction
- FFmpeg for video processing

---

**Made with ❤️ using Node.js, Python, and YOLO**
