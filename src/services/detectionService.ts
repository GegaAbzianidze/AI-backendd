import fs from 'fs/promises';
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

/**
 * Call YOLO microservice to process frames
 * This version communicates with a separate YOLO service via HTTP
 */
export const runDetections = async ({
  framesDir,
  outputJson,
  totalFrames,
  fps = 7.0,
  previewFile,
  onProgress,
  onStageChange,
  onFramePreview,
}: RunDetectionOptions): Promise<FrameItems[]> => {
  try {
    console.log(`🤖 Calling YOLO service at: ${env.yoloServiceUrl}`);
    
    // Prepare request to YOLO service
    const requestBody = {
      frames_dir: framesDir,
      output_json: outputJson,
      total_frames: totalFrames,
      preview_file: previewFile || '',
      model_path: env.yoloModelPath,
      confidence: env.minConfidence,
    };

    console.log('📤 Sending detection request...');
    onStageChange?.('ai');
    
    // Call YOLO microservice
    const response = await fetch(`${env.yoloServiceUrl}/detect`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(requestBody),
    });

    if (!response.ok) {
      const errorText = await response.text();
      throw new Error(`YOLO service error (${response.status}): ${errorText}`);
    }

    const result = await response.json() as { success: boolean; detected_frames: number; message: string };
    console.log(`✅ YOLO service completed: ${result.detected_frames} frames processed`);

    // Simulate progress updates (since we don't have streaming from HTTP)
    // In a real implementation, you might use WebSocket or polling
    const progressInterval = totalFrames / 10;
    for (let i = 1; i <= 10; i++) {
      onProgress?.(Math.min(i * progressInterval, totalFrames));
      if (i === 5) onStageChange?.('ocr');
      await new Promise(resolve => setTimeout(resolve, 100));
    }

    // Read the results from the output file
    const fileContent = await fs.readFile(outputJson, 'utf-8');
    const results = JSON.parse(fileContent) as FrameItems[];
    
    console.log(`📊 Loaded ${results.length} detection results`);
    return results;

  } catch (error) {
    console.error('❌ Detection service error:', error);
    
    // Fallback to local Python execution if microservice is unavailable
    console.log('⚠️  YOLO service unavailable, falling back to local execution...');
    return runDetectionsLocal({
      framesDir,
      outputJson,
      totalFrames,
      fps,
      previewFile,
      onProgress,
      onStageChange,
      onFramePreview,
    });
  }
};

/**
 * Fallback: Run YOLO detection locally (original implementation)
 * Used when microservice is unavailable
 */
const runDetectionsLocal = async ({
  framesDir,
  outputJson,
  totalFrames,
  fps = 7.0,
  previewFile,
  onProgress,
  onStageChange,
  onFramePreview,
}: RunDetectionOptions): Promise<FrameItems[]> => {
  const { spawn } = await import('child_process');
  const path = await import('path');
  const readline = await import('readline');
  
  return new Promise((resolve, reject) => {
    const detectorScript = path.join(__dirname, '..', '..', 'python', 'detector.py');
    
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
};

