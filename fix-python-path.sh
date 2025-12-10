#!/bin/bash
# Quick fix script for Python path issue
# Run as: sudo bash fix-python-path.sh

APP_DIR="/opt/ai-backend"
APP_USER="ai-backend"

echo "Fixing Python executable path..."

# Verify Python exists
PYTHON_EXEC="${APP_DIR}/python/venv/bin/python"
if [ ! -f "$PYTHON_EXEC" ]; then
    echo "ERROR: Python executable not found at $PYTHON_EXEC"
    echo "Checking if venv exists..."
    if [ ! -d "${APP_DIR}/python/venv" ]; then
        echo "Creating Python virtual environment..."
        cd "$APP_DIR"
        python3 -m venv python/venv
        source python/venv/bin/activate
        pip install --upgrade pip setuptools wheel
        if [ -f "python/requirements.txt" ]; then
            pip install -r python/requirements.txt
        fi
        deactivate
    else
        echo "ERROR: venv directory exists but Python executable is missing"
        exit 1
    fi
fi

# Update .env file
if [ -f "${APP_DIR}/.env" ]; then
    # Check if PYTHON_EXECUTABLE is set correctly
    if ! grep -q "PYTHON_EXECUTABLE=${APP_DIR}/python/venv/bin/python" "${APP_DIR}/.env"; then
        echo "Updating .env file..."
        # Remove old PYTHON_EXECUTABLE line if exists
        sed -i '/^PYTHON_EXECUTABLE=/d' "${APP_DIR}/.env"
        # Add correct PYTHON_EXECUTABLE
        echo "PYTHON_EXECUTABLE=${APP_DIR}/python/venv/bin/python" >> "${APP_DIR}/.env"
        chown "$APP_USER:$APP_USER" "${APP_DIR}/.env"
        chmod 600 "${APP_DIR}/.env"
        echo "✓ Updated .env file"
    fi
else
    echo "ERROR: .env file not found at ${APP_DIR}/.env"
    exit 1
fi

# Update systemd service
SERVICE_FILE="/etc/systemd/system/ai-backend.service"
if [ -f "$SERVICE_FILE" ]; then
    # Check if PYTHON_EXECUTABLE is in Environment section
    if ! grep -q 'Environment="PYTHON_EXECUTABLE=' "$SERVICE_FILE"; then
        echo "Updating systemd service file..."
        # Add PYTHON_EXECUTABLE after other Environment lines
        sed -i '/Environment="EASYOCR_CACHE_DIR=/a Environment="PYTHON_EXECUTABLE='"${APP_DIR}"'/python/venv/bin/python"' "$SERVICE_FILE"
        systemctl daemon-reload
        echo "✓ Updated systemd service file"
    fi
else
    echo "ERROR: systemd service file not found"
    exit 1
fi

# Restart service
echo "Restarting service..."
systemctl restart ai-backend.service
sleep 2
systemctl status ai-backend.service --no-pager -l

echo ""
echo "✓ Fix complete!"
echo "Python executable: $PYTHON_EXEC"
echo "Check service status: systemctl status ai-backend.service"
echo "Check logs: journalctl -u ai-backend.service -f"

