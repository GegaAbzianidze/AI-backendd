# Troubleshooting Guide

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
```

## Manual HTTPS Setup (After DNS is Fixed)

If you've fixed DNS and firewall, but the deployment script already failed:

```bash
# 1. Ensure HTTP works first
curl -I http://shuaman.publicvm.com

# 2. Run certbot manually
sudo certbot --nginx -d shuaman.publicvm.com

# 3. Follow prompts (or use non-interactive):
sudo certbot --nginx \
    --non-interactive \
    --agree-tos \
    --email your@email.com \
    -d shuaman.publicvm.com \
    --redirect

# 4. Verify certificate
sudo certbot certificates

# 5. Test auto-renewal
sudo certbot renew --dry-run
```

## Other Common Issues

### Application Not Starting

```bash
# Check service status
sudo systemctl status ai-backend.service

# View logs
sudo journalctl -u ai-backend.service -f

# Check if port is in use
sudo netstat -tlnp | grep 3000
```

### Python Detection Service Fails

```bash
# Check Python environment
/opt/ai-backend/python/venv/bin/python --version

# Check cache directories
ls -la /opt/ai-backend/.config
ls -la /opt/ai-backend/.cache
ls -la /opt/ai-backend/.EasyOCR

# Check permissions
sudo chown -R ai-backend:ai-backend /opt/ai-backend/.config /opt/ai-backend/.cache /opt/ai-backend/.EasyOCR
```

### Nginx 502 Bad Gateway

```bash
# Check if backend is running
curl http://localhost:3000/api/status/health

# If not, check backend logs
sudo journalctl -u ai-backend.service -n 50

# Check Nginx error logs
sudo tail -50 /var/log/nginx/ai-backend-error.log
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

