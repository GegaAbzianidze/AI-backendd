# ✅ Hetzner Deployment Checklist

Use this checklist to ensure smooth deployment.

---

## 📋 Pre-Deployment

### Local Setup
- [ ] All code committed to Git
- [ ] `.env.example` file present
- [ ] `best.pt` model file exists
- [ ] `docker-compose.yml` configured
- [ ] Build succeeds: `npm run build`
- [ ] Docker builds locally: `docker compose build`

### Hetzner Account
- [ ] Hetzner Cloud account created
- [ ] Payment method added
- [ ] SSH key generated (or password ready)

---

## 🖥️ Server Creation

- [ ] Create new project in Hetzner Console
- [ ] Create server:
  - [ ] Ubuntu 22.04 selected
  - [ ] CPX31 or higher selected (4 vCPU, 8GB RAM)
  - [ ] SSH key added
  - [ ] Firewall configured (ports 22, 80, 443, 3000)
- [ ] Server IP address copied
- [ ] Can SSH into server: `ssh root@YOUR_IP`

---

## ⚙️ Server Setup

- [ ] System updated: `apt update && apt upgrade -y`
- [ ] Docker installed
- [ ] Docker Compose installed
- [ ] Firewall (UFW) configured
- [ ] Application directory created: `/opt/ai-backend`

---

## 📦 Application Deployment

- [ ] Files uploaded to server (Git clone or SCP)
- [ ] Model file uploaded: `best.pt`
- [ ] `.env` file created with secure API key
- [ ] Required directories created: `uploads/`, `frames/`, `jobs/`, `data/`
- [ ] Docker image built: `docker compose build`
- [ ] Application started: `docker compose up -d`

---

## ✅ Verification

- [ ] Container running: `docker compose ps`
- [ ] No errors in logs: `docker compose logs`
- [ ] Health check passes: `curl http://localhost:3000/api/status/health`
- [ ] Dashboard accessible: `http://YOUR_IP:3000`
- [ ] Can upload test video
- [ ] Job processes successfully
- [ ] Can view results
- [ ] Status page shows metrics: `/status.html`
- [ ] Docs page loads: `/docs.html`

---

## 🔒 Security (Optional but Recommended)

- [ ] Changed SSH port from 22
- [ ] Disabled root login
- [ ] Created non-root user
- [ ] Fail2Ban installed
- [ ] API key is strong (32+ characters)
- [ ] `.env` file has restricted permissions: `chmod 600 .env`

---

## 🌐 Domain Setup (Optional)

- [ ] Domain pointed to server IP
- [ ] Nginx installed
- [ ] Nginx configured as reverse proxy
- [ ] SSL certificate installed (Certbot)
- [ ] HTTPS working
- [ ] HTTP redirects to HTTPS

---

## 💾 Backup Setup (Optional)

- [ ] Backup script created
- [ ] Cron job configured
- [ ] Test backup runs successfully
- [ ] Backup restoration tested

---

## 📊 Post-Deployment

- [ ] Monitor system resources: `htop`
- [ ] Check disk space: `df -h`
- [ ] Test with real videos
- [ ] Test queue system (upload 4+ videos)
- [ ] Test job termination
- [ ] Test job deletion
- [ ] Monitor logs for errors
- [ ] Save API key securely
- [ ] Share API documentation with team

---

## 🎉 Success Criteria

Your deployment is successful when:

✅ Dashboard loads at `http://YOUR_IP:3000`
✅ Can upload and process videos
✅ Queue system works (max 3 concurrent)
✅ Jobs persist after server restart
✅ Status page shows system metrics
✅ Logs appear in monitoring dashboard
✅ Can terminate and delete jobs
✅ No errors in Docker logs

---

## 📞 Need Help?

**Check logs:**
```bash
docker compose logs -f
```

**Restart application:**
```bash
docker compose restart
```

**Full rebuild:**
```bash
docker compose down
docker compose build --no-cache
docker compose up -d
```

**Check system resources:**
```bash
htop           # CPU/Memory
df -h          # Disk space
docker stats   # Container resources
```

---

## 🎊 You're Live!

Once all checkboxes are ✅, your AI Backend is production-ready on Hetzner!

**Share with your team:**
- Dashboard: `http://YOUR_IP:3000`
- API Docs: `http://YOUR_IP:3000/docs.html`
- API Key: (from your `.env` file)

Happy deploying! 🚀

