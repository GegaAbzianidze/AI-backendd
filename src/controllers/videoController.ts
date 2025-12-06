import { Request, Response } from 'express';
import * as videoService from '../services/videoService';
import * as jobService from '../services/jobService';

export const uploadVideo = async (req: Request, res: Response) => {
  try {
    if (!req.file) {
      return res.status(400).json({
        success: false,
        message: 'No video file provided. Make sure the field name is "video".',
      });
    }

    const job = jobService.createJob(req.file.originalname);
    videoService.processVideoJob(job, req.file).catch((error) => {
      console.error('Background processing error', error);
    });

    return res.status(202).json({
      success: true,
      jobId: job.id,
      videoId: job.videoId,
    });
  } catch (error) {
    console.error('Video processing failed', error);
    const message = error instanceof Error ? error.message : 'Failed to process video';
    return res.status(500).json({ success: false, message });
  }
};

export const getVideoMetadata = (req: Request, res: Response) => {
  const { id } = req.params;
  const video = videoService.getVideo(id);

  if (!video) {
    return res.status(404).json({
      success: false,
      message: `Video with id "${id}" was not found.`,
    });
  }

  return res.json({
    success: true,
    video: {
      id: video.id,
      originalFileName: video.originalFileName,
      detectedFrameCount: video.detectedFrameCount,
      createdAt: video.createdAt,
    },
  });
};

export const getVideoDetectedFrames = (req: Request, res: Response) => {
  const { id } = req.params;
  const video = videoService.getVideo(id);

  if (!video) {
    return res.status(404).json({
      success: false,
      message: `Video with id "${id}" was not found.`,
    });
  }

  return res.json({
    success: true,
    videoId: video.id,
    detectedFrameCount: video.detectedFrameCount,
  });
};

export const getVideoItems = (req: Request, res: Response) => {
  const { id } = req.params;
  const frames = videoService.getVideoItems(id);

  if (!frames) {
    return res.status(404).json({
      success: false,
      message: `Video with id "${id}" was not found.`,
    });
  }

  return res.json({
    success: true,
    videoId: id,
    frames,
  });
};

