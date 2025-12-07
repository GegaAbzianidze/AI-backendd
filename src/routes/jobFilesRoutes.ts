import { Router, Request, Response } from 'express';
import path from 'path';
import { env } from '../config/env';
import { getJob } from '../services/jobService';

const router = Router();

// Get job's items.json
router.get('/:jobId/items.json', (req: Request, res: Response) => {
  const job = getJob(req.params.jobId);
  
  if (!job) {
    return res.status(404).json({ success: false, message: 'Job not found' });
  }
  
  const itemsPath = path.join(env.jobsDir, req.params.jobId, 'items.json');
  res.sendFile(itemsPath, (err) => {
    if (err) {
      res.status(404).json({ success: false, message: 'Items file not found' });
    }
  });
});

// Get job's preview image
router.get('/:jobId/preview.jpg', (req: Request, res: Response) => {
  const job = getJob(req.params.jobId);
  
  if (!job) {
    return res.status(404).json({ success: false, message: 'Job not found' });
  }
  
  const previewPath = path.join(env.jobsDir, req.params.jobId, 'preview.jpg');
  res.sendFile(previewPath, (err) => {
    if (err) {
      res.status(404).json({ success: false, message: 'Preview image not found' });
    }
  });
});

export default router;

