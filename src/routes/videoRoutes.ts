import { Router } from 'express';
import multer from 'multer';
import path from 'path';
import { env } from '../config/env';
import { uploadVideo, getVideoMetadata, getVideoDetectedFrames, getVideoItems } from '../controllers/videoController';

const allowedMimeTypes = new Set([
  'video/mp4',
  'video/quicktime',
  'video/webm',
  'video/x-matroska',
  'video/avi',
]);

const storage = multer.diskStorage({
  destination: (_req, _file, cb) => cb(null, env.uploadDir),
  filename: (_req, file, cb) => {
    const uniqueSuffix = `${Date.now()}-${Math.round(Math.random() * 1e9)}`;
    const extension = path.extname(file.originalname) || '.mp4';
    cb(null, `${uniqueSuffix}${extension}`);
  },
});

const fileFilter: multer.Options['fileFilter'] = (_req, file, cb) => {
  if (allowedMimeTypes.has(file.mimetype)) {
    cb(null, true);
  } else {
    cb(new Error('Unsupported file type. Allowed types: mp4, mov, webm, mkv, avi.'));
  }
};

const upload = multer({
  storage,
  fileFilter,
  limits: {
    fileSize: 500 * 1024 * 1024, // 500 MB
  },
});

const router = Router();

const singleVideoUpload = upload.single('video');

router.post(
  '/upload',
  (req, res, next) => {
    singleVideoUpload(req, res, (err) => {
      if (err) {
        const message = err instanceof Error ? err.message : 'Failed to upload video';
        return res.status(400).json({ success: false, message });
      }
      next();
    });
  },
  uploadVideo,
);

router.get('/:id', getVideoMetadata);
router.get('/:id/frame-count', getVideoDetectedFrames);
router.get('/:id/items', getVideoItems);

export default router;

