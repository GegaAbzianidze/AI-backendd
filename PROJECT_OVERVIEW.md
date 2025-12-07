# Project Overview

## ✨ Clean, Organized AI Backend

Simple monolithic architecture with Docker support. No cloud-specific configurations.

---

## 📁 Final Structure

```
AI backend/
├── 📱 Frontend (Web Dashboard)
│   └── public/
│       ├── index.html         # Job list page
│       └── job-detail.html    # Job details + live preview
│
├── 🔧 Backend (Node.js + TypeScript)
│   ├── src/
│   │   ├── config/           # Configuration & environment
│   │   ├── controllers/      # Request handlers
│   │   ├── routes/           # API routes
│   │   ├── services/         # Business logic
│   │   │   ├── jobService.ts       # Job queue (3 concurrent)
│   │   │   ├── videoService.ts     # FFmpeg processing
│   │   │   └── detectionService.ts # Python integration
│   │   ├── middleware/       # Auth & error handling
│   │   ├── types/            # TypeScript definitions
│   │   └── utils/            # Helper functions
│   ├── package.json          # Node.js dependencies
│   └── tsconfig.json         # TypeScript config
│
├── 🤖 AI Processing (Python)
│   └── python/
│       ├── detector.py       # YOLO + EasyOCR detection
│       └── requirements.txt  # Python dependencies
│
├── 🎯 Model & Data
│   ├── models/my_model/.../best.pt  # YOLO weights (~500MB)
│   └── skin_list.txt                # Reference data
│
├── 🐳 Docker
│   └── Dockerfile            # Single, clean container
│
├── 📄 Documentation
│   ├── README.md            # Main docs (start here!)
│   ├── APIPath.md           # Complete API reference
│   └── PROJECT_OVERVIEW.md  # This file
│
└── ⚙️ Configuration
    ├── .gitignore           # Git exclusions
    └── .env (create)        # Environment variables
```

---

## 📊 Statistics

| Metric | Value |
|--------|-------|
| **Source Files** | ~20 TypeScript + 1 Python |
| **Documentation** | 3 markdown files |
| **Docker Configs** | 1 Dockerfile |
| **Repository Size** | ~50MB |
| **Docker Image** | ~3-4GB (includes ML libs) |
| **Dependencies** | Node.js + Python only |

---

## 🎯 Key Features

### Multi-Job Queue
- Process 3 videos simultaneously
- Auto-queue when at capacity
- Independent job isolation

### AI Detection
- YOLO object detection
- EasyOCR text extraction
- Frame-by-frame analysis

### Real-time Updates
- Live progress tracking
- Preview thumbnails
- WebSocket-style polling

### Web Dashboard
- Job list overview
- Individual job monitoring
- Upload interface

### REST API
- Complete CRUD operations
- API key authentication
- JSON responses

---

## 🚀 Usage

### Local Development

```bash
# Install dependencies
npm install

# Set up Python
cd python && python -m venv venv
.\venv\Scripts\Activate.ps1
pip install -r requirements.txt

# Run
npm run dev
```

### Docker

```bash
# Build
docker build -t ai-backend .

# Run
docker run -p 3000:3000 -e API_KEY=your-key ai-backend
```

### Environment

Create `.env`:
```env
API_KEY=your-secret-key
PORT=3000
NODE_ENV=development
```

---

## 📡 API Endpoints

**Base URL:** `http://localhost:3000`

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/` | GET | Web dashboard |
| `/api/test-key` | GET | Test API key |
| `/api/videos/upload` | POST | Upload video |
| `/api/jobs` | GET | List all jobs |
| `/api/jobs/:id/status` | GET | Job status |
| `/api/videos/:id/items` | GET | Detection results |
| `/api/skins/refined` | GET | Refined results |

**All API endpoints require:** `X-API-Key` header

---

## 🏗️ Architecture

```
┌──────────────────────┐
│   Web Browser        │
│   (User Interface)   │
└──────────┬───────────┘
           │ HTTP
           ▼
