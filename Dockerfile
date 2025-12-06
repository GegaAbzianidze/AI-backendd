# Stage 1: Builder
FROM node:20-slim AS builder

WORKDIR /app

# Install build dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 \
    && rm -rf /var/lib/apt/lists/*

# Copy package files
COPY package*.json ./

# Install Node.js dependencies
RUN npm ci --only=production && npm cache clean --force

# Copy TypeScript config and source
COPY tsconfig.json ./
COPY src ./src

# Build TypeScript
RUN npm install typescript && npm run build && npm prune --production

# Stage 2: Runtime
FROM node:20-slim

WORKDIR /app

# Install runtime dependencies only
RUN apt-get update && apt-get install -y --no-install-recommends \
    ffmpeg \
    python3 \
    python3-pip \
    python3-venv \
    libgl1-mesa-glx \
    libglib2.0-0 \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# Copy Node.js dependencies from builder
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/dist ./dist
COPY package*.json ./

# Install Python dependencies
COPY python/requirements.txt ./python/requirements.txt
RUN python3 -m venv /app/python/venv \
    && /app/python/venv/bin/pip install --no-cache-dir --upgrade pip setuptools wheel \
    && /app/python/venv/bin/pip install --no-cache-dir -r python/requirements.txt \
    && find /app/python/venv -type d -name __pycache__ -exec rm -rf {} + 2>/dev/null || true \
    && find /app/python/venv -type f -name "*.pyc" -delete \
    && find /app/python/venv -type f -name "*.pyo" -delete

# Copy application files
COPY public ./public
COPY python ./python
COPY skin_list.txt ./

# Copy ONLY the required model file (not training data)
COPY models/my_model/train/weights/best.pt ./models/my_model/train/weights/best.pt

# Create necessary directories
RUN mkdir -p uploads frames data

# Environment variables
ENV NODE_ENV=production \
    PORT=8080 \
    YOLO_MODEL_PATH=/app/models/my_model/train/weights/best.pt \
    PYTHON_EXECUTABLE=/app/python/venv/bin/python \
    API_KEY=change-me-in-production

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
  CMD node -e "require('http').get('http://localhost:8080/', (r) => {process.exit(r.statusCode === 200 ? 0 : 1)})"

EXPOSE 8080

# Run as non-root user
RUN addgroup --system --gid 1001 nodejs \
    && adduser --system --uid 1001 appuser \
    && chown -R appuser:nodejs /app

USER appuser

CMD ["node", "dist/index.js"]

