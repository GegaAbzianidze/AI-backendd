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

    const python = spawn(env.pythonExecutable, args, {
      stdio: ['ignore', 'pipe', 'pipe'],
    });

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
        console.log(`[Python] ${line}`);
        return;
      }
    });

    let stderr = '';
    python.stderr.on('data', (chunk) => {
      stderr += chunk.toString();
    });

    python.on('error', (error) => {
      reject(error);
    });

    python.on('close', async (code) => {
      stdoutReader.close();
      if (code !== 0) {
        return reject(new Error(stderr || `Detection script exited with code ${code}`));
      }

      try {
        const fileContent = await fs.readFile(outputJson, 'utf-8');
        const results = JSON.parse(fileContent) as FrameItems[];
        resolve(results);
      } catch (error) {
        reject(error);
      }
    });
  });

