# Troubleshooting Guide

## YOLO Model File Errors

### Error: `_pickle.UnpicklingError: invalid load key, 'v'`

This error means the model file is corrupted or is a text file instead of a binary PyTorch model.

#### Diagnosis

Run the diagnostic script:
```bash
sudo bash check-model.sh
```

Or manually check:
```bash
# Check if file exists
ls -lh /opt/ai-backend/models/my_model/train/weights/best.pt

# Check file type
file /opt/ai-backend/models/my_model/train/weights/best.pt

# Check first few bytes (should be binary, not text)
head -c 50 /opt/ai-backend/models/my_model/train/weights/best.pt | cat -A
```

#### Solutions

**1. Verify the model file is correct:**
```bash
# The file should be a binary .pt file, not a text file
# Check file size (should be several MB, not a few KB)
ls -lh /opt/ai-backend/models/my_model/train/weights/best.pt

# If it's very small or shows as "text", it's wrong
```

**2. Re-upload the correct model file:**
```bash
# If you have the correct best.pt file, upload it:
# Option A: Using SCP from your local machine
scp models/my_model/train/weights/best.pt user@server:/opt/ai-backend/models/my_model/train/weights/

# Option B: Using SFTP
sftp user@server
put models/my_model/train/weights/best.pt /opt/ai-backend/models/my_model/train/weights/

# Then fix permissions
sudo chown -R ai-backend:ai-backend /opt/ai-backend/models
```

**3. Check if wrong file is being loaded:**
```bash
# List all files in the model directory
ls -la /opt/ai-backend/models/my_model/train/weights/

# Make sure best.pt is the actual model, not args.yaml or another file
```

**4. Verify model path in .env:**
```bash
# Check the path is correct
grep YOLO_MODEL_PATH /opt/ai-backend/.env

# Should show:
# YOLO_MODEL_PATH=/opt/ai-backend/models/my_model/train/weights/best.pt
```

## Let's Encrypt SSL Certificate Issues

### Problem: "Timeout during connect (likely firewall problem)"

This error means Let's Encrypt cannot reach your server on port 80 to verify domain ownership.

### Step-by-Step Fix:

#### 1. Verify DNS Configuration

Check if your domain points to your server's IP:

```bash
# Get your server's public IP
curl ifconfig.me

# Check what IP your domain resolves to
dig +short shuaman.publicvm.com

# They should match!
```

**If they don't match:**
- Update your DNS A record to point `shuaman.publicvm.com` to your server's IP
- Wait for DNS propagation (can take a few minutes to 48 hours)
- Verify with: `dig shuaman.publicvm.com`

#### 2. Check Firewall (UFW)

Ensure port 80 (HTTP) is open:

```bash
# Check firewall status
sudo ufw status

# If port 80 is not listed, allow it:
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp  # Also allow HTTPS for later

# Verify
sudo ufw status
```

#### 3. Verify Nginx is Running

```bash
# Check Nginx status
sudo systemctl status nginx

# If not running, start it:
sudo systemctl start nginx
sudo systemctl enable nginx
```

#### 4. Test HTTP Access

From your local machine (not the server), test:

```bash
# Should return HTTP 200, 301, or 302
curl -I http://shuaman.publicvm.com

# Or open in browser:
# http://shuaman.publicvm.com
```

If this fails, the domain is not accessible from the internet.

#### 5. Check Nginx Configuration

Verify Nginx is listening on port 80:

```bash
sudo netstat -tlnp | grep :80
# Should show nginx listening

# Or
sudo ss -tlnp | grep :80
```

#### 6. Check for Other Firewalls

Some cloud providers have additional firewalls:

- **AWS**: Check Security Groups
- **DigitalOcean**: Check Firewalls in Networking
- **Linode**: Check Firewalls
- **Azure**: Check Network Security Groups

Ensure port 80 (HTTP) is open in these firewalls too.

#### 7. Retry Certificate Request

Once DNS and firewall are configured:

```bash
# Test first (dry run)
sudo certbot --nginx -d shuaman.publicvm.com --dry-run

# If test passes, get real certificate
sudo certbot --nginx -d shuaman.publicvm.com

# Auto-renewal should already be set up, but verify:
sudo systemctl status certbot.timer
```

### Common Issues

#### Issue: "Domain does not point to this server"

**Solution:** Update DNS A record. The domain must resolve to your server's IP address.

#### Issue: "Connection refused" or "Timeout"

**Solution:** 
1. Check UFW: `sudo ufw allow 80/tcp`
2. Check cloud provider firewall
3. Verify Nginx is running: `sudo systemctl status nginx`

#### Issue: "Nginx configuration test failed"

**Solution:**
```bash
# Test Nginx config
sudo nginx -t

# If errors, check the config file
sudo nano /etc/nginx/sites-available/ai-backend

# Fix any errors, then:
sudo nginx -t
sudo systemctl reload nginx
```

#### Issue: Certificate obtained but site still shows HTTP

**Solution:**
```bash
# Check if Nginx config was updated
sudo cat /etc/nginx/sites-available/ai-backend

# Should have SSL configuration. If not, certbot might have failed.
# Manually configure or re-run certbot:
sudo certbot --nginx -d shuaman.publicvm.com --redirect
```

## Python Path Errors

### Error: "spawn /app/python/venv/bin/python ENOENT"

This means the Python executable path is wrong.

**Solution:**
```bash
# Verify Python exists
ls -la /opt/ai-backend/python/venv/bin/python

# Update .env file
sudo nano /opt/ai-backend/.env
# Ensure it has: PYTHON_EXECUTABLE=/opt/ai-backend/python/venv/bin/python

# Update systemd service
sudo nano /etc/systemd/system/ai-backend.service
# Add: Environment="PYTHON_EXECUTABLE=/opt/ai-backend/python/venv/bin/python"

# Restart
sudo systemctl daemon-reload
sudo systemctl restart ai-backend.service
```

## Quick Diagnostic Commands

Run these to diagnose issues:

```bash
# 1. Check server IP
echo "Server IP: $(curl -s ifconfig.me)"

# 2. Check domain IP
echo "Domain IP: $(dig +short shuaman.publicvm.com)"

# 3. Check firewall
sudo ufw status verbose

# 4. Check Nginx
sudo systemctl status nginx
sudo nginx -t

# 5. Check if port 80 is listening
sudo ss -tlnp | grep :80

# 6. Test HTTP from server itself
curl -I http://localhost
curl -I http://shuaman.publicvm.com

# 7. Check certbot logs
sudo tail -50 /var/log/letsencrypt/letsencrypt.log

# 8. Check model file
sudo bash check-model.sh

# 9. Check application logs
sudo journalctl -u ai-backend.service -n 50
```

## Getting Help

If issues persist:

1. Check all logs:
   - Application: `sudo journalctl -u ai-backend.service -n 100`
   - Nginx: `sudo tail -100 /var/log/nginx/ai-backend-error.log`
   - Certbot: `sudo tail -100 /var/log/letsencrypt/letsencrypt.log`

2. Verify configuration:
   - DNS: `dig shuaman.publicvm.com`
   - Firewall: `sudo ufw status verbose`
   - Services: `sudo systemctl status ai-backend.service nginx`

3. Test connectivity:
   - From server: `curl -I http://localhost:3000`
   - From internet: `curl -I http://shuaman.publicvm.com`
