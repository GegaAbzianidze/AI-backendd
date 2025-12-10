#!/bin/bash
# Diagnostic script to check YOLO model file
# Run as: sudo bash check-model.sh

MODEL_PATH="${YOLO_MODEL_PATH:-/opt/ai-backend/models/my_model/train/weights/best.pt}"

echo "Checking YOLO model file..."
echo "Path: $MODEL_PATH"
echo ""

# Check if file exists
if [ ! -f "$MODEL_PATH" ]; then
    echo "❌ ERROR: Model file does not exist!"
    echo ""
    echo "Looking for model files in /opt/ai-backend/models/..."
    find /opt/ai-backend/models -name "*.pt" -type f 2>/dev/null || echo "No .pt files found"
    exit 1
fi

# Check file size
FILE_SIZE=$(stat -f%z "$MODEL_PATH" 2>/dev/null || stat -c%s "$MODEL_PATH" 2>/dev/null)
echo "File size: $FILE_SIZE bytes ($(numfmt --to=iec-i --suffix=B $FILE_SIZE 2>/dev/null || echo "N/A"))"

if [ "$FILE_SIZE" -lt 1024 ]; then
    echo "⚠️  WARNING: File is very small (< 1KB), might be corrupted"
fi

# Check file type
echo ""
echo "File type:"
file "$MODEL_PATH" 2>/dev/null || echo "Could not determine file type"

# Check first few bytes
echo ""
echo "First 20 bytes (hex):"
head -c 20 "$MODEL_PATH" | xxd -p -c 20 2>/dev/null || od -An -tx1 -N 20 "$MODEL_PATH" 2>/dev/null || echo "Could not read file"

echo ""
echo "First 50 characters (as text):"
head -c 50 "$MODEL_PATH" | cat -A
echo ""

# Try to validate with Python
echo "Attempting to validate with Python..."
python3 <<EOF
import os
import sys

model_path = "$MODEL_PATH"

if not os.path.exists(model_path):
    print("❌ File does not exist")
    sys.exit(1)

file_size = os.path.getsize(model_path)
print(f"✓ File exists: {model_path}")
print(f"✓ File size: {file_size} bytes")

# Check if it's a .pt file
if not model_path.endswith('.pt'):
    print("⚠️  Warning: File does not have .pt extension")

# Try to read first bytes
try:
    with open(model_path, 'rb') as f:
        header = f.read(20)
        print(f"✓ First 20 bytes: {header[:20]}")
        
        # Check if it looks like a text file
        if header.startswith(b'v') or header.startswith(b'#') or header.startswith(b'version'):
            print("❌ ERROR: File appears to be a text file, not a PyTorch model!")
            print("   This might be args.yaml or another config file")
            sys.exit(1)
        
        # PyTorch files typically have specific magic bytes
        if len(header) >= 4:
            print(f"✓ File header looks binary (not plain text)")
except Exception as e:
    print(f"❌ Error reading file: {e}")
    sys.exit(1)

# Try to load with torch (if available)
try:
    import torch
    print("\nAttempting to load with PyTorch...")
    checkpoint = torch.load(model_path, map_location='cpu')
    print("✓ File can be loaded with PyTorch!")
    if isinstance(checkpoint, dict):
        print(f"✓ Checkpoint keys: {list(checkpoint.keys())[:5]}...")
    else:
        print("✓ Checkpoint loaded (not a dict)")
except ImportError:
    print("⚠️  PyTorch not available, skipping validation")
except Exception as e:
    print(f"❌ ERROR: Cannot load with PyTorch: {e}")
    print("   File might be corrupted or not a valid PyTorch model")
    sys.exit(1)

print("\n✅ Model file appears to be valid!")
EOF

echo ""
echo "If the model file is invalid, you may need to:"
echo "1. Re-upload the correct best.pt file"
echo "2. Check if the file was corrupted during transfer"
echo "3. Verify the model path in .env: YOLO_MODEL_PATH"

