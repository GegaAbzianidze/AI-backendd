import argparse
import json
import os
from typing import List, Optional, Tuple

import cv2
import numpy as np
from ultralytics import YOLO
import easyocr


NAME_CLASS_TOKENS = {'name', 'item', 'skin', 'weapon'}
OWNED_POSITIVE = {'owned', 'purchase complete'}
OWNED_NEGATIVE = {'unlock', 'locked', 'buy', 'purchase'}
EQUIPPED_POSITIVE = {'equipped'}
EQUIPPED_NEGATIVE = {'unequipped', 'equip now', 'equip!', 'equip'}


def parse_args():
    parser = argparse.ArgumentParser()
    parser.add_argument('--model', required=True, help='Path to YOLO model file')
    parser.add_argument('--frames-dir', required=True, help='Directory containing extracted frames')
    parser.add_argument('--output-json', required=True, help='Destination JSON file for detections')
    parser.add_argument('--confidence', type=float, default=0.5, help='Minimum confidence threshold')
    parser.add_argument('--total-frames', type=int, default=0, help='Total number of frames expected')
    parser.add_argument('--fps', type=float, default=7.0, help='Frames per second of the video')
    parser.add_argument('--preview-file', help='Path to write a live preview frame with items')
    return parser.parse_args()


def clamp(value: int, min_value: int, max_value: int) -> int:
    return max(min_value, min(max_value, value))


def crop_region(image: np.ndarray, bbox: Tuple[float, float, float, float], padding: float = 0.1) -> np.ndarray:
    height, width = image.shape[:2]
    x1, y1, x2, y2 = bbox
    box_width = x2 - x1
    box_height = y2 - y1
    pad_x = box_width * padding
    pad_y = box_height * padding

    left = clamp(int(x1 - pad_x), 0, width)
    right = clamp(int(x2 + pad_x), 0, width)
    top = clamp(int(y1 - pad_y), 0, height)
    bottom = clamp(int(y2 + pad_y), 0, height)

    if left >= right or top >= bottom:
        return np.zeros((0, 0, 3), dtype=np.uint8)

    return image[top:bottom, left:right]


def read_text(reader: easyocr.Reader, image: np.ndarray) -> str:
    if image.size == 0:
        return ''
    results = reader.readtext(image, detail=0)
    return ' '.join(results).strip()





