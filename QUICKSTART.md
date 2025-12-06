# Quick Start Guide

Get the AI Backend running in 5 minutes!

## 🚀 Fastest Way - Docker

1. **Clone and enter directory:**
   ```bash
   cd "AI backend"
   ```

2. **Create `.env` file:**
   ```bash
   echo "API_KEY=change-me-in-production" > .env
   ```

3. **Run with Docker Compose:**
   ```bash
   docker-compose up --build
   ```

4. **Open your browser:**
   ```
   http://localhost:3000
   ```

5. **Enter API key in the web interface:**
   ```
   change-me-in-production
   ```

Done! 🎉

---

## 💻 Local Development Setup

### Step 1: Install Python Dependencies

```bash
cd python
python -m venv venv

# Windows
.\venv\Scripts\Activate.ps1

# Linux/Mac  
source venv/bin/activate

pip install -r requirements.txt
cd ..
```

### Step 2: Install Node Dependencies

```bash
npm install
```

### Step 3: Create `.env` File

Create `.env` in the root:
```env
API_KEY=change-me-in-production
PORT=3000
```

### Step 4: Build & Run

```bash
npm run build
npm run dev
```

### Step 5: Open Browser

```
http://localhost:3000
```

Enter API key: `change-me-in-production`

---

## 📤 Upload Your First Video

1. Click **"+ New Job"** button
2. Select a video file (MP4, MOV, etc.)
3. Watch it process in real-time!
4. View results when complete

---

## 🧪 Test the API

### Test API Key
```bash
curl http://localhost:3000/api/test-key \
  -H "X-API-Key: change-me-in-production"
```

### Upload Video
```bash
curl -X POST http://localhost:3000/api/videos/upload \
  -H "X-API-Key: change-me-in-production" \
  -F "video=@/path/to/your/video.mp4"
```

### Get All Jobs
```bash
curl http://localhost:3000/api/jobs \
  -H "X-API-Key: change-me-in-production"
```

---

## ⚙️ Common Issues

### Port Already in Use
Change port in `.env`:
```env
PORT=8080
```

### Python Not Found
Make sure you're using Python 3.12 or 3.11:
```bash
python --version
```

### API 401 Error
Check that:
- API key is set in `.env`
- You entered the key in the web interface
- Server was restarted after changing `.env`

### Docker Build Fails
Try without cache:
```bash
docker-compose build --no-cache
docker-compose up
```

---

## 🎯 Next Steps

1. **Read API docs:** [APIPath.md](./APIPath.md)
2. **Deploy to cloud:** [DEPLOYMENT.md](./DEPLOYMENT.md)
3. **Customize:** Edit `src/config/env.ts` for configuration
4. **Secure:** Change API_KEY to a strong random value

---

## 📊 What Happens When You Upload?

1. Video uploads (progress bar shows)
2. Frames extracted with FFmpeg
3. YOLO AI detects objects in each frame
4. EasyOCR reads text
5. Results compiled and displayed
6. Live preview updates in real-time

Processing time depends on video length and your hardware.

---

## 🔥 Quick Deploy to Fly.io

```bash
# Install Fly CLI
curl -L https://fly.io/install.sh | sh

# Login
fly auth login

# Deploy
fly launch
fly secrets set API_KEY=your-secure-key
fly deploy

# Open
fly open
```

See [DEPLOYMENT.md](./DEPLOYMENT.md) for details.

---

## 💡 Tips

- **Multiple Videos:** Upload up to 3 at once, rest auto-queue
- **Live Updates:** Dashboard refreshes every 2 seconds
- **Job History:** All jobs shown on landing page
- **Direct Access:** Use `?jobId=xxx` to link to specific job
- **API Integration:** Use REST API for custom workflows

---

## 📚 Learn More

- **Full README:** [README.md](./README.md)
- **API Reference:** [APIPath.md](./APIPath.md)
- **Deployment:** [DEPLOYMENT.md](./DEPLOYMENT.md)

Happy processing! 🎬✨

