# AI Backend - Video Processing API

Multi-job video processing backend with AI detection, OCR, and real-time monitoring. Built with Node.js, Express, Python, YOLO, and EasyOCR.

## 🚀 Features

- **Multi-job processing** - Run up to 3 videos simultaneously
- **Automatic queueing** - Jobs queue when at capacity
- **Real-time monitoring** - Live preview and progress tracking
- **AI Detection** - YOLO-based object detection
- **OCR Processing** - Text extraction with EasyOCR
- **REST API** - Complete API for integration
- **Modern Dashboard** - Clean, minimal UI for job management
- **Docker Ready** - Full containerization support
- **Cloud Deployment** - Fly.io ready with one command

## 📋 Prerequisites

### Local Development
- Node.js 20+
- Python 3.12+ (for ML libraries compatibility)
- FFmpeg
- Virtual environment for Python

### Docker/Production
- Docker (all dependencies included)
- Fly.io CLI (for cloud deployment)

## 🛠️ Setup

### 1. Install Dependencies

**Node.js:**
```bash
npm install
```

**Python (with virtual environment):**
```bash
cd python
python -m venv venv
.\venv\Scripts\Activate.ps1  # Windows
source venv/bin/activate      # Linux/Mac
pip install -r requirements.txt
```

### 2. Environment Configuration

Create a `.env` file:
```bash
# API Security
API_KEY=your-secret-key-here

# Server
PORT=3000
NODE_ENV=development

# Python (optional, auto-detected)
PYTHON_EXECUTABLE=./python/venv/Scripts/python

# YOLO Model (optional)
YOLO_MODEL_PATH=./models/my_model/train/weights/best.pt
MIN_CONFIDENCE=0.5
```

### 3. Build TypeScript

```bash
npm run build
```

## 🏃 Running the Application

### Development Mode
```bash
npm run dev
```

### Production Mode
```bash
npm start
```

### Docker
```bash
# Build image
docker build -t ai-backend .

# Run container
docker run -p 8080:8080 \
  -e API_KEY=your-secret-key \
  ai-backend
```

### Docker Compose
```bash
docker-compose up --build
```

## 📚 Documentation

- **[API Documentation](./APIPath.md)** - Complete API reference with examples
- **[Deployment Guide](./DEPLOYMENT.md)** - Step-by-step Fly.io deployment

## 🌐 API Endpoints

All endpoints require `X-API-Key` header for authentication.

### Videos
- `POST /api/videos/upload` - Upload and process video
- `GET /api/videos/{videoId}/items` - Get detected items

### Jobs
- `GET /api/jobs` - List all jobs with stats
- `GET /api/jobs/{jobId}/status` - Get job status and progress

### Skins
- `GET /api/skins/refined?videoId={id}` - Get refined detection results

### Debug
- `GET /api/test-key` - Test API key validity

See [APIPath.md](./APIPath.md) for detailed documentation.

## 🎨 Web Interface

### Landing Page (`/`)
- View all jobs in real-time
- Upload new videos
- Monitor queue status (running/queued)
- Click jobs to view details

### Job Detail Page (`/job-detail.html?jobId=xxx`)
- Live video processing preview
- Real-time progress tracking
- Detected objects list
- Frame-by-frame analysis
- Download results

## 🏗️ Architecture

### Job Processing Pipeline

1. **Upload** - Video file received
2. **Queue** - Job queued if 3 already running
3. **Frame Extraction** - FFmpeg extracts frames (7 fps)
4. **AI Detection** - YOLO processes each frame
5. **OCR** - Text extraction from detected regions
6. **Results** - JSON output with all detections

### Concurrency Model

- **Max concurrent jobs:** 3
- **Queue:** Unlimited, auto-processes
- **Isolation:** Each job fully isolated
- **Progress tracking:** Real-time updates

### Tech Stack

**Backend:**
- Node.js 20 + Express
- TypeScript
- FFmpeg (video processing)
- Multer (file uploads)

**AI/ML:**
- Python 3.12
- Ultralytics YOLO v8
- EasyOCR
- OpenCV
- NumPy

