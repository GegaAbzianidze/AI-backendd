# AI Backend - Clean Docker Configuration
FROM node:20-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    ffmpeg \
    python3 \
    python3-pip \
    python3-venv \
    libgl1-mesa-glx \
    libglib2.0-0 \
    libgomp1 \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# Copy package files and install Node.js dependencies
COPY package*.json ./
RUN npm ci --only=production && npm cache clean --force

# Install Python dependencies in virtual environment
COPY python/requirements.txt ./python/requirements.txt
RUN python3 -m venv /app/python/venv \
    && /app/python/venv/bin/pip install --no-cache-dir --upgrade pip setuptools wheel \
    && /app/python/venv/bin/pip install --no-cache-dir -r python/requirements.txt \
    && find /app/python/venv -type d -name __pycache__ -exec rm -rf {} + 2>/dev/null || true \
    && find /app/python/venv -type f -name "*.pyc" -delete \
    && find /app/python/venv -type f -name "*.pyo" -delete

# Copy application code
COPY tsconfig.json ./
COPY src ./src
COPY public ./public
COPY python ./python
COPY skin_list.txt ./
COPY models/my_model/train/weights/best.pt ./models/my_model/train/weights/best.pt
COPY models/my_model/train/args.yaml ./models/my_model/train/args.yaml

# Build TypeScript
RUN npm install typescript && npm run build && npm uninstall typescript

# Create necessary directories
RUN mkdir -p uploads frames jobs data

# Environment variables
ENV NODE_ENV=production \
    PORT=3000 \
    YOLO_MODEL_PATH=/app/models/my_model/train/weights/best.pt \
    PYTHON_EXECUTABLE=/app/python/venv/bin/python \
    API_KEY=change-me-in-production

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
  CMD node -e "require('http').get('http://localhost:3000/', (r) => {process.exit(r.statusCode === 200 ? 0 : 1)})"

EXPOSE 3000

# Run as non-root user for security
RUN addgroup --system --gid 1001 nodejs \
    && adduser --system --uid 1001 appuser \
    && chown -R appuser:nodejs /app

USER appuser

CMD ["node", "dist/index.js"]