def run_detection(model_path, frames_dir, output_json, min_conf, fps=7.0, preview_file=None):
    model = YOLO(model_path, task='detect')
    reader = easyocr.Reader(['en'], gpu=False)
    frame_files = sorted(
        [f for f in os.listdir(frames_dir) if f.lower().endswith(('.png', '.jpg', '.jpeg'))]
    )

    frames_to_process: List[dict] = []
    frames_with_items: List[dict] = []

    print('STAGE:ai', flush=True)

    import time
    start_time = time.time()

    for idx, filename in enumerate(frame_files):
        frame_path = os.path.join(frames_dir, filename)
        image = cv2.imread(frame_path)
        if image is None:
            print(f'PROGRESS:{idx + 1}', flush=True)
            continue

        results = model(image, verbose=False)
        if not results:
            print(f'PROGRESS:{idx + 1}', flush=True)
            continue

        boxes = results[0].boxes
        frame_boxes = []
        
        # Temporary storage for status detection in this frame
        detected_status = None # {'owned': str, 'equipped': bool}

        for box in boxes:
            conf = float(box.conf.item())
            if conf < min_conf:
                continue
            cls_id = int(box.cls.item())
            class_name = model.names.get(cls_id, str(cls_id))
            coords = [float(x) for x in box.xyxy.cpu().numpy().flatten().tolist()]
            
            frame_boxes.append(
                {
                    'className': class_name,
                    'confidence': conf,
                    'bbox': coords,
                }
            )
            print(f'DEBUG: Detected class "{class_name}" with confidence {conf:.2f}', flush=True)

            # Check for status classes
            lower_class = class_name.lower()
            if lower_class == 'ownd_equipped':
                detected_status = {'owned': 'owned', 'equipped': True}
            elif lower_class == 'ownd_unequipped':
                detected_status = {'owned': 'owned', 'equipped': False}

        # Filter: Only process frames that have a detected status AND a Name object
        name_boxes = [b for b in frame_boxes if (b.get('className') or '').lower() in NAME_CLASS_TOKENS]
        
        if detected_status and name_boxes:
            frames_to_process.append(
                {
                    'frameIndex': idx + 1,
                    'fileName': filename,
                    'status': detected_status,
                    'nameBoxes': name_boxes,
                    'allBoxes': frame_boxes # Keep all for debug/preview if needed
                }
            )
            
            # Generate preview with preliminary info
            if preview_file:
                preview_image = image.copy()
                preview_items = []
                for detection in frame_boxes:
                    class_name = (detection.get('className') or '').lower()
                    x1, y1, x2, y2 = map(int, detection['bbox'])
                    label = f"{detection.get('className', 'Unknown')} ({detection.get('confidence', 0):.2f})"
                    
                    # Color coding
                    if class_name in NAME_CLASS_TOKENS:
                        color = (0, 255, 0) 
                    elif class_name in {'ownd_equipped', 'ownd_unequipped'}:
                        color = (255, 0, 255)
                    else:
                        color = (0, 255, 255)

                    cv2.rectangle(preview_image, (x1, y1), (x2, y2), color, 2)
                    cv2.putText(preview_image, label, (x1, max(y1 - 10, 0)), cv2.FONT_HERSHEY_SIMPLEX, 0.5, (255, 0, 0), 1)
                    
                    if class_name in NAME_CLASS_TOKENS:
                         preview_items.append({
                            'name': '...', # Placeholder until OCR
                            'owned': detected_status['owned'],
                            'equipped': detected_status['equipped']
                        })

                cv2.imwrite(preview_file, preview_image)
                preview_payload = {
                    'frameIndex': idx + 1,
                    'items': preview_items,
                    'processingTime': time.time() - start_time,
                    'videoTime': idx / fps
                }
                print(f'PREVIEW:{json.dumps(preview_payload)}', flush=True)

        print(f'PROGRESS:{idx + 1}', flush=True)

    print('STAGE:ocr', flush=True)

    # OCR Stage
    # We only iterate over frames that passed the filter
    total_frames_to_process = len(frames_to_process)
    
    # We need to map back to original total frames for progress if we want it accurate relative to video, 
    # but here we just report progress based on the filtered list or maybe just finish?
    # The original code reported progress for every frame in the OCR loop. 
    # Since we skipped many frames, the progress bar might jump. That's acceptable for now.
    
    for i, frame_entry in enumerate(frames_to_process):
        frame_path = os.path.join(frames_dir, frame_entry['fileName'])
        image = cv2.imread(frame_path)
        if image is None:
            continue

        frame_items = []
        status = frame_entry['status']

        for detection in frame_entry['nameBoxes']:
            coords = tuple(detection['bbox'])
            name_region = crop_region(image, coords)
            name_text = read_text(reader, name_region)
            
            if name_text:
                frame_items.append(
                    {
                        'name': name_text,
                        'owned': status['owned'],
                        'equipped': status['equipped'],
                    }
                )

        if frame_items:
            frames_with_items.append(
                {
                    'frameIndex': frame_entry['frameIndex'],
                    'items': frame_items,
                }
            )
            
            # Update preview with OCR results
            if preview_file:
                preview_image = image.copy()
                for item, detection in zip(frame_items, frame_entry['nameBoxes']):
                    x1, y1, x2, y2 = map(int, detection['bbox'])
                    label = f"{item['name']} ({item['owned']}, {'Equipped' if item['equipped'] else 'Not Equipped'})"
                    cv2.rectangle(preview_image, (x1, y1), (x2, y2), (0, 255, 0), 2)
                    cv2.putText(preview_image, label, (x1, max(y1 - 10, 0)), cv2.FONT_HERSHEY_SIMPLEX, 0.5, (255, 0, 0), 1)
                
                cv2.imwrite(preview_file, preview_image)
                preview_payload = {
                    'frameIndex': frame_entry['frameIndex'],
                    'items': frame_items,
                    'processingTime': time.time() - start_time,
                    'videoTime': (frame_entry['frameIndex'] - 1) / fps
                }
                print(f'PREVIEW:{json.dumps(preview_payload)}', flush=True)

        # Report progress (mapped to the original frame index would be ideal, but just incrementing is fine for the backend listener)
        # The backend listens for "PROGRESS:N". We should probably output the actual frame index or just keep the stream alive.
        # Since we are skipping frames, we might want to output the frame index we just processed.
        print(f'PROGRESS:{frame_entry["frameIndex"]}', flush=True)

    with open(output_json, 'w', encoding='utf-8') as outfile:
        json.dump(frames_with_items, outfile)


def main():
    args = parse_args()
    run_detection(args.model, args.frames_dir, args.output_json, args.confidence, args.fps, args.preview_file)


if __name__ == '__main__':
    main()