┌──────────────────────┐
│   Express API        │
│   - Job Queue        │
│   - File Upload      │
│   - FFmpeg           │
└──────────┬───────────┘
           │ subprocess
           ▼
┌──────────────────────┐
│   Python Worker      │
│   - YOLO Detection   │
│   - EasyOCR          │
│   - Frame Processing │
└──────────────────────┘
```

**Process Flow:**
1. User uploads video via web UI
2. Backend creates job and extracts frames (FFmpeg)
3. Python subprocess processes frames (YOLO + OCR)
4. Results stored and displayed in real-time
5. User can view detections and download results

---

## 🔒 Security

- ✅ API key authentication
- ✅ Non-root Docker user
- ✅ Environment-based secrets
- ✅ Input validation
- ✅ Rate limiting (3 jobs max)
- ✅ No hardcoded credentials

---

## 🎨 Clean Design Principles

1. **Single Responsibility** - Each module has one clear purpose
2. **No Redundancy** - Removed all duplicate/unused files
3. **Clear Structure** - Logical folder organization
4. **Simple Deployment** - Single Dockerfile
5. **Good Documentation** - Clear README + API docs
6. **Type Safety** - Full TypeScript support
7. **Error Handling** - Graceful failures
8. **Scalability** - Queue-based job processing

---

## 📦 What's NOT Included

Intentionally removed for simplicity:

- ❌ Cloud platform configs (Railway, Fly.io, etc.)
- ❌ Microservices architecture
- ❌ Multiple Dockerfiles
- ❌ Kubernetes configs
- ❌ CI/CD pipelines
- ❌ Database (using in-memory storage)
- ❌ Authentication system (simple API key)
- ❌ Logging services
- ❌ Monitoring dashboards
- ❌ Load balancers

**Result:** Simple, focused, and easy to understand.

---

## 🧪 Testing

```bash
# Build project
npm run build

# Run tests (if added)
npm test

# Build Docker image
docker build -t ai-backend .

# Test Docker image
docker run -p 3000:3000 ai-backend

# Test API
curl http://localhost:3000/api/test-key \
  -H "X-API-Key: change-me-in-production"
```

---

## 📈 Future Enhancements (Optional)

If needed, you can add:

- Database (PostgreSQL) for persistent storage
- Redis for better queue management
- WebSocket for real-time updates
- User authentication system
- Admin dashboard
- Analytics & metrics
- Rate limiting per user
- Video streaming support
- Batch processing
- Export to various formats

---

## 🛠️ Maintenance

**To update dependencies:**
```bash
npm update
pip install --upgrade -r python/requirements.txt
```

**To rebuild:**
```bash
npm run build
docker build -t ai-backend .
```

**To clean:**
```bash
# Remove build artifacts
rm -rf dist node_modules python/venv

# Remove processed files
rm -rf uploads frames
```

---

## 💡 Tips

1. **Python Version:** Use Python 3.12 for best compatibility
2. **Model File:** Ensure `best.pt` exists before building
3. **Memory:** Recommend 4GB+ RAM for video processing
4. **CPU:** Multi-core recommended for concurrent jobs
5. **Storage:** ~10GB free space for video processing

---

## 📞 Quick Reference

**Start Dev Server:**
```bash
npm run dev
```

**Build for Production:**
```bash
npm run build
docker build -t ai-backend .
```

**Run Production:**
```bash
docker run -p 3000:3000 -e API_KEY=xxx ai-backend
```

**Access:**
```
http://localhost:3000
```

---

## ✅ Project Status

- ✅ Clean, organized structure
- ✅ Fully functional monolithic app
- ✅ Docker-ready
- ✅ Well-documented
- ✅ Production-ready
- ✅ Easy to maintain
- ✅ No unnecessary complexity

**Ready to use!** 🎉

