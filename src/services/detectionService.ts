import { spawn } from 'child_process';
import path from 'path';
import fs from 'fs/promises';
import readline from 'readline';
import { env } from '../config/env';
import { FrameItems, OwnershipStatus } from '../types/media';

type DetectionStage = 'ai' | 'ocr';

interface RunDetectionOptions {
  framesDir: string;
  outputJson: string;
  totalFrames: number;
  fps?: number;
  previewFile?: string;
  onProgress?: (processedFrames: number) => void;
  onStageChange?: (stage: DetectionStage) => void;
  onFramePreview?: (frame: { frameIndex: number; items: Array<{ name: string; owned?: OwnershipStatus; equipped?: boolean }>; processingTime?: number; videoTime?: number }) => void;
  onProcessStart?: (pid: number) => void;
}

const detectorScript = path.join(__dirname, '..', '..', 'python', 'detector.py');

export const runDetections = async ({
  framesDir,
  outputJson,
  totalFrames,
  fps = 7.0,
  previewFile,
  onProgress,
  onStageChange,
  onFramePreview,
  onProcessStart,
}: RunDetectionOptions): Promise<FrameItems[]> =>
  new Promise((resolve, reject) => {
    const args = [
      detectorScript,
      '--model',
      env.yoloModelPath,
      '--frames-dir',
      framesDir,
      '--output-json',
      outputJson,
      '--confidence',
      env.minConfidence.toString(),
      '--total-frames',
      totalFrames.toString(),
      '--fps',
      fps.toString(),
    ];

    if (previewFile) {
      args.push('--preview-file', previewFile);
    }

    // Pass environment variables to Python process for cache directories
    // Use APP_DIR or RUNTIME_DIR from env, fallback to process.cwd() (works for both Docker /app and Ubuntu /opt/ai-backend)
    const appDir = process.env.APP_DIR || process.env.RUNTIME_DIR || process.cwd();
    const homeDir = process.env.HOME || appDir;
    
    const pythonEnv = {
      ...process.env,
      HOME: homeDir,
      APP_DIR: appDir,
      RUNTIME_DIR: process.env.RUNTIME_DIR || appDir,
      MPLCONFIGDIR: process.env.MPLCONFIGDIR || `${homeDir}/.config/matplotlib`,
      XDG_CACHE_HOME: process.env.XDG_CACHE_HOME || `${homeDir}/.cache`,
      XDG_CONFIG_HOME: process.env.XDG_CONFIG_HOME || `${homeDir}/.config`,
      EASYOCR_CACHE_DIR: process.env.EASYOCR_CACHE_DIR || `${homeDir}/.EasyOCR`,
    };

    const python = spawn(env.pythonExecutable, args, {
      stdio: ['ignore', 'pipe', 'pipe'],
      env: pythonEnv,
    });

    // Notify about process start with PID
    if (python.pid) {
      onProcessStart?.(python.pid);
    }

    const stdoutReader = readline.createInterface({ input: python.stdout });
    stdoutReader.on('line', (line) => {
      if (line.startsWith('PROGRESS')) {
        const [, value] = line.split(':');
        const processed = Number(value?.trim());
        if (!Number.isNaN(processed)) {
          onProgress?.(processed);
        }
        return;
      }

      if (line.startsWith('STAGE')) {
        const [, value] = line.split(':');
        const stage = value?.trim();
        if (stage === 'ai' || stage === 'ocr') {
          onStageChange?.(stage);
        }
        return;
      }

      if (line.startsWith('PREVIEW')) {
        const payload = line.slice('PREVIEW:'.length);
        try {
          const data = JSON.parse(payload) as { frameIndex: number; items: Array<{ name: string; owned?: OwnershipStatus; equipped?: boolean }>; processingTime?: number; videoTime?: number };
          onFramePreview?.(data);
        } catch (error) {
          console.warn('Failed to parse preview payload', error);
        }
        return;
      }

      if (line.startsWith('DEBUG')) {
        // Only log debug messages in development
        if (process.env.NODE_ENV !== 'production') {
          console.log(`[Python] ${line}`);
        }
        return;
      }
    });

    let stderr = '';
    python.stderr.on('data', (chunk) => {
      stderr += chunk.toString();
    });

    python.on('error', (error) => {
      const errorMessage = error instanceof Error ? error.message : 'Unknown error';
      console.error(`[DetectionService] Failed to start Python process: ${errorMessage}`);
      reject(error);
    });

    python.on('close', async (code) => {
      stdoutReader.close();
      if (code !== 0) {
        const errorMsg = stderr || `Detection script exited with code ${code}`;
        console.error(`[DetectionService] Python process failed: ${errorMsg}`);
        return reject(new Error(errorMsg));
      }

      try {
        const fileContent = await fs.readFile(outputJson, 'utf-8');
        const results = JSON.parse(fileContent) as FrameItems[];
        resolve(results);
      } catch (error) {
        const errorMsg = error instanceof Error ? error.message : 'Failed to read detection results';
        console.error(`[DetectionService] Failed to parse results: ${errorMsg}`);
        reject(new Error(errorMsg));
      }
    });
  });

