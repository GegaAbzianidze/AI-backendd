# Deployment Guide - Fly.io

This guide will help you deploy the AI Backend application to Fly.io.

## Prerequisites

1. **Install Fly.io CLI**
   ```bash
   # Windows (PowerShell)
   powershell -Command "iwr https://fly.io/install.ps1 -useb | iex"
   
   # macOS/Linux
   curl -L https://fly.io/install.sh | sh
   ```

2. **Create Fly.io Account**
   - Visit [fly.io/signup](https://fly.io/signup)
   - Or run: `fly auth signup`

3. **Login to Fly.io**
   ```bash
   fly auth login
   ```

---

## Initial Setup

### 1. Configure Your App Name

Edit `fly.toml` and change the app name:
```toml
app = "your-unique-app-name"
```

### 2. Launch the App

```bash
fly launch
```

This command will:
- Detect your Dockerfile
- Create the app on Fly.io
- Set up the configuration

**Important:** When prompted:
- ❌ Don't deploy yet (say "No")
- ✅ Create a PostgreSQL database? → No (we don't need it)
- ✅ Create a Redis database? → No (we don't need it)

### 3. Set Secrets

Set your API key as a secret (never commit secrets to git):
```bash
fly secrets set API_KEY=your-super-secure-api-key-here
```

### 4. Create Volume for Persistent Storage

Create a volume for uploads and frames:
```bash
fly volumes create app_data --size 10 --region iad
```

Note: Change `iad` to your preferred region. Available regions:
- `iad` - Ashburn, VA (US East)
- `lax` - Los Angeles, CA (US West)
- `lhr` - London, UK
- `fra` - Frankfurt, Germany
- `nrt` - Tokyo, Japan

### 5. Deploy

```bash
fly deploy
```

This will:
- Build the Docker image
- Push it to Fly.io
- Deploy your application

---

## Configuration Options

### Scaling

**Increase resources:**
```bash
fly scale vm shared-cpu-4x --memory 4096
```

**Scale to multiple instances:**
```bash
fly scale count 2
```

### Regions

**Add more regions:**
```bash
fly regions add lhr fra
```

**List available regions:**
```bash
fly regions list
```

### Environment Variables

**Set environment variables:**
```bash
fly secrets set VARIABLE_NAME=value
```

**Available variables:**
- `API_KEY` - Your API authentication key (required)
- `PORT` - Port to run on (default: 8080)
- `NODE_ENV` - Environment mode (default: production)
- `MIN_CONFIDENCE` - YOLO detection confidence threshold (default: 0.5)

---

## Post-Deployment

### 1. Check Status

```bash
fly status
```

### 2. View Logs

```bash
fly logs
```

### 3. Open Your App

```bash
fly open
```

This will open your app in the browser: `https://your-app-name.fly.dev`

### 4. SSH into Machine (for debugging)

```bash
fly ssh console
```

---

## Updating Your App

After making code changes:

```bash
# Rebuild and deploy
fly deploy

# Or force rebuild from scratch
fly deploy --no-cache
```

---

## Monitoring

### View Metrics

```bash
fly dashboard
```

### Check Health

```bash
fly checks list
```

### View App Info

```bash
fly info
```

---

## Storage & Data

### Volume Management

**List volumes:**
```bash
fly volumes list
```

**Extend volume size:**
```bash
fly volumes extend app_data --size 20
```

**Create snapshot:**
```bash
fly volumes snapshots create app_data
```

### Accessing Files

SSH into your app and access `/app/data`:
```bash
fly ssh console
ls /app/data
```

---

## Troubleshooting

### App Won't Start

1. Check logs:
   ```bash
   fly logs
   ```

2. Verify secrets are set:
   ```bash
   fly secrets list
   ```

3. Check app status:
   ```bash
   fly status
   ```

### Build Failures

1. Build locally first to test:
   ```bash
   docker build -t ai-backend .
   docker run -p 8080:8080 ai-backend
   ```

2. Force rebuild without cache:
   ```bash
   fly deploy --no-cache
   ```

### Memory Issues

Increase memory allocation:
```bash
fly scale memory 4096
```

### Connection Issues

1. Check if app is running:
   ```bash
   fly status
   ```

2. Verify health checks:
   ```bash
   fly checks list
   ```

3. Check firewall/networking:
   ```bash
   fly ips list
   ```

---

## Cost Optimization

### Free Tier Limits

Fly.io offers:
- Up to 3 shared-cpu-1x VMs (256MB RAM each)
- 160GB outbound data transfer
- 3GB persistent storage

### Current Configuration

This app uses:
- 1x `shared-cpu-2x` (2 CPUs, 2GB RAM) - ~$12/month
- 10GB volume - ~$1.50/month

**Total: ~$13.50/month**

### Reduce Costs

**Option 1: Use smaller VM**
```bash
fly scale vm shared-cpu-1x --memory 1024
```

**Option 2: Auto-stop when idle**
Edit `fly.toml`:
```toml
auto_stop_machines = "stop"
auto_start_machines = true
min_machines_running = 0
```

**Option 3: Smaller volume**
Start with 5GB instead of 10GB

---

## Production Checklist

Before going to production:

- [ ] Set a strong API_KEY secret
- [ ] Configure proper domain (optional)
- [ ] Set up monitoring/alerts
- [ ] Test video upload and processing
- [ ] Verify concurrent job processing (3 max)
- [ ] Check disk space usage
- [ ] Set up backup strategy for volumes
- [ ] Test error handling
- [ ] Monitor memory usage under load

---

## Custom Domain (Optional)

### 1. Add Certificate

```bash
fly certs create yourdomain.com
```

### 2. Get DNS Instructions

```bash
fly certs show yourdomain.com
```

### 3. Add DNS Records

Add the CNAME or A record to your domain's DNS settings.

### 4. Verify

```bash
fly certs check yourdomain.com
```

---

## Backup & Restore

### Create Backup

```bash
fly volumes snapshots create app_data
```

### List Snapshots

```bash
fly volumes snapshots list app_data
```

### Restore from Snapshot

1. Create new volume from snapshot:
   ```bash
   fly volumes create app_data_restored --snapshot-id <snapshot-id>
   ```

2. Update `fly.toml` to use new volume

3. Deploy:
   ```bash
   fly deploy
   ```

---

## Support & Resources

- **Fly.io Docs:** https://fly.io/docs
- **Fly.io Community:** https://community.fly.io
- **Status Page:** https://status.fly.io
- **Pricing:** https://fly.io/docs/about/pricing

---

## Quick Reference

```bash
# Deploy app
fly deploy

# View logs
fly logs

# Check status  
fly status

# Open app in browser
fly open

# Set secret
fly secrets set KEY=value

# Scale VM
fly scale vm shared-cpu-2x

# SSH into machine
fly ssh console

# Restart app
fly apps restart

# Destroy app (careful!)
fly apps destroy your-app-name
```

