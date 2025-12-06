# Railway Quick Start - 5 Minutes to Deploy! 🚂

The absolute fastest way to deploy your AI Backend.

---

## 🚀 Method 1: Deploy from GitHub (Easiest - No CLI needed!)

### Step 1: Push Your Code to GitHub

```bash
# If not already a git repo
git init
git add .
git commit -m "Ready for Railway deployment"

# Create a new repo on GitHub.com, then:
git remote add origin https://github.com/YOUR_USERNAME/YOUR_REPO.git
git branch -M main
git push -u origin main
```

### Step 2: Deploy on Railway

1. Go to **[railway.app](https://railway.app)** and sign up/login
2. Click **"New Project"**
3. Select **"Deploy from GitHub repo"**
4. Choose your repository
5. Railway automatically detects your Dockerfile! ✨
6. Click **"Deploy Now"**

### Step 3: Set Your API Key

While it's deploying:
1. Click on your service (the blue box)
2. Go to **"Variables"** tab
3. Click **"+ New Variable"**
4. Add:
   - Name: `API_KEY`
   - Value: `your-super-secure-key` (make it strong!)
5. Click **"Add"**

The service will auto-restart with the new variable.

### Step 4: Get Your URL

1. Go to **"Settings"** tab
2. Click **"Generate Domain"**
3. Copy your URL: `https://ai-backend-production-xxxx.up.railway.app`

### Step 5: Test It!

```bash
curl https://your-app.up.railway.app/api/test-key \
  -H "X-API-Key: your-super-secure-key"
```

**You should see:**
```json
{"success": true, "message": "API key is valid!"}
```

## ✅ Done! Your app is live! 🎉

---

## 🚀 Method 2: Deploy with Railway CLI (For Pro Users)

### Step 1: Install Railway CLI

**Windows (PowerShell):**
```powershell
iwr https://railway.app/install.ps1 -useb | iex
```

**macOS/Linux:**
```bash
curl -fsSL https://railway.app/install.sh | sh
```

**Or with npm (all platforms):**
```bash
npm install -g @railway/cli
```

### Step 2: Login & Deploy

```bash
# Login to Railway
railway login

# Navigate to your project
cd "AI backend"

# Initialize Railway project
railway init

# Set your API key
railway variables set API_KEY=your-super-secure-key

# Deploy!
railway up
```

### Step 3: Open Your App

```bash
railway open
```

## ✅ Done! 🎊

---

## 📱 What Happens Next?

### Automatic Deployments
Every time you push to GitHub, Railway automatically:
1. Builds your Docker image
2. Deploys the new version
3. Runs health checks
4. Switches traffic to new deployment

### View Live Logs
```bash
railway logs -f
```

### Monitor Your App
Go to your Railway dashboard to see:
- CPU & Memory usage
- Build & deploy logs
- Request metrics
- Health status

---

## 🎯 Quick Test Your Deployment

### 1. Test API Key
```bash
curl https://your-app.up.railway.app/api/test-key \
  -H "X-API-Key: your-api-key"
```

### 2. Upload a Video (from web interface)
1. Open `https://your-app.up.railway.app` in browser
2. Enter your API key when prompted
3. Click **"Save Key"**
4. Click **"+ New Job"**
5. Upload a video file
6. Watch it process in real-time! 🎬

### 3. Test with cURL
```bash
curl -X POST https://your-app.up.railway.app/api/videos/upload \
  -H "X-API-Key: your-api-key" \
  -F "video=@/path/to/your/video.mp4"
```

---

## 💡 Pro Tips

### 1. Add Custom Domain
1. Go to **Settings** → **Domains**
2. Click **"Custom Domain"**
3. Enter: `api.yourdomain.com`
4. Add CNAME to your DNS:
   ```
   api  CNAME  your-app.up.railway.app
   ```

### 2. Add Persistent Storage
1. Go to **Settings** → **Volumes**  
2. Click **"Add Volume"**
3. Mount path: `/app/data`
4. Size: `10GB`

### 3. View Real-Time Logs
```bash
railway logs -f
```

### 4. Scale Resources
In dashboard:
- **Settings** → **Resources**
- Increase RAM/CPU as needed

### 5. Enable Metrics
Go to **Observability** tab for:
- Request rates
- Response times
- Error rates
- Resource usage

---

## 🆘 Troubleshooting

### "Can't access my app"
```bash
# Check deployment status
railway status

# View logs for errors
railway logs
```

### "401 Unauthorized"
Make sure you:
1. Set `API_KEY` in Railway variables
2. Entered the same key in web interface
3. Restarted the service after adding variables

### "Build failed"
```bash
# View build logs
railway logs --build

# Common fix: Deploy with light Dockerfile
# Edit railway.json:
{
  "build": {
    "dockerfilePath": "Dockerfile.light"
  }
}
```

### "App is slow"
1. Go to **Settings** → **Resources**
2. Increase RAM to 4GB
3. Increase CPU to 4 vCPU

---

## 📊 Estimated Costs

**Free Trial:**
- $5 in credits (no credit card needed!)
- Perfect for testing

**After Trial (~$10-15/month):**
- 2GB RAM, 2 vCPU
- 24/7 uptime
- 10GB storage
- Unlimited deployments

**Much cheaper than:**
- AWS (~$50/mo)
- Heroku (~$50/mo)
- Azure (~$60/mo)

---

## 🎉 You're All Set!

Your AI Backend is now:
- ✅ Live on Railway
- ✅ Auto-deploying on push
- ✅ HTTPS enabled
- ✅ Monitored with health checks
- ✅ Accessible worldwide

### Next Steps:
1. Share your API with your team
2. Update your frontend to use the new URL
3. Monitor usage in Railway dashboard
4. Scale as you grow

**Need help?** Check [RAILWAY_DEPLOYMENT.md](./RAILWAY_DEPLOYMENT.md) for complete documentation.

---

## 🔗 Useful Links

- **Your Dashboard:** https://railway.app/dashboard
- **Railway Docs:** https://docs.railway.app
- **Railway Discord:** https://discord.gg/railway
- **Railway Status:** https://status.railway.app

Welcome to Railway! 🚂✨

---

## 📋 Quick Command Reference

```bash
# Install CLI
npm i -g @railway/cli

# Login
railway login

# Initialize
railway init

# Deploy
railway up

# View logs
railway logs -f

# Set variables
railway variables set KEY=value

# Open dashboard
railway open

# Check status
railway status
```

Enjoy deploying! 🎊

