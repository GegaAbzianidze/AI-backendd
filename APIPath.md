# API Documentation

## Base URL
- Local: `http://localhost:3000`
- Production: `https://your-app.fly.dev`

## Authentication
All API endpoints (except static files and root) require API key authentication.

**Header Required:**
```
X-API-Key: your-api-key-here
```

**Default API Key:** `change-me-in-production`

---

## Endpoints

### 📁 Static & Web Pages

#### `GET /`
**Description:** Main dashboard landing page  
**Authentication:** None  
**Response:** HTML page showing all jobs

#### `GET /job-detail.html?jobId={jobId}`
**Description:** Individual job detail page  
**Authentication:** None  
**Query Parameters:**
- `jobId` (required) - UUID of the job to view  
**Response:** HTML page with job details and live monitoring

#### `GET /frames/{videoId}/{filename}`
**Description:** Access processed frame images  
**Authentication:** None  
**Response:** Image file (JPEG/PNG)

---

### 🎬 Video Endpoints

#### `POST /api/videos/upload`
**Description:** Upload a video file and start processing  
**Authentication:** Required  
**Content-Type:** `multipart/form-data`  
**Body:**
```
video: <file> (video file)
```

**Response:** `200 OK`
```json
{
  "success": true,
  "message": "Video uploaded successfully",
  "jobId": "550e8400-e29b-41d4-a716-446655440000",
  "videoId": "7c9e6679-7425-40de-944b-e07fc1f90ae7"
}
```

**Possible Status:**
- `200` - Success, job created
- `400` - No video file provided or invalid file
- `401` - Invalid or missing API key

---

#### `GET /api/videos/{videoId}/items`
**Description:** Get all detected items from a processed video  
**Authentication:** Required  
**URL Parameters:**
- `videoId` - UUID of the video

**Response:** `200 OK`
```json
{
  "success": true,
  "items": [
    {
      "frameIndex": 0,
      "items": [
        {
          "name": "item-name",
          "owned": "owned",
          "equipped": true
        }
      ]
    }
  ]
}
```

**Possible Status:**
- `200` - Success
- `404` - Video not found
- `401` - Invalid or missing API key

---

### 📋 Job Endpoints

#### `GET /api/jobs`
**Description:** List all jobs with queue statistics  
**Authentication:** Required

**Response:** `200 OK`
```json
{
  "success": true,
  "jobs": [
    {
      "id": "550e8400-e29b-41d4-a716-446655440000",
      "videoId": "7c9e6679-7425-40de-944b-e07fc1f90ae7",
      "originalFileName": "video.mp4",
      "status": "processing",
      "uploadProgress": 100,
      "processingProgress": 45.5,
      "detectedFramesCount": 0,
      "currentStage": "working with ai",
      "createdAt": "2024-12-06T10:30:00.000Z",
      "updatedAt": "2024-12-06T10:30:45.000Z",
      "livePreview": {
        "frameIndex": 12,
        "previewUrl": "/frames/7c9e6679-7425-40de-944b-e07fc1f90ae7/live-preview.jpg",
        "items": [...],
        "processingTime": 0.234,
        "videoTime": 1.71,
        "updatedAt": "2024-12-06T10:30:45.123Z"
      }
    }
  ],
  "stats": {
    "running": 2,
    "maxConcurrent": 3,
    "queued": 1,
    "availableSlots": 1
  }
}
```

**Job Status Values:**
- `queued` - Waiting for processing slot
- `uploading` - File is being uploaded
- `processing` - Video is being processed
- `completed` - Processing finished successfully
- `error` - An error occurred

**Possible Status:**
- `200` - Success
- `401` - Invalid or missing API key

---

#### `GET /api/jobs/{jobId}/status`
**Description:** Get status and details of a specific job  
**Authentication:** Required  
**URL Parameters:**
- `jobId` - UUID of the job

**Response:** `200 OK`
```json
{
  "success": true,
  "job": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "videoId": "7c9e6679-7425-40de-944b-e07fc1f90ae7",
    "originalFileName": "video.mp4",
    "status": "processing",
    "uploadProgress": 100,
    "processingProgress": 67.3,
    "detectedFramesCount": 0,
    "currentStage": "getting ocr results",
    "livePreview": {
      "frameIndex": 25,
      "previewUrl": "/frames/7c9e6679-7425-40de-944b-e07fc1f90ae7/live-preview.jpg",
      "items": [
        {
          "name": "detected-item",
          "owned": "owned",
          "equipped": false
        }
      ],
      "processingTime": 0.189,
      "videoTime": 3.57,
      "updatedAt": "2024-12-06T10:31:15.456Z"
    },
    "createdAt": "2024-12-06T10:30:00.000Z",
    "updatedAt": "2024-12-06T10:31:15.456Z"
  }
}
```

**Possible Status:**
- `200` - Success
- `404` - Job not found
- `401` - Invalid or missing API key

---

### 🎨 Skin Detection Endpoints

