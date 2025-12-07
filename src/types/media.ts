export type JobStatus = 'queued' | 'uploading' | 'processing' | 'completed' | 'error';

export type OwnershipStatus = 'owned' | 'not_owned';

export interface FrameItem {
  name: string;
  owned?: OwnershipStatus;
  equipped?: boolean;
}

export interface FrameItems {
  frameIndex: number;
  items: FrameItem[];
}

export interface Job {
  id: string;
  videoId: string;
  originalFileName: string;
  status: JobStatus;
  uploadProgress: number;
  processingProgress: number;
  detectedFramesCount: number;
  currentStage: string;
  uploadedFilePath?: string;
  pythonProcessId?: number;
  livePreview?: {
    frameIndex: number;
    previewUrl: string;
    items: Array<{ name: string; owned?: OwnershipStatus; equipped?: boolean }>;
    processingTime?: number;
    videoTime?: number;
    updatedAt: string;
  };
  createdAt: Date;
  updatedAt: Date;
  errorMessage?: string;
}
