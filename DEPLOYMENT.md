# Deployment Guide

This document provides instructions for deploying the AI Backend application to an Ubuntu server.

## Quick Start

### Prerequisites
- Fresh Ubuntu 22.04 server
- Root or sudo access
- Domain name (optional, for HTTPS)

### One-Command Deployment

1. Clone the repository to your server:
```bash
git clone <your-repo-url> /opt/ai-backend
cd /opt/ai-backend
```

2. Run the build script:
```bash
sudo bash build.sh
```

### Updating the Application

After initial deployment, to update to the latest code, simply run the same script:

```bash
sudo bash build.sh
```

The `build.sh` script automatically detects if it's an update and:
- Preserves your `.env` file and configuration
- Pulls latest changes from git
- Handles Git LFS model files
- Updates Python dependencies if needed
- Rebuilds TypeScript
- Updates paths in .env file
- Restarts the service

The script will:
- Install all system dependencies
- Set up Python virtual environment
- Build and configure Node.js backend
- Create systemd service
- Configure Nginx reverse proxy
- Set up firewall (UFW)
- Optionally configure HTTPS with Let's Encrypt

### Manual Configuration

If you prefer manual setup or need to customize:

#### 1. Environment Variables

Copy `.env.example` to `.env` and configure:

```bash
cp .env.example .env
nano .env
```

**Required variables:**
- `API_KEY`: Generate with `openssl rand -hex 32`
- `PORT`: Backend port (default: 3000)
- `NODE_ENV`: Set to `production`

**Important:** Never commit `.env` to version control!

#### 2. Systemd Service

The service file is located at `systemd/ai-backend.service`. To install:

```bash
sudo cp systemd/ai-backend.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable ai-backend.service
sudo systemctl start ai-backend.service
```

#### 3. Nginx Configuration

The Nginx config is at `nginx/ai-backend.conf`. To install:

```bash
sudo cp nginx/ai-backend.conf /etc/nginx/sites-available/ai-backend
sudo ln -s /etc/nginx/sites-available/ai-backend /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx
```

**Important:** Edit the config file and replace `mydomain.com` with your actual domain.

#### 4. HTTPS Setup (Let's Encrypt)

```bash
sudo certbot --nginx -d yourdomain.com
```

This will automatically:
- Obtain SSL certificate
- Configure Nginx for HTTPS
- Set up auto-renewal

## Docker Deployment

### Using Docker Compose

1. Copy `.env.example` to `.env` and configure:
```bash
cp .env.example .env
# Edit .env with your settings
```

2. Build and start:
```bash
docker-compose up -d
```

### Dockerfile Details

The Dockerfile:
- Uses multi-stage build for smaller image size
- Sets proper HOME and cache directories
- Runs as non-root user
- Includes all Python dependencies for YOLO + EasyOCR

## Directory Structure

```
/opt/ai-backend/          # Application root
├── .env                  # Environment variables (not in git)
├── dist/                 # Compiled TypeScript
├── src/                  # TypeScript source
├── python/               # Python detection service
│   ├── venv/            # Python virtual environment
│   └── detector.py       # Detection script
├── uploads/             # Uploaded videos
├── frames/              # Extracted frames
├── jobs/                # Job metadata and results
├── models/              # YOLO model files
└── .config/             # Python cache directories
    ├── matplotlib/
    └── .cache/
    └── .EasyOCR/
```

## Service Management

### Check Status
```bash
sudo systemctl status ai-backend.service
```

### View Logs
```bash
# Application logs
sudo journalctl -u ai-backend.service -f

# Nginx access logs
sudo tail -f /var/log/nginx/ai-backend-access.log

# Nginx error logs
sudo tail -f /var/log/nginx/ai-backend-error.log
```

### Restart Service
```bash
sudo systemctl restart ai-backend.service
```

## Security Checklist

- [ ] Changed default `API_KEY` in `.env`
- [ ] Firewall (UFW) is enabled and configured
- [ ] Nginx is configured with proper server_name
- [ ] HTTPS is enabled (if using domain)
- [ ] Service runs as non-root user
- [ ] `.env` file has restricted permissions (600)
- [ ] No secrets are committed to git

## Troubleshooting

### Python Process Fails
- Check Python virtual environment: `python/venv/bin/python --version`
- Verify cache directories exist and are writable
- Check environment variables: `env | grep -E 'HOME|CACHE|EASYOCR'`

### Node.js Service Won't Start
- Check logs: `journalctl -u ai-backend.service -n 50`
- Verify `.env` file exists and is readable
- Check TypeScript build: `npm run build`

### Nginx 502 Bad Gateway
- Verify backend is running: `curl http://localhost:3000/api/status/health`
- Check Nginx error logs
- Verify firewall allows localhost connections

### Permission Errors
- Ensure app user owns all directories: `sudo chown -R ai-backend:ai-backend /opt/ai-backend`
- Check cache directory permissions: `ls -la /opt/ai-backend/.config`

## Environment Variables Reference

See `.env.example` for complete list. Key variables:

| Variable | Description | Default |
|----------|-------------|---------|
| `API_KEY` | API authentication key | `change-me-in-production` |
| `PORT` | Backend port | `3000` |
| `NODE_ENV` | Node environment | `production` |
| `MIN_CONFIDENCE` | YOLO detection threshold | `0.5` |
| `HOME` | Home directory for Python libs | `/app` or `/opt/ai-backend` |
| `MPLCONFIGDIR` | Matplotlib config directory | `$HOME/.config/matplotlib` |
| `EASYOCR_CACHE_DIR` | EasyOCR cache directory | `$HOME/.EasyOCR` |

## Support

For issues or questions:
1. Check logs first
2. Review this deployment guide
3. Check GitHub issues (if applicable)