**Frontend:**
- Vanilla JavaScript
- Modern CSS (no frameworks)
- Real-time polling

## 📦 Project Structure

```
├── src/
│   ├── config/          # Configuration & environment
│   ├── controllers/     # Request handlers
│   ├── routes/          # API routes
│   ├── services/        # Business logic
│   │   ├── jobService.ts       # Job queue management
│   │   ├── videoService.ts     # Video processing
│   │   └── detectionService.ts # AI detection
│   ├── middleware/      # Auth & error handling
│   └── types/           # TypeScript definitions
├── public/
│   ├── index.html       # Landing page (job list)
│   └── job-detail.html  # Job detail view
├── python/
│   ├── detector.py      # Python detection worker
│   └── requirements.txt # Python dependencies
├── models/              # YOLO model weights
├── uploads/             # Temporary video storage
├── frames/              # Processed frames & results
├── Dockerfile           # Production container
├── fly.toml            # Fly.io configuration
└── docker-compose.yml  # Local Docker setup
```

## 🚢 Deployment

### Railway (Recommended) 🚂

**Best for:** Large Docker images, ML apps, easy setup

**Quick Deploy:**
1. Push to GitHub
2. Go to [railway.app](https://railway.app)
3. Click "Deploy from GitHub repo"
4. Set `API_KEY` environment variable
5. Done! 🎉

**CLI Deploy:**
```bash
npm i -g @railway/cli
railway login
railway init
railway up
```

See [RAILWAY_DEPLOYMENT.md](./RAILWAY_DEPLOYMENT.md) for complete guide.

### Fly.io (Alternative)

**Note:** May have issues with large Docker images (8GB limit)

```bash
curl -L https://fly.io/install.sh | sh
fly auth login
fly launch
fly secrets set API_KEY=your-secure-key
fly deploy --dockerfile Dockerfile.light
```

See [DEPLOYMENT.md](./DEPLOYMENT.md) for complete guide.

### Other Platforms

The Docker container works on any platform that supports Docker:
- AWS ECS/Fargate
- Google Cloud Run
- Azure Container Instances
- DigitalOcean App Platform
- Heroku Container Registry
- Railway.app

## 🔐 Security

- **API Key Authentication** - Required for all endpoints
- **Input Validation** - File type and size checks
- **Rate Limiting** - 3 concurrent jobs max
- **Isolated Processing** - Jobs don't interfere
- **Non-root Container** - Docker runs as unprivileged user

## 🐛 Troubleshooting

### Python Import Errors
Use Python 3.12 or 3.11 (not 3.14) - ML libraries need compatible versions.

### FFmpeg Not Found
Install FFmpeg: `apt-get install ffmpeg` (Linux) or `brew install ffmpeg` (Mac)

### API 401 Errors
Check API key is set and matches between server and client.

### Build Failures
Clear cache: `npm run build && docker build --no-cache -t ai-backend .`

### Memory Issues
Increase Docker memory: Edit Docker Desktop settings or use larger VM.

## 📊 Monitoring

The application includes:
- Health check endpoint (Docker/Fly.io)
- Real-time job statistics
- Live progress tracking
- Error reporting
- Queue monitoring

## 🤝 Contributing

1. Fork the repository
2. Create feature branch (`git checkout -b feature/amazing`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing`)
5. Open Pull Request

## 📄 License

MIT License - See LICENSE file for details

## 🔗 Resources

- [API Documentation](./APIPath.md)
- [Deployment Guide](./DEPLOYMENT.md)
- [Fly.io Docs](https://fly.io/docs)
- [YOLO Documentation](https://docs.ultralytics.com)
- [EasyOCR GitHub](https://github.com/JaidedAI/EasyOCR)

## 📞 Support

For issues and questions:
- Open an issue on GitHub
- Check [APIPath.md](./APIPath.md) for API usage
- See [DEPLOYMENT.md](./DEPLOYMENT.md) for deployment help

---

Made with ❤️ using Node.js, Python, and YOLO
