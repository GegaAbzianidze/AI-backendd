# Fix: Docker Image Too Large for Fly.io

## Problem
Fly.io error: "Not enough space to unpack image, possibly exceeds maximum of 8GB uncompressed"

## Solutions (Choose One)

---

## ✅ Solution 1: Use Optimized Dockerfile (Recommended)

The updated `Dockerfile` now uses multi-stage builds and excludes training data.

### Deploy with optimized Dockerfile:
```bash
fly deploy
```

**This should reduce image size to ~4-5GB**

---

## ✅ Solution 2: Use Ultra-Light Dockerfile (Smallest)

Use CPU-only PyTorch version (60% smaller):

```bash
# Build with light version
fly deploy --dockerfile Dockerfile.light
```

**This reduces image size to ~2-3GB**

---

## ✅ Solution 3: Increase Fly.io VM Size

If your image is still too large, use a larger VM temporarily:

### Update `fly.toml`:
```toml
[[vm]]
  size = 'performance-2x'  # or 'performance-4x'
  memory = '4gb'
  cpus = 2
```

### Then deploy:
```bash
fly deploy
```

---

## ✅ Solution 4: Exclude Model Files (Use Remote Storage)

If models are very large, store them separately:

### Option A: Use Fly.io Volumes
Store model on persistent volume instead of image.

### Option B: Use S3/R2
Download model at runtime from cloud storage.

---

## 🔧 Quick Fixes to Try Now

### 1. Clean Local Docker Cache
```bash
docker system prune -a --volumes
```

### 2. Build Locally to Check Size
```bash
docker build -t ai-backend .
docker images ai-backend

# Check size - should be under 3GB compressed
```

### 3. Deploy with Light Dockerfile
```bash
fly deploy --dockerfile Dockerfile.light
```

---

## 📊 Image Size Comparison

| Version | Uncompressed | Compressed | Deploy Time |
|---------|--------------|------------|-------------|
| Original | ~8-10GB | ~3-4GB | ❌ Too large |
| Optimized | ~4-5GB | ~1.5-2GB | ✅ Works |
| Ultra-light | ~2-3GB | ~800MB-1GB | ✅ Fast |

---

## 🎯 What Was Optimized

### In Updated Dockerfile:
1. ✅ Multi-stage build (separates build/runtime)
2. ✅ Only copy `best.pt` model file (not training data)
3. ✅ Clean Python cache files (`__pycache__`, `*.pyc`)
4. ✅ Remove pip/setuptools after install
5. ✅ Aggressive apt cleanup

### In Dockerfile.light:
1. ✅ CPU-only PyTorch (60% smaller)
2. ✅ Separate Python build stage
3. ✅ Minimal runtime dependencies
4. ✅ Only essential files copied

---

## 🚀 Recommended Deployment Steps

### Step 1: Clean Everything
```bash
docker system prune -a
fly deploy --no-cache
```

### Step 2: If Still Too Large, Use Light Version
```bash
fly deploy --dockerfile Dockerfile.light
```

### Step 3: Monitor Deployment
```bash
fly logs
```

---

## 📦 What's Excluded Now

The following are now excluded from the image:

### Training Data (Excluded):
- ❌ `models/my_model/train/*.jpg` - Training images
- ❌ `models/my_model/train/*.png` - Graphs/charts
- ❌ `models/my_model/train/*.csv` - Training logs
- ❌ `models/my_model/train/weights/last.pt` - Backup weights
- ❌ `models/my_model/vea.mp4` - Test video

### Only Included:
- ✅ `models/my_model/train/weights/best.pt` - Trained model (required)
- ✅ `models/my_model/train/args.yaml` - Config (if needed)

---

## 🔍 Verify Image Size Locally

```bash
# Build
docker build -t ai-backend .

# Check size
docker images ai-backend

# Should show something like:
# REPOSITORY    TAG       SIZE
# ai-backend    latest    2.5GB    ✅ Good!
# ai-backend    latest    8.5GB    ❌ Too large!

# If too large, use light version:
docker build -f Dockerfile.light -t ai-backend .
```

---

## ⚡ Ultra-Fast Deploy (CPU-Only)

If you don't need GPU and want fastest deploy:

```bash
fly deploy --dockerfile Dockerfile.light --no-cache
```

This uses:
- CPU-only PyTorch
- Minimal Python packages
- Smallest base image
- **Deploy time: ~2-3 minutes**

---

## 🐛 Troubleshooting

### "Still too large after optimization"

Try this aggressive cleanup:

```bash
# Add to Dockerfile before final stage
RUN apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /tmp/* && \
    rm -rf /root/.cache
```

### "CPU-only PyTorch not working"

Make sure you're using the light Dockerfile:
```bash
fly deploy --dockerfile Dockerfile.light
```

### "Model file not found"

Verify the model exists:
```bash
ls -lh models/my_model/train/weights/best.pt
```

---

## 💡 Best Practices

1. **Always use multi-stage builds** for ML apps
2. **Exclude training data** from production images
3. **Use CPU-only PyTorch** unless you need GPU
4. **Clean caches** aggressively
5. **Test locally** before deploying

---

## 📞 Need Help?

1. Check image size locally first
2. Try the light Dockerfile
3. Use `fly logs` to see deployment errors
4. Join Fly.io community forum

---

## ✅ Success Checklist

- [ ] Updated `.dockerignore` (excludes training data)
- [ ] Using multi-stage Dockerfile
- [ ] Built and tested locally
- [ ] Image size under 4GB
- [ ] Deployed to Fly.io successfully
- [ ] App health check passing
- [ ] API endpoints working

---

## 🎉 Final Command

```bash
# Clean, build, and deploy in one go
docker system prune -a -f && fly deploy --no-cache
```

Good luck! 🚀

