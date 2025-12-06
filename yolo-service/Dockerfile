# YOLO Service Dockerfile - Lightweight Python-only
FROM python:3.12-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    libgl1-mesa-glx \
    libglib2.0-0 \
    libgomp1 \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# Copy requirements
COPY requirements.txt .

# Install Python dependencies
RUN pip install --no-cache-dir --upgrade pip setuptools wheel \
    && pip install --no-cache-dir -r requirements.txt \
    && find /usr/local -type d -name __pycache__ -exec rm -rf {} + 2>/dev/null || true \
    && find /usr/local -type f -name "*.pyc" -delete \
    && find /usr/local -type f -name "*.pyo" -delete

# Copy service files
COPY yolo-service/main.py .

# Copy detector module and model from root context
COPY python/detector.py ./python/detector.py
COPY models/my_model/train/weights/best.pt ./models/my_model/train/weights/best.pt
COPY models/my_model/train/args.yaml ./models/my_model/train/args.yaml
COPY skin_list.txt ./skin_list.txt

# Create necessary directories
RUN mkdir -p frames uploads data

# Environment variables
ENV PORT=8000 \
    YOLO_MODEL_PATH=/app/models/my_model/train/weights/best.pt \
    PYTHONUNBUFFERED=1

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
  CMD python -c "import requests; requests.get('http://localhost:8000/health', timeout=5)" || exit 1

EXPOSE 8000

# Run as non-root user
RUN addgroup --system --gid 1001 pythonuser \
    && adduser --system --uid 1001 pythonuser \
    && chown -R pythonuser:pythonuser /app

USER pythonuser

CMD ["python", "-m", "uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]

