"""
YOLO Detection Service - FastAPI Microservice
Handles AI detection and OCR processing for video frames
"""
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import os
import sys
import json
from pathlib import Path
import logging

# Add parent directory to path to import detector
sys.path.append(str(Path(__file__).parent.parent))

app = FastAPI(
    title="YOLO Detection Service",
    description="AI-powered object detection and OCR service",
    version="1.0.0"
)

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


class DetectionRequest(BaseModel):
    frames_dir: str
    output_json: str
    total_frames: int
    preview_file: str
    model_path: str = "/app/models/my_model/train/weights/best.pt"
    confidence: float = 0.5


class DetectionResponse(BaseModel):
    success: bool
    detected_frames: int
    message: str = ""


@app.get("/")
async def root():
    """Health check endpoint"""
    return {
        "service": "YOLO Detection Service",
        "status": "operational",
        "version": "1.0.0"
    }


@app.get("/health")
async def health():
    """Detailed health check"""
    try:
        import torch
        import cv2
        from ultralytics import YOLO
        
        return {
            "status": "healthy",
            "torch_available": True,
            "cuda_available": torch.cuda.is_available(),
            "opencv_available": True,
            "yolo_available": True
        }
    except Exception as e:
        logger.error(f"Health check failed: {e}")
        return {
            "status": "unhealthy",
            "error": str(e)
        }


@app.post("/detect", response_model=DetectionResponse)
async def detect_objects(request: DetectionRequest):
    """
    Process video frames with YOLO detection and OCR
    
    Args:
        request: DetectionRequest with frames directory and output path
        
    Returns:
        DetectionResponse with detection results
    """
    try:
        logger.info(f"Processing frames from: {request.frames_dir}")
        
        # Import detector module
        try:
            from python.detector import process_frames
        except ImportError:
            # Try alternative import path
            import detector
            process_frames = detector.process_frames
        
        # Process frames
        results = process_frames(
            frames_dir=request.frames_dir,
            output_json=request.output_json,
            model_path=request.model_path,
            confidence=request.confidence,
            preview_file=request.preview_file,
            total_frames=request.total_frames
        )
        
        logger.info(f"Detection complete: {len(results)} frames processed")
        
        return DetectionResponse(
            success=True,
            detected_frames=len(results),
            message=f"Successfully processed {len(results)} frames"
        )
        
    except FileNotFoundError as e:
        logger.error(f"File not found: {e}")
        raise HTTPException(status_code=404, detail=str(e))
    except Exception as e:
        logger.error(f"Detection failed: {e}")
        raise HTTPException(status_code=500, detail=f"Detection failed: {str(e)}")


@app.post("/test-detect")
async def test_detect():
    """Test endpoint to verify YOLO is working"""
    try:
        from ultralytics import YOLO
        import tempfile
        import numpy as np
        import cv2
        
        # Create a dummy test image
        with tempfile.NamedTemporaryFile(suffix='.jpg', delete=False) as tmp:
            # Create a simple test image (black square)
            img = np.zeros((640, 640, 3), dtype=np.uint8)
            cv2.imwrite(tmp.name, img)
            
            # Load model and test
            model_path = os.getenv('YOLO_MODEL_PATH', '/app/models/my_model/train/weights/best.pt')
            if not os.path.exists(model_path):
                return {
                    "success": False,
                    "message": f"Model not found at {model_path}"
                }
            
            model = YOLO(model_path)
            results = model(tmp.name, conf=0.5, verbose=False)
            
            # Clean up
            os.unlink(tmp.name)
            
            return {
                "success": True,
                "message": "YOLO model loaded and tested successfully",
                "model_path": model_path
            }
            
    except Exception as e:
        logger.error(f"Test detection failed: {e}")
        return {
            "success": False,
            "message": f"Test failed: {str(e)}"
        }


if __name__ == "__main__":
    import uvicorn
    port = int(os.getenv("PORT", 8000))
    uvicorn.run(app, host="0.0.0.0", port=port)

