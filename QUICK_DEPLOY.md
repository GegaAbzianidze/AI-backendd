# ⚡ Quick Deploy Guide (5 Minutes)

Fast track deployment for Hetzner Cloud.

---

## 🎯 Prerequisites

- Hetzner account
- SSH access to your server
- Your `best.pt` model file

---

## 🚀 Deploy in 5 Steps

### 1️⃣ Create Hetzner Server

1. Go to [Hetzner Cloud Console](https://console.hetzner.cloud/)
2. Create project: `ai-backend`
3. Add Server:
   - **Image**: Ubuntu 22.04
   - **Type**: CPX31 (4 vCPU, 8GB RAM)
   - **Add SSH key** or create password
4. Copy server IP address

---

### 2️⃣ Connect to Server

```bash
ssh root@YOUR_SERVER_IP
```

---

### 3️⃣ Run Auto-Deploy Script

```bash
# Download and run deployment script
curl -fsSL https://raw.githubusercontent.com/YOUR_REPO/main/deploy.sh | bash

# Or manually upload files first, then run:
cd /opt/ai-backend
chmod +x deploy.sh
./deploy.sh
```

**Script will:**
- ✅ Install Docker & Docker Compose
- ✅ Configure firewall
- ✅ Setup directories
- ✅ Generate API key
- ✅ Start application

---

### 4️⃣ Upload Your Project Files

**Option A: Using Git**
```bash
cd /opt/ai-backend
git clone YOUR_REPO_URL .
```

**Option B: Manual Upload (from your computer)**
```bash
# Create archive
tar -czf ai-backend.tar.gz \
  --exclude=node_modules \
  --exclude=dist \
  --exclude=python/venv \
  .

# Upload
scp ai-backend.tar.gz root@YOUR_SERVER_IP:/opt/ai-backend/

# On server, extract
cd /opt/ai-backend
tar -xzf ai-backend.tar.gz
```

---

### 5️⃣ Upload Model & Start

```bash
# From your local machine - upload model
scp models/my_model/train/weights/best.pt \
  root@YOUR_SERVER_IP:/opt/ai-backend/models/my_model/train/weights/

# On server - start application
cd /opt/ai-backend
docker compose up -d
```

---

## ✅ Verify Deployment

```bash
# Check if running
docker compose ps

# Test health endpoint
curl http://localhost:3000/api/status/health
```

---

## 🌐 Access Your App

Open in browser:
```
http://YOUR_SERVER_IP:3000
```

Enter the API key shown during deployment.

---

## 📊 Useful Commands

```bash
# View logs
docker compose logs -f

# Restart
docker compose restart

# Stop
docker compose down

# Update and restart
docker compose down && docker compose up -d --build
```

---

## 🎉 Done!

Your AI Backend is live on Hetzner!

**Next Steps:**
- Visit dashboard: `http://YOUR_IP:3000`
- Read full guide: `DEPLOYMENT.md`
- Setup domain + SSL (optional)

---

## 💰 Costs

- **CPX31**: €13.90/month
- Includes 20TB traffic
- Pay-as-you-go billing

---

Need help? Check `DEPLOYMENT.md` for detailed instructions!

