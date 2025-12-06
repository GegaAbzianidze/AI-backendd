import fs from 'fs/promises';
import path from 'path';
import ffmpeg from 'fluent-ffmpeg';
import { env } from '../config/env';
import { FrameItems } from '../types/media';
import { Job } from '../types/media';
import { updateJob } from './jobService';
import { runDetections } from './detectionService';

export interface VideoMetadata {
  id: string;
  originalFileName: string;
  storedFilePath: string;
  detectedFrameCount: number;
  createdAt: Date;
  itemsFile: string;
  frames: FrameItems[];
}

const videos = new Map<string, VideoMetadata>();

const extractFrames = (inputFile: string, outputPattern: string, onProgress?: (percent: number) => void) =>
  new Promise<void>((resolve, reject) => {
    ffmpeg(inputFile)
      .output(outputPattern)
      .outputOptions(['-vf', 'fps=7'])
      .on('progress', (progress) => {
        if (typeof progress.percent === 'number') {
          onProgress?.(progress.percent);
        }
      })
      .on('end', () => resolve())
      .on('error', (error: Error) => reject(error))
      .run();
  });

const prepareDirectory = async (dir: string) => {
  await fs.rm(dir, { recursive: true, force: true });
  await fs.mkdir(dir, { recursive: true });
};

const extractionWeight = 20;
const aiWeight = 30;
const ocrWeight = 50;

export const processVideoJob = async (job: Job, file: Express.Multer.File) => {
  try {
    updateJob(job.id, { uploadProgress: 100, status: 'processing', processingProgress: 1 });

    const videoDir = path.join(env.framesDir, job.videoId);
    const rawDir = path.join(videoDir, 'raw');
    const itemsJson = path.join(videoDir, 'items.json');
    const previewFile = path.join(videoDir, 'live-preview.jpg');

    await prepareDirectory(videoDir);
    await fs.mkdir(rawDir, { recursive: true });

    updateJob(job.id, { currentStage: 'splitting frames' });
    await extractFrames(
      file.path,
      path.join(rawDir, 'frame-%04d.png'),
      (percent) => updateJob(job.id, { processingProgress: Math.min(extractionWeight, (percent / 100) * extractionWeight) }),
    );

    let frameFiles = (await fs.readdir(rawDir))
      .filter((name) => name.endsWith('.png') || name.endsWith('.jpg'))
      .sort((a, b) => a.localeCompare(b));

    if (frameFiles.length > 1) {
      const filesToRemove = frameFiles.filter((_, index) => index % 2 === 1);
      await Promise.all(filesToRemove.map((fileName) => fs.rm(path.join(rawDir, fileName))));
      frameFiles = frameFiles.filter((_, index) => index % 2 === 0);
    }

    const totalFrames = Math.max(frameFiles.length, 1);
    let currentDetectionStage: 'ai' | 'ocr' = 'ai';

    updateJob(job.id, { currentStage: 'working with ai' });
    const detectionResults = await runDetections({
      framesDir: rawDir,
      outputJson: itemsJson,
      totalFrames,
      previewFile,
      onProgress: (processed) => {
        const normalized = Math.min(processed, totalFrames) / totalFrames;
        let progress = 0;

        if (currentDetectionStage === 'ai') {
          progress = extractionWeight + (normalized * aiWeight);
        } else {
          progress = extractionWeight + aiWeight + (normalized * ocrWeight);
        }

        updateJob(job.id, { processingProgress: Number(progress.toFixed(2)) });
      },
      onStageChange: (stage) => {
        currentDetectionStage = stage;
        if (stage === 'ai') {
          updateJob(job.id, { currentStage: 'working with ai' });
        } else {
          updateJob(job.id, { currentStage: 'getting ocr results' });
        }
      },
      onFramePreview: (frame) => {
        updateJob(job.id, {
          livePreview: {
            frameIndex: frame.frameIndex,
            previewUrl: `/frames/${job.videoId}/live-preview.jpg`,
            items: frame.items,
            processingTime: frame.processingTime,
            videoTime: frame.videoTime,
            updatedAt: new Date().toISOString(),
          },
        });
      },
    });

    updateJob(job.id, { currentStage: 'finalizing results' });
    await fs.rm(rawDir, { recursive: true, force: true });
    await fs.writeFile(itemsJson, JSON.stringify(detectionResults, null, 2));

    const metadata: VideoMetadata = {
      id: job.videoId,
      originalFileName: file.originalname,
      storedFilePath: file.path,
      detectedFrameCount: detectionResults.length,
      createdAt: new Date(),
      itemsFile: itemsJson,
      frames: detectionResults,
    };

    videos.set(job.videoId, metadata);
    updateJob(job.id, {
      status: 'completed',
      processingProgress: 100,
      detectedFramesCount: detectionResults.length,
      currentStage: 'completed',
    });
  } catch (error) {
    console.error('Video processing failed', error);
    updateJob(job.id, {
      status: 'error',
      errorMessage: error instanceof Error ? error.message : 'Failed to process video',
      currentStage: 'error',
    });
  }
};

export const getVideo = (id: string): VideoMetadata | undefined => videos.get(id);

export const getVideoItems = (id: string): FrameItems[] | undefined => videos.get(id)?.frames;

