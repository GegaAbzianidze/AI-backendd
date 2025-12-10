# Quick Update Guide

## Easy Update Process

### One-Command Update

```bash
sudo bash update.sh
```

This script automatically:
1. ✅ Backs up your `.env` file
2. ✅ Pulls latest changes from git
3. ✅ Updates Python dependencies (if requirements.txt changed)
4. ✅ Rebuilds TypeScript
5. ✅ Restarts the service
6. ✅ Preserves your configuration

### Manual Update (if needed)

If you prefer to update manually:

```bash
cd /opt/ai-backend

# 1. Pull latest changes
sudo git pull

# 2. Update Python dependencies (if needed)
source python/venv/bin/activate
pip install -r python/requirements.txt
deactivate

# 3. Rebuild TypeScript
sudo npm ci --production
sudo npm install typescript --no-save
sudo npm run build
sudo npm uninstall typescript

# 4. Restart service
sudo systemctl restart ai-backend.service

# 5. Check status
sudo systemctl status ai-backend.service
```

### What Gets Updated

- ✅ Source code (TypeScript files)
- ✅ Python dependencies (if requirements.txt changed)
- ✅ Node.js dependencies (if package.json changed)
- ✅ Configuration files (but `.env` is preserved)

### What Stays the Same

- ✅ Your `.env` file (with API keys, paths, etc.)
- ✅ Uploaded videos and frames
- ✅ Job data
- ✅ Systemd service configuration
- ✅ Nginx configuration

### Troubleshooting Updates

If update fails:z

```bash
# Check what went wrong
sudo journalctl -u ai-backend.service -n 50

# Restore from backup (if needed)
cd /opt/ai-backend
sudo cp .env.backup .env
sudo systemctl restart ai-backend.service
```

### Git Setup (if not already done)

If you haven't set up git yet:

```bash
cd /opt/ai-backend

# If you cloned from a repo, you're already set
git remote -v

# If you need to add a remote:
git remote add origin <your-repo-url>
git branch -M main
```

### Before First Update

Make sure your server has the latest code:

```bash
cd /opt/ai-backend

# If you haven't committed the deployment files yet:
git add .
git commit -m "Add deployment configuration"
git push
```

Then on your server:
```bash
sudo bash update.sh
```