#### `GET /api/skins/refined?videoId={videoId}`
**Description:** Get refined/filtered skin detection results  
**Authentication:** Required  
**Query Parameters:**
- `videoId` (required) - UUID of the video

**Response:** `200 OK`
```json
{
  "success": true,
  "refinedSkins": [
    "skin-name-1",
    "skin-name-2"
  ],
  "totalDetected": 45,
  "uniqueSkins": 2
}
```

**Possible Status:**
- `200` - Success
- `404` - Video not found
- `401` - Invalid or missing API key

---

### 🔍 Debug/Test Endpoint

#### `GET /api/test-key`
**Description:** Test API key validity  
**Authentication:** Required

**Response:** `200 OK`
```json
{
  "success": true,
  "message": "API key is valid!"
}
```

**Possible Status:**
- `200` - API key is valid
- `401` - Invalid or missing API key

---

## Error Responses

All error responses follow this format:

```json
{
  "success": false,
  "message": "Error description here"
}
```

### Common HTTP Status Codes

- `200` - Success
- `400` - Bad Request (invalid input)
- `401` - Unauthorized (invalid/missing API key)
- `404` - Not Found (resource doesn't exist)
- `500` - Internal Server Error

### Authentication Errors

**Missing API Key:**
```json
{
  "success": false,
  "message": "Missing API key. Please provide X-API-Key header."
}
```

**Invalid API Key:**
```json
{
  "success": false,
  "message": "Invalid API key"
}
```

---

## Usage Examples

### cURL Examples

**Upload a video:**
```bash
curl -X POST http://localhost:3000/api/videos/upload \
  -H "X-API-Key: change-me-in-production" \
  -F "video=@/path/to/video.mp4"
```

**Get all jobs:**
```bash
curl http://localhost:3000/api/jobs \
  -H "X-API-Key: change-me-in-production"
```

**Get job status:**
```bash
curl http://localhost:3000/api/jobs/550e8400-e29b-41d4-a716-446655440000/status \
  -H "X-API-Key: change-me-in-production"
```

**Get video items:**
```bash
curl http://localhost:3000/api/videos/7c9e6679-7425-40de-944b-e07fc1f90ae7/items \
  -H "X-API-Key: change-me-in-production"
```

**Test API key:**
```bash
curl http://localhost:3000/api/test-key \
  -H "X-API-Key: change-me-in-production"
```

---

### JavaScript/Fetch Examples

**Upload a video:**
```javascript
const formData = new FormData();
formData.append('video', fileInput.files[0]);

const response = await fetch('/api/videos/upload', {
  method: 'POST',
  headers: {
    'X-API-Key': 'change-me-in-production'
  },
  body: formData
});

const data = await response.json();
console.log('Job ID:', data.jobId);
```

**Poll job status:**
```javascript
async function pollJobStatus(jobId) {
  const response = await fetch(`/api/jobs/${jobId}/status`, {
    headers: {
      'X-API-Key': 'change-me-in-production'
    }
  });
  
  const data = await response.json();
  console.log('Status:', data.job.status);
  console.log('Progress:', data.job.processingProgress);
  
  return data.job;
}

// Poll every 2 seconds
const intervalId = setInterval(async () => {
  const job = await pollJobStatus(jobId);
  
  if (job.status === 'completed' || job.status === 'error') {
    clearInterval(intervalId);
  }
}, 2000);
```

**Get all jobs:**
```javascript
const response = await fetch('/api/jobs', {
  headers: {
    'X-API-Key': 'change-me-in-production'
  }
});

const data = await response.json();
console.log('Running jobs:', data.stats.running);
console.log('Queued jobs:', data.stats.queued);
console.log('All jobs:', data.jobs);
```

---

## Processing Pipeline

When a video is uploaded, it goes through these stages:

1. **queued** (if 3 jobs already running)
   - `currentStage: "queued - waiting for slot"`

2. **uploading**
   - `currentStage: "uploading video"`
   - `uploadProgress: 0-100`

3. **processing**
   - `currentStage: "splitting frames"` - Extract frames from video
   - `currentStage: "working with ai"` - AI detection on frames
   - `currentStage: "getting ocr results"` - OCR text extraction
   - `currentStage: "finalizing results"` - Cleanup and save
   - `processingProgress: 0-100`

4. **completed**
   - `currentStage: "completed"`
   - `processingProgress: 100`
   - Results available via `/api/videos/{videoId}/items`

5. **error** (if something fails)
   - `currentStage: "error"`
   - `errorMessage: "error description"`

---

## Rate Limiting & Concurrency

- **Max concurrent jobs:** 3
- **Queue:** Unlimited (jobs auto-queue when at capacity)
- **Auto-processing:** Jobs in queue automatically start when slots become available

---

## Notes

- All timestamps are in ISO 8601 format (UTC)
- UUIDs are v4 format
- File uploads use multipart/form-data
- Live preview updates in real-time during processing
- Progress percentages are floats (0.0 - 100.0)
- Frame indices are 0-based

