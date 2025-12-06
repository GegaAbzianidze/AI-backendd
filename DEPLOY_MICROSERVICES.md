# Deploy Microservices to Railway

## 🏗️ Architecture Overview

Your AI Backend is now split into 2 services:

```
┌─────────────────┐    HTTP     ┌──────────────────┐
│  Backend API    │ ────────────> │  YOLO Service    │
│  (Node.js)      │              │  (Python FastAPI) │
│  Port 3000      │ <──────────── │  Port 8000       │
└─────────────────┘    Results   └──────────────────┘
```

## 🚀 Deployment Steps

### Step 1: Push to GitHub

```bash
# In your project root
git add .
git commit -m "Microservices architecture with Railway config"
git push
```

### Step 2: Deploy YOLO Service

1. **Go to [railway.app](https://railway.app)**
2. **Click "New Project"**
3. **Deploy from GitHub repo**
4. **⚠️ IMPORTANT: Configure Build Settings**
   
   In the Railway dashboard:
   - Click on your service
   - Go to **Settings** → **Build**
   - **Root Directory:** `.` (leave as root - important!)
   - **Dockerfile Path:** `yolo-service/Dockerfile`
   
   Or use the `railway.json` in `yolo-service/` directory (Railway auto-detects it)

5. **Environment Variables (optional):**
   ```
   PORT=8000
   MIN_CONFIDENCE=0.5
   ```

6. **Deploy!**

**Get the URL:**
- Go to **Settings** → **Networking** → **Public Networking**
- Click **Generate Domain**
- Copy the URL: `https://yolo-service-production-xxxx.up.railway.app`

### Step 3: Deploy Backend Service

1. **In the same project, click "New Service"** (or create new project)
2. **Deploy from GitHub repo** (same repository)
3. **Configure Build Settings:**
   - **Root Directory:** `.` (root)
   - **Dockerfile Path:** `Dockerfile.backend`
   
4. **Set Environment Variables:**
   ```
   API_KEY=your-super-secure-key-here
   YOLO_SERVICE_URL=https://yolo-service-production-xxxx.up.railway.app
   PORT=3000
   NODE_ENV=production
   ```
   
   ⚠️ **Important:** Replace `YOLO_SERVICE_URL` with your actual YOLO service URL from Step 2!

5. **Deploy!**

### Step 4: Get Backend URL

- Go to **Settings** → **Networking** → **Public Networking**
- Click **Generate Domain**
- Your app: `https://backend-production-xxxx.up.railway.app`

## ⚡ Alternative: Internal Networking (Recommended)

If both services are in the same Railway project, use internal networking:

### YOLO Service
- No special config needed

### Backend Service Variables:
```
API_KEY=your-super-secure-key
YOLO_SERVICE_URL=http://${{RAILWAY_SERVICE_NAME}}.railway.internal:8000
```

Or reference by service name:
```
YOLO_SERVICE_URL=http://yolo-service.railway.internal:8000
```

This keeps traffic internal to Railway's network (faster & free)!

## ✅ Test Your Deployment

### Test YOLO Service

```bash
curl https://your-yolo-service.up.railway.app/health
```

**Expected Response:**
```json
{
  "status": "healthy",
  "torch_available": true,
  "cuda_available": false,
  "opencv_available": true,
  "yolo_available": true
}
```

### Test Backend

```bash
curl https://your-backend.up.railway.app/api/test-key \
  -H "X-API-Key: your-super-secure-key"
```

**Expected Response:**
```json
{
  "success": true,
  "message": "API key is valid!"
}
```

### Test Full Flow

1. Open `https://your-backend.up.railway.app` in browser
2. Enter your API key when prompted
3. Click "Save Key"
4. Click "+ New Job"
5. Upload a video
6. Watch it process across both services! 🎉

## 🐛 Troubleshooting

### Build Error: "model not found"

**Problem:** Docker can't find model files

**Solution:** Make sure:
1. Build from root directory (`.`)
2. Dockerfile path is `yolo-service/Dockerfile`
3. Model files are committed to git (check `.gitignore`)

**Verify model exists:**
```bash
ls -lh models/my_model/train/weights/best.pt
```

### Build Error: "COPY failed"

**Problem:** Dockerfile trying to copy from parent directory

**Solution:** Already fixed! The Dockerfile now expects to be built from root with paths like:
```dockerfile
COPY yolo-service/main.py .
COPY python/detector.py ./python/detector.py
```

### "YOLO service unavailable"

**Check:**
1. YOLO service is deployed and shows "Active"
2. Health check is passing: `/health` endpoint
3. `YOLO_SERVICE_URL` is correctly set in backend
4. No typos in the URL

**Test:**
```bash
# Test health endpoint
curl https://your-yolo-service.up.railway.app/health

# Check logs
railway logs --service yolo-service
```

### "Module not found" errors

**YOLO Service:**
- Check `requirements.txt` is in `yolo-service/`
- Verify all dependencies installed

**Backend:**
- Check `package.json` dependencies
- Run `npm install` locally first

### Build timeout

**Solution:** Split the build or increase resources
- Go to **Settings** → **Resources**
- Increase RAM to 4GB during build
- Can reduce back to 2GB after deployment

## 📊 Estimated Costs

### Railway Pricing

**YOLO Service (Recommended):**
- 2GB RAM, 2 vCPU
- ~$8-10/month

**Backend Service (Recommended):**
- 1GB RAM, 1 vCPU  
- ~$5-7/month

**Total: ~$13-17/month**

**Cheaper alternatives:**
- Use 1GB RAM for YOLO (slower): ~$10/month total
- Use serverless mode (auto-sleep when idle): ~$5/month total

## 🔧 Configuration Tips

### Railway Project Structure

**Option 1: Separate Projects**
```
Project: YOLO Service
  - Service: yolo-service (from GitHub)

Project: Backend
  - Service: backend (from GitHub)
  - Variable: YOLO_SERVICE_URL (public URL)
```

**Option 2: Single Project (Recommended)**
```
Project: AI Backend
  - Service: yolo-service
  - Service: backend
  - Internal networking between services
```

### Build Configuration

**YOLO Service:**
```json
{
  "build": {
    "builder": "DOCKERFILE",
    "dockerfilePath": "yolo-service/Dockerfile"
  }
}
```

**Backend Service:**
```json
{
  "build": {
    "builder": "DOCKERFILE",
    "dockerfilePath": "Dockerfile.backend"
  }
}
```

## 🚀 Auto-Deploy on Push

Both services automatically redeploy when you push to GitHub!

```bash
# Make changes
git add .
git commit -m "Updated feature"
git push

# Railway automatically:
# 1. Detects changes
# 2. Rebuilds affected services
# 3. Runs health checks
# 4. Switches traffic
```

## 💡 Performance Tips

### 1. Use Internal Networking
```
YOLO_SERVICE_URL=http://yolo-service.railway.internal:8000
```
- Faster (no internet roundtrip)
- Free (doesn't count as egress)

### 2. Enable Caching
Railway caches Docker layers automatically

### 3. Scale Appropriately
- Start with minimum resources
- Monitor usage in dashboard
- Scale up if needed

### 4. Use Shared Volumes
For persistent data between deployments:
- Go to **Settings** → **Volumes**
- Add volume at `/app/data`
- 10GB recommended

## 📈 Monitoring

### Railway Dashboard

Each service shows:
- ✅ CPU usage graph
- ✅ Memory usage graph
- ✅ Network traffic
- ✅ Build logs
- ✅ Deploy logs
- ✅ Runtime logs
- ✅ Metrics & analytics

### CLI Monitoring

```bash
# Install Railway CLI
npm install -g @railway/cli

# Login
railway login

# Link project
railway link

# View logs
railway logs --service yolo-service
railway logs --service backend

# Check status
railway status
```

## 🔄 Rollback

If deployment fails:

### Via Dashboard:
1. Go to **Deployments**
2. Find previous working deployment
3. Click **"Redeploy"**

### Via CLI:
```bash
railway rollback
```

## 🎨 Custom Domains (Optional)

### Add Domains

**Backend:**
1. Go to **Settings** → **Networking** → **Public Networking**
2. Add custom domain: `api.yourdomain.com`
3. Add CNAME record: `api CNAME backend.up.railway.app`

**YOLO Service:**
1. Add custom domain: `yolo.yourdomain.com`  
2. Add CNAME record: `yolo CNAME yolo-service.up.railway.app`

### Update Backend Config
```
YOLO_SERVICE_URL=https://yolo.yourdomain.com
```

## ✅ Deployment Checklist

Before deploying:
- [ ] Code pushed to GitHub
- [ ] `.gitignore` excludes `node_modules`, `.env`, `venv`
- [ ] Model file exists: `models/my_model/train/weights/best.pt`
- [ ] Both Dockerfiles build successfully locally

For YOLO Service:
- [ ] Build from root directory
- [ ] Dockerfile path: `yolo-service/Dockerfile`
- [ ] `railway.json` in `yolo-service/` directory

For Backend:
- [ ] Build from root directory
- [ ] Dockerfile path: `Dockerfile.backend`
- [ ] `YOLO_SERVICE_URL` environment variable set
- [ ] `API_KEY` environment variable set

After deploying:
- [ ] Both services show "Active" status
- [ ] Health checks passing
- [ ] Can access both URLs
- [ ] Test API key endpoint works
- [ ] Upload a test video successfully

## 🎉 Success!

Once deployed, your architecture looks like:

```
Internet
   ↓
Backend (https://backend.up.railway.app)
   ↓ internal/private network
YOLO Service (http://yolo-service.railway.internal:8000)
```

**Features:**
- ✅ Auto-scaling
- ✅ Auto-deploys
- ✅ Health monitoring
- ✅ Log aggregation
- ✅ Metrics & analytics
- ✅ Zero-downtime deployments

## 📞 Support

- **Railway Docs:** https://docs.railway.app
- **Discord:** https://discord.gg/railway
- **Status:** https://status.railway.app

## 🚀 Quick Commands

```bash
# View logs (follow mode)
railway logs -f --service yolo-service
railway logs -f --service backend

# Restart service
railway restart --service yolo-service

# Open dashboard
railway open

# Deploy manually
railway up --service yolo-service
```

Happy deploying! 🎊
