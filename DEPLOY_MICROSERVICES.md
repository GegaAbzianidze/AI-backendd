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
git commit -m "Microservices architecture"
git push
```

### Step 2: Deploy YOLO Service First

1. **Go to [railway.app](https://railway.app)**
2. **Click "New Project"**
3. **Deploy from GitHub repo**
4. **Important: In Advanced Settings:**
   - **Root Directory:** `yolo-service`
   - This tells Railway to build from the yolo-service subdirectory
5. **Environment Variables (optional):**
   - `PORT=8000`
   - `MIN_CONFIDENCE=0.5`
6. **Deploy!**

**Get the URL:**
- Go to **Settings** → **Domains**
- Click **Generate Domain**
- Copy the URL: `https://yolo-service-production-xxxx.up.railway.app`

### Step 3: Deploy Backend Service

1. **Create another project** (or add service to same project)
2. **Deploy from GitHub repo**  
3. **Important: In Advanced Settings:**
   - **Root Directory:** `.` (root, default)
   - **Dockerfile Path:** `Dockerfile.backend`
4. **Set Environment Variables:**
   ```
   API_KEY=your-super-secure-key
   YOLO_SERVICE_URL=https://yolo-service-production-xxxx.up.railway.app
   PORT=3000
   ```
   ⚠️ **Replace the YOLO_SERVICE_URL** with your actual YOLO service URL from Step 2!

5. **Deploy!**

### Step 4: Get Backend URL

- Go to **Settings** → **Domains**  
- Click **Generate Domain**
- Your app: `https://backend-production-xxxx.up.railway.app`

## ✅ Test Your Deployment

### Test YOLO Service

```bash
curl https://your-yolo-service.up.railway.app/health
```

Should return:
```json
{
  "status": "healthy",
  "torch_available": true,
  "opencv_available": true,
  "yolo_available": true
}
```

### Test Backend

```bash
curl https://your-backend.up.railway.app/api/test-key \
  -H "X-API-Key: your-super-secure-key"
```

Should return:
```json
{
  "success": true,
  "message": "API key is valid!"
}
```

### Test Full Flow

1. Open `https://your-backend.up.railway.app` in browser
2. Enter API key
3. Upload a video
4. Watch it process! 🎉

## 🎯 Alternative: Single Project with Multiple Services

You can also deploy both as services in a single Railway project:

1. **Create new project**
2. **Add service** → GitHub repo (YOLO)
   - Root Directory: `yolo-service`
3. **Add another service** → Same GitHub repo (Backend)
   - Root Directory: `.`
   - Dockerfile: `Dockerfile.backend`
4. **Link them:**
   - In Backend service variables:
   - `YOLO_SERVICE_URL=${{yolo-service.RAILWAY_PRIVATE_DOMAIN}}`

Railway will create internal networking between services!

## 💰 Cost Breakdown

### YOLO Service
- **2GB RAM, 2 vCPU**
- ~$8-10/month

### Backend Service
- **1GB RAM, 1 vCPU**
- ~$5-7/month

**Total: ~$13-17/month**

**Advantages:**
✅ Much smaller Docker images (build faster)
✅ Scale services independently  
✅ Better resource utilization
✅ Cleaner architecture

## 🐛 Troubleshooting

### "YOLO service unavailable"

**Check:**
1. YOLO service is deployed and running
2. `YOLO_SERVICE_URL` is set correctly in backend
3. Health check passes: `curl https://yolo-service/health`

**Backend will fallback to local Python** if service is unavailable (requires Python in backend image).

### "Build failed"

**YOLO Service:**
- Check `yolo-service/Dockerfile` exists
- Check model files are in git (or accessible)
- View build logs in Railway

**Backend Service:**
- Check `Dockerfile.backend` exists
- Verify no Python dependencies in package.json
- View build logs in Railway

### "Cannot connect services"

If using internal networking:
```
YOLO_SERVICE_URL=${{yolo-service.RAILWAY_PRIVATE_DOMAIN}}
```

If using public URLs:
```
YOLO_SERVICE_URL=https://yolo-service.up.railway.app
```

## 📊 Monitoring

### Railway Dashboard

Each service shows:
- CPU usage
- Memory usage
- Request count
- Build/deploy logs
- Metrics

### CLI Monitoring

```bash
# View YOLO service logs
railway logs --service yolo-service

# View backend logs
railway logs --service backend

# View all services
railway status
```

## 🔄 Updates & Redeployment

### Auto-Deploy on Push

Both services automatically redeploy when you push to GitHub!

```bash
# Make changes
git add .
git commit -m "Updated feature"
git push

# Railway automatically:
# 1. Rebuilds changed services
# 2. Runs health checks
# 3. Switches traffic
```

### Manual Deploy

```bash
# Deploy specific service
railway up --service backend
railway up --service yolo-service
```

## 🎨 Optional: Custom Domains

Add custom domains to each service:

**Backend:**
```
api.yourdomain.com → backend.up.railway.app
```

**YOLO Service:**
```
yolo.yourdomain.com → yolo-service.up.railway.app
```

Then update backend env:
```
YOLO_SERVICE_URL=https://yolo.yourdomain.com
```

## 🎉 You're Done!

Your microservices are now:
- ✅ Deployed to Railway
- ✅ Auto-scaling independently
- ✅ Communicating via HTTP
- ✅ Auto-deploying on push
- ✅ Monitored with metrics

**Test your app:**
`https://your-backend.up.railway.app`

Enjoy your scalable AI backend! 🚀✨

