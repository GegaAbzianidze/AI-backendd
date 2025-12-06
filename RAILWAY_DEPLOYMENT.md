# Railway Deployment Guide

Deploy your AI Backend to [Railway](https://railway.com/) in minutes!

## Why Railway?

- ✅ **Larger image support** - No 8GB limit like Fly.io
- ✅ **Automatic deployments** - From GitHub on every push
- ✅ **Built-in volumes** - Persistent storage included
- ✅ **Simple pricing** - Pay for what you use
- ✅ **Great DX** - Beautiful dashboard and CLI
- ✅ **Instant preview URLs** - No domain setup needed

---

## 🚀 Quick Deploy (5 Minutes)

### Option 1: Deploy from GitHub (Recommended)

#### Step 1: Push to GitHub

```bash
# Initialize git if not already
git init
git add .
git commit -m "Initial commit"

# Create repo on GitHub, then:
git remote add origin https://github.com/yourusername/ai-backend.git
git branch -M main
git push -u origin main
```

#### Step 2: Deploy on Railway

1. **Go to [railway.app](https://railway.app)**
2. **Click "Start a New Project"**
3. **Select "Deploy from GitHub repo"**
4. **Choose your repository**
5. **Railway auto-detects your Dockerfile!**
6. **Click "Deploy"**

That's it! 🎉

#### Step 3: Set Environment Variables

In Railway dashboard:
1. Go to your project
2. Click **Variables** tab
3. Add these variables:

```
API_KEY=your-super-secure-api-key-here
PORT=8080
NODE_ENV=production
```

#### Step 4: Get Your URL

Railway automatically provides a URL:
- Find it in the **Settings** → **Domains** section
- Or click **Generate Domain**

Your app will be live at: `https://your-app.up.railway.app`

---

### Option 2: Deploy with Railway CLI

#### Step 1: Install Railway CLI

```bash
# Windows (PowerShell)
iwr https://railway.app/install.ps1 | iex

# macOS/Linux
curl -fsSL https://railway.app/install.sh | sh

# Or with npm
npm install -g @railway/cli
```

#### Step 2: Login

```bash
railway login
```

#### Step 3: Initialize Project

```bash
# In your project directory
railway init
```

#### Step 4: Set Variables

```bash
railway variables set API_KEY=your-super-secure-key
railway variables set PORT=8080
railway variables set NODE_ENV=production
```

#### Step 5: Deploy

```bash
railway up
```

Done! Your app is live! 🚀

#### Step 6: Open Your App

```bash
railway open
```

---

## 📦 What Railway Does Automatically

1. ✅ **Detects Dockerfile** - Uses your optimized Docker image
2. ✅ **Builds in cloud** - No local Docker needed
3. ✅ **Generates HTTPS URL** - Secure by default
4. ✅ **Auto-redeploys** - On every GitHub push
5. ✅ **Provides metrics** - CPU, RAM, Network monitoring
6. ✅ **Creates volumes** - For persistent storage
7. ✅ **Health checks** - Automatic monitoring

---

## ⚙️ Configuration

### Railway.json (Already Created)

Your project includes `railway.json` for custom configuration:

```json
{
  "$schema": "https://railway.app/railway.schema.json",
  "build": {
    "builder": "DOCKERFILE",
    "dockerfilePath": "Dockerfile"
  },
  "deploy": {
    "numReplicas": 1,
    "restartPolicyType": "ON_FAILURE",
    "restartPolicyMaxRetries": 10
  }
}
```

### Environment Variables

Set these in Railway dashboard or CLI:

| Variable | Value | Required |
|----------|-------|----------|
| `API_KEY` | Your secret key | ✅ Yes |
| `PORT` | `8080` | Optional (auto-set) |
| `NODE_ENV` | `production` | Optional |
| `PYTHON_EXECUTABLE` | `/app/python/venv/bin/python` | Optional (default) |
| `MIN_CONFIDENCE` | `0.5` | Optional |

---

## 💾 Add Persistent Storage (Optional)

If you want to persist uploads/frames across deployments:

### In Railway Dashboard:

1. Go to your service
2. Click **Settings** → **Volumes**
3. Click **Add Volume**
4. Set mount path: `/app/data`
5. Set size: `10GB`

### Update Your Service:

Uploads and frames will now persist in `/app/data`

---

## 🔄 Auto-Deploy on Push

Railway automatically deploys on every push to your main branch!

```bash
# Make changes
git add .
git commit -m "Updated feature"
git push

# Railway automatically deploys! ✨
```

Watch the deployment in real-time in the Railway dashboard.

---

## 📊 Monitor Your App

### Railway Dashboard

Access at `railway.app/project/your-project`

**Metrics Available:**
- CPU usage
- Memory usage
- Network traffic
- Build logs
- Deploy logs
- Runtime logs

### CLI Monitoring

```bash
# View logs
railway logs

# View logs (follow)
railway logs -f

# Check status
railway status
```

---

## 💰 Pricing

Railway uses **usage-based pricing**:

### Free Trial
- **$5 free credits** to start
- **No credit card required**
- Great for testing!

### Paid Plans
**Starter ($5/month):**
- $5 free credits included
- Pay only for what you use
- ~$0.000463 per GB-hour of RAM
- ~$0.000231 per vCPU-hour

**Estimated Monthly Cost for This App:**
- **2GB RAM, 2 vCPU, 24/7 uptime**
- RAM: 2GB × 730 hours × $0.000463 = ~$6.76
- CPU: 2 vCPU × 730 hours × $0.000231 = ~$3.37
- **Total: ~$10-15/month**

Much better than Fly.io for ML apps! 💪

---

## 🎨 Custom Domain (Optional)

### Add Your Domain:

1. Go to **Settings** → **Domains**
2. Click **Custom Domain**
3. Enter your domain: `api.yourdomain.com`
4. Add CNAME record to your DNS:

```
CNAME  api  your-app.up.railway.app
```

5. Wait for DNS propagation (5-30 minutes)
6. SSL certificate auto-generated! 🔒

---

## 🐛 Troubleshooting

### Build Fails

**Check logs:**
```bash
railway logs --build
```

**Common issues:**
- Docker build timeout → Optimize Dockerfile
- Out of memory → Increase service resources

### App Won't Start

**Check runtime logs:**
```bash
railway logs
```

**Common issues:**
- Wrong PORT variable → Railway auto-sets it
- Missing API_KEY → Set in variables
- Python not found → Check Dockerfile

### Can't Access App

**Verify deployment:**
```bash
railway status
```

**Check:**
- Service is "Active"
- Health checks passing
- Domain is generated

---

## 🚀 Optimization Tips

### 1. Use Smaller Dockerfile

If image is still large, use the light version:

```bash
# Edit railway.json
{
  "build": {
    "builder": "DOCKERFILE",
    "dockerfilePath": "Dockerfile.light"  ← Use this
  }
}
```

### 2. Enable Build Cache

Railway caches Docker layers automatically. Use multi-stage builds (already done!).

### 3. Add Health Check

Railway uses your Docker HEALTHCHECK (already configured).

### 4. Scale Resources

In dashboard: **Settings** → **Resources**
- Adjust CPU (0.5-32 vCPU)
- Adjust RAM (0.5GB-32GB)

---

## 🔒 Security Best Practices

### 1. Use Strong API Key

```bash
# Generate secure key (example)
openssl rand -base64 32

# Set in Railway
railway variables set API_KEY=<generated-key>
```

### 2. Enable HTTPS Only

Railway does this automatically! ✅

### 3. Use Environment Variables

Never commit secrets to git:
```bash
# .gitignore already includes
.env
.env.local
```

### 4. Regular Updates

```bash
# Update dependencies
npm update
pip install --upgrade -r python/requirements.txt

# Commit and push
git push  # Auto-deploys!
```

---

## 📈 Scaling

### Horizontal Scaling (Multiple Instances)

Edit `railway.json`:
```json
{
  "deploy": {
    "numReplicas": 3  ← Run 3 instances
  }
}
```

### Vertical Scaling (More Resources)

In dashboard: **Settings** → **Resources**
- Increase RAM for video processing
- Increase CPU for faster AI detection

---

## 🔄 Rollback

### Via Dashboard:
1. Go to **Deployments**
2. Find previous successful deployment
3. Click **Redeploy**

### Via CLI:
```bash
railway rollback
```

---

## 📞 Support

- **Railway Docs:** https://docs.railway.app
- **Discord Community:** https://discord.gg/railway
- **Twitter:** [@Railway](https://twitter.com/Railway)
- **Status:** https://status.railway.app

---

## ✅ Deployment Checklist

- [ ] Code pushed to GitHub
- [ ] Railway account created
- [ ] Project deployed from GitHub
- [ ] Environment variables set (API_KEY)
- [ ] App is accessible via Railway URL
- [ ] Health checks passing
- [ ] Test video upload working
- [ ] Monitor logs for errors
- [ ] Optional: Custom domain added
- [ ] Optional: Volume for persistence

---

## 🎉 Success!

Your AI Backend is now live on Railway!

**Next Steps:**
1. Test all endpoints with your Railway URL
2. Update API_KEY in your clients
3. Monitor usage in Railway dashboard
4. Scale as needed

**Your app URL:** `https://your-app.up.railway.app`

**Test it:**
```bash
curl https://your-app.up.railway.app/api/test-key \
  -H "X-API-Key: your-api-key"
```

Welcome aboard! 🚂✨

---

## 🆚 Railway vs Fly.io

| Feature | Railway | Fly.io |
|---------|---------|--------|
| Image Size Limit | 20GB+ | 8GB |
| Setup Complexity | ⭐ Easy | ⭐⭐⭐ Moderate |
| Auto GitHub Deploy | ✅ Yes | ❌ Manual |
| Free Tier | $5 credits | Limited |
| Dashboard | ⭐⭐⭐ Beautiful | ⭐⭐ Functional |
| Best For | ML Apps, Large Images | Edge Computing |

**For this AI Backend: Railway is the better choice! ✅**

---

## 🚀 Quick Commands Reference

```bash
# Install CLI
npm install -g @railway/cli

# Login
railway login

# Initialize project
railway init

# Set variables
railway variables set KEY=value

# Deploy
railway up

# View logs
railway logs -f

# Open dashboard
railway open

# Check status
railway status

# Rollback
railway rollback
```

Happy deploying! 🎊

