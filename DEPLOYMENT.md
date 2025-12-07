# 🚀 Hetzner Deployment Guide

Complete step-by-step guide to deploy AI Backend on Hetzner Cloud.

---

## 📋 Prerequisites

- Hetzner Cloud account
- SSH client (Terminal on Mac/Linux, PuTTY on Windows)
- Git installed locally
- Your YOLO model file (`best.pt`)

---

## 🖥️ Step 1: Create Hetzner Server

### 1.1 Create New Project
1. Log in to [Hetzner Cloud Console](https://console.hetzner.cloud/)
2. Click **"New Project"**
3. Name it: `ai-backend`

### 1.2 Create Server
1. Click **"Add Server"**
2. **Location**: Choose closest to your users (e.g., Nuremberg, Helsinki)
3. **Image**: Ubuntu 22.04 LTS
4. **Type**: 
   - **Recommended**: CPX31 (4 vCPU, 8 GB RAM) - €13.90/month
   - **Minimum**: CPX21 (3 vCPU, 4 GB RAM) - €8.90/month
   - **Budget**: CX21 (2 vCPU, 4 GB RAM) - €4.90/month (slower)
5. **SSH Key**: 
   - Add your SSH key or create password
   - For SSH key: Copy your public key from `~/.ssh/id_rsa.pub`
6. **Firewall**: Create new firewall:
   - Inbound Rules:
     - SSH: Port 22 (TCP)
     - HTTP: Port 80 (TCP)
     - HTTPS: Port 443 (TCP)
     - API: Port 3000 (TCP)
7. **Name**: `ai-backend-prod`
8. Click **"Create & Buy now"**

### 1.3 Get Server IP
- Copy the **IPv4 address** (e.g., `65.108.123.45`)

---

## 🔐 Step 2: Connect to Server

### Windows (PowerShell/CMD):
```bash
ssh root@YOUR_SERVER_IP
```

### Mac/Linux:
```bash
ssh root@YOUR_SERVER_IP
```

Accept the fingerprint by typing `yes`.

---

## ⚙️ Step 3: Initial Server Setup

### 3.1 Update System
```bash
apt update && apt upgrade -y
```

### 3.2 Install Docker
```bash
# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh

# Start Docker
systemctl start docker
systemctl enable docker

# Verify installation
docker --version
```

### 3.3 Install Docker Compose
```bash
# Install Docker Compose
apt install docker-compose-plugin -y

# Verify installation
docker compose version
```

### 3.4 Install Additional Tools
```bash
apt install -y git curl nano htop ufw
```

### 3.5 Configure Firewall (UFW)
```bash
# Enable firewall
ufw allow 22/tcp      # SSH
ufw allow 80/tcp      # HTTP
ufw allow 443/tcp     # HTTPS
ufw allow 3000/tcp    # API
ufw --force enable

# Check status
ufw status
```

---

## 📦 Step 4: Deploy Application

### 4.1 Clone Repository
```bash
# Create app directory
mkdir -p /opt/ai-backend
cd /opt/ai-backend

# Clone your repository
git clone YOUR_REPOSITORY_URL .

# Or upload files manually (see below)
```

### 4.2 If Not Using Git (Manual Upload)
From your **local machine**:
```bash
# Create archive (exclude unnecessary files)
tar -czf ai-backend.tar.gz \
  --exclude=node_modules \
  --exclude=dist \
  --exclude=python/venv \
  --exclude=uploads \
  --exclude=frames \
  --exclude=data \
  --exclude=jobs \
  .

# Upload to server
scp ai-backend.tar.gz root@YOUR_SERVER_IP:/opt/ai-backend/

# On server, extract
cd /opt/ai-backend
tar -xzf ai-backend.tar.gz
rm ai-backend.tar.gz
```

### 4.3 Upload YOLO Model
From your **local machine**:
```bash
# Upload your trained model
scp models/my_model/train/weights/best.pt \
  root@YOUR_SERVER_IP:/opt/ai-backend/models/my_model/train/weights/
```

### 4.4 Configure Environment
```bash
cd /opt/ai-backend

# Copy example env file
cp .env.example .env

# Edit environment variables
nano .env
```

**Set your values:**
```env
API_KEY=your-super-secret-random-key-12345
PORT=3000
NODE_ENV=production
MIN_CONFIDENCE=0.5
```

**Generate a secure API key:**
```bash
# Generate random API key
openssl rand -hex 32
```

Save and exit (Ctrl+X, Y, Enter).

### 4.5 Create Required Directories
```bash
mkdir -p uploads frames jobs data
touch uploads/.gitkeep frames/.gitkeep jobs/.gitkeep data/.gitkeep
```

---

## 🐳 Step 5: Build and Run with Docker

### 5.1 Build Docker Image
```bash
cd /opt/ai-backend
docker compose build
```

This will take 5-10 minutes (downloads dependencies, builds Python venv, etc.).

### 5.2 Start Application
```bash
docker compose up -d
```

### 5.3 Check Status
```bash
# View running containers
docker compose ps

# View logs
docker compose logs -f

# Check if server is responding
curl http://localhost:3000/api/status/health
```

You should see:
```json
{"success":true,"status":"healthy","timestamp":"...","uptime":...}
```

---

## 🌐 Step 6: Access Your Application

### 6.1 Test API
```bash
# From your local machine
curl http://YOUR_SERVER_IP:3000/api/status/health \
  -H "X-API-Key: YOUR_API_KEY"
```

### 6.2 Access Web Interface
Open in browser:
```
http://YOUR_SERVER_IP:3000
```

Enter your API key when prompted.

---

## 🔒 Step 7: Setup Domain & SSL (Optional but Recommended)

### 7.1 Point Domain to Server
In your domain registrar (Namecheap, GoDaddy, etc.):
- Create **A Record**: `api.yourdomain.com` → `YOUR_SERVER_IP`
- Wait 5-10 minutes for DNS propagation

### 7.2 Install Nginx
```bash
apt install -y nginx
```

### 7.3 Configure Nginx
```bash
nano /etc/nginx/sites-available/ai-backend
```

Paste this configuration:
```nginx
server {
    listen 80;
    server_name api.yourdomain.com;

    client_max_body_size 500M;

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
        proxy_read_timeout 600s;
        proxy_connect_timeout 600s;
        proxy_send_timeout 600s;
    }
}
```

Enable site:
```bash
ln -s /etc/nginx/sites-available/ai-backend /etc/nginx/sites-enabled/
nginx -t
systemctl restart nginx
```

### 7.4 Install SSL Certificate
```bash
# Install Certbot
apt install -y certbot python3-certbot-nginx

# Get SSL certificate
certbot --nginx -d api.yourdomain.com

# Follow prompts, choose to redirect HTTP to HTTPS
```

Now access via:
```
https://api.yourdomain.com
```

---

## 📊 Step 8: Monitoring & Management

### 8.1 View Logs
```bash
# All logs
docker compose logs -f

# Last 100 lines
docker compose logs --tail=100

# Specific service
docker compose logs -f ai-backend
```

### 8.2 Restart Application
```bash
docker compose restart
```

### 8.3 Stop Application
```bash
docker compose down
```

### 8.4 Update Application
```bash
cd /opt/ai-backend

# Pull latest code
git pull

# Rebuild and restart
docker compose down
docker compose build
docker compose up -d
```

### 8.5 Check Resource Usage
```bash
# CPU and Memory
htop

# Docker stats
docker stats

# Disk usage
df -h
du -sh /opt/ai-backend/*
```

### 8.6 Access Monitoring Dashboard
Open in browser:
```
http://YOUR_SERVER_IP:3000/status.html
```

---

## 🔧 Troubleshooting

### Application Won't Start
```bash
# Check logs
docker compose logs

# Check if port is in use
netstat -tulpn | grep 3000

# Restart Docker
systemctl restart docker
docker compose up -d
```

### Out of Memory
```bash
# Check memory
free -h

# Restart application
docker compose restart

# Consider upgrading server plan
```

### Can't Upload Large Videos
Edit `/etc/nginx/sites-available/ai-backend`:
```nginx
client_max_body_size 1G;  # Increase to 1GB
```

Restart Nginx:
```bash
systemctl restart nginx
```

### Python Process Issues
```bash
# Enter container
docker compose exec ai-backend bash

# Check Python
python --version

# Test detector manually
cd /app
python python/detector.py --help
```

### Database/Jobs Lost
Jobs are stored in `/opt/ai-backend/jobs/`. To backup:
```bash
# Backup
tar -czf backup-$(date +%Y%m%d).tar.gz jobs/ data/

# Restore
tar -xzf backup-20250107.tar.gz
```

---

## 💾 Backup Strategy

### Automated Daily Backup
```bash
# Create backup script
nano /opt/backup-ai-backend.sh
```

Paste:
```bash
#!/bin/bash
BACKUP_DIR="/opt/backups"
DATE=$(date +%Y%m%d-%H%M%S)

mkdir -p $BACKUP_DIR

cd /opt/ai-backend
tar -czf $BACKUP_DIR/ai-backend-$DATE.tar.gz \
  jobs/ data/ models/

# Keep only last 7 days
find $BACKUP_DIR -name "ai-backend-*.tar.gz" -mtime +7 -delete

echo "Backup completed: $BACKUP_DIR/ai-backend-$DATE.tar.gz"
```

Make executable:
```bash
chmod +x /opt/backup-ai-backend.sh
```

Add to crontab (daily at 2 AM):
```bash
crontab -e

# Add this line:
0 2 * * * /opt/backup-ai-backend.sh >> /var/log/ai-backend-backup.log 2>&1
```

---

## 🔐 Security Best Practices

### 1. Change Default SSH Port
```bash
nano /etc/ssh/sshd_config

# Change Port 22 to Port 2222
systemctl restart sshd

# Update firewall
ufw allow 2222/tcp
ufw delete allow 22/tcp
```

### 2. Disable Root Login
```bash
# Create new user
adduser deploy
usermod -aG sudo,docker deploy

# Copy SSH keys
mkdir -p /home/deploy/.ssh
cp ~/.ssh/authorized_keys /home/deploy/.ssh/
chown -R deploy:deploy /home/deploy/.ssh

# Disable root login
nano /etc/ssh/sshd_config
# Set: PermitRootLogin no
systemctl restart sshd
```

### 3. Setup Fail2Ban
```bash
apt install -y fail2ban

# Configure
systemctl enable fail2ban
systemctl start fail2ban
```

### 4. Regular Updates
```bash
# Weekly updates
apt update && apt upgrade -y
docker compose pull
docker compose up -d
```

---

## 📈 Performance Optimization

### 1. Increase Swap (if needed)
```bash
# Create 4GB swap
fallocate -l 4G /swapfile
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile

# Make permanent
echo '/swapfile none swap sw 0 0' >> /etc/fstab
```

### 2. Docker Cleanup
```bash
# Remove unused images
docker system prune -a

# Remove old logs
docker compose logs --tail=0 -f > /dev/null
```

---

## 🎉 You're Live!

Your AI Backend is now running on Hetzner! 🚀

**Access Points:**
- Dashboard: `http://YOUR_IP:3000`
- API Docs: `http://YOUR_IP:3000/docs.html`
- Monitoring: `http://YOUR_IP:3000/status.html`
- Health Check: `http://YOUR_IP:3000/api/status/health`

**Next Steps:**
1. Test uploading a video
2. Monitor system resources
3. Setup automated backups
4. Configure domain + SSL
5. Share API with your team!

---

## 📞 Support

If you encounter issues:
1. Check logs: `docker compose logs`
2. Check status page: `/status.html`
3. Verify environment variables in `.env`
4. Ensure model file exists: `models/my_model/train/weights/best.pt`
5. Check server resources: `htop`

---

## 💰 Cost Estimate

**Hetzner CPX31** (Recommended):
- Server: €13.90/month
- Backup: €2.78/month (optional)
- Traffic: Unlimited (20TB included)
- **Total: ~€17/month**

**Domain + SSL:**
- Domain: €10-15/year
- SSL: Free (Let's Encrypt)

**Total Annual Cost: ~€220/year**

---

Happy deploying! 🎊

