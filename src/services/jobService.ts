import { randomUUID } from 'crypto';
import fs from 'fs/promises';
import path from 'path';
import fsSync from 'fs';
import { Job, JobStatus } from '../types/media';
import { env } from '../config/env';
import * as videoService from './videoService';
import { logger } from './logService';

const jobs = new Map<string, Job>();
const MAX_CONCURRENT_JOBS = 3;

// Load jobs from job folders on startup
const loadJobsFromFolders = async () => {
  try {
    await fs.mkdir(env.jobsDir, { recursive: true });
    const jobFolders = await fs.readdir(env.jobsDir);
    
    let loadedCount = 0;
    for (const jobId of jobFolders) {
      const metadataPath = path.join(env.jobsDir, jobId, 'metadata.json');
      try {
        const data = await fs.readFile(metadataPath, 'utf-8');
        const job = JSON.parse(data) as Job;
        
        // Convert date strings back to Date objects
        job.createdAt = new Date(job.createdAt);
        job.updatedAt = new Date(job.updatedAt);
        jobs.set(job.id, job);
        loadedCount++;
      } catch (error) {
        console.warn(`Failed to load job ${jobId}:`, error);
      }
    }
    
    console.log(`📂 Loaded ${loadedCount} jobs from storage`);
  } catch (error) {
    if ((error as NodeJS.ErrnoException).code !== 'ENOENT') {
      console.error('Failed to load jobs:', error);
    }
  }
};

// Save job metadata to its folder
const saveJobMetadata = async (job: Job) => {
  try {
    const jobDir = path.join(env.jobsDir, job.id);
    await fs.mkdir(jobDir, { recursive: true });
    const metadataPath = path.join(jobDir, 'metadata.json');
    await fs.writeFile(metadataPath, JSON.stringify(job, null, 2));
  } catch (error) {
    console.error('Failed to save job metadata:', error);
  }
};

// Initialize jobs from folders
loadJobsFromFolders();

const updateTimestamp = (job: Job) => {
  job.updatedAt = new Date();
};

// Get count of currently running jobs
const getRunningJobsCount = () => {
  return Array.from(jobs.values()).filter(
    (job) => job.status === 'uploading' || job.status === 'processing'
  ).length;
};

// Check if we can start a new job
const canStartJob = () => {
  return getRunningJobsCount() < MAX_CONCURRENT_JOBS;
};

// Get queued jobs
const getQueuedJobs = () => {
  return Array.from(jobs.values())
    .filter((job) => job.status === 'queued')
    .sort((a, b) => a.createdAt.getTime() - b.createdAt.getTime());
};

export const createJob = (originalFileName: string, uploadedFilePath?: string) => {
  const shouldQueue = !canStartJob();
  
  const job: Job = {
    id: randomUUID(),
    videoId: randomUUID(),
    originalFileName,
    status: shouldQueue ? 'queued' : 'uploading',
    uploadProgress: 0,
    processingProgress: 0,
    detectedFramesCount: 0,
    currentStage: shouldQueue ? 'queued - waiting for slot' : 'uploading video',
    uploadedFilePath,
    createdAt: new Date(),
    updatedAt: new Date(),
  };

  jobs.set(job.id, job);
  
  // Create job folder and save metadata
  saveJobMetadata(job).catch(err => console.error('Failed to persist new job:', err));
  
  // Log job creation
  if (shouldQueue) {
    logger.info(`Job ${job.id.substring(0, 8)} created and queued for ${originalFileName}`);
  } else {
    logger.success(`Job ${job.id.substring(0, 8)} created for ${originalFileName}`);
  }
  
  return job;
};

export const updateJob = (jobId: string, payload: Partial<Omit<Job, 'id' | 'createdAt' | 'videoId'>>) => {
  const job = jobs.get(jobId);
  if (!job) {
    return;
  }

  Object.assign(job, payload);
  updateTimestamp(job);
  
  // Save metadata after each update
  saveJobMetadata(job).catch(err => console.error('Failed to persist job update:', err));
};

export const setJobStatus = (jobId: string, status: JobStatus) => {
  updateJob(jobId, { status });
  
  // When a job completes or errors, try to start the next queued job
  if (status === 'completed' || status === 'error') {
    tryStartNextQueuedJob();
  }
};

export const getJob = (jobId: string) => jobs.get(jobId);

export const getAllJobs = () => {
  return Array.from(jobs.values()).sort((a, b) => b.createdAt.getTime() - a.createdAt.getTime());
};

export const getQueueStats = () => {
  const runningCount = getRunningJobsCount();
  const queuedJobs = getQueuedJobs();
  
  return {
    running: runningCount,
    maxConcurrent: MAX_CONCURRENT_JOBS,
    queued: queuedJobs.length,
    availableSlots: MAX_CONCURRENT_JOBS - runningCount,
  };
};

// Try to start the next queued job if there's capacity
export const tryStartNextQueuedJob = async () => {
  if (!canStartJob()) return null;
  
  const queuedJobs = getQueuedJobs();
  if (queuedJobs.length === 0) return null;
  
  const nextJob = queuedJobs[0];
  
  // Check if we have the uploaded file path
  if (!nextJob.uploadedFilePath) {
    console.error(`Cannot start queued job ${nextJob.id}: no uploaded file path`);
    return null;
  }
  
  updateJob(nextJob.id, {
    status: 'processing',
    uploadProgress: 100,
    currentStage: 'starting processing',
  });
  
  logger.success(`Starting queued job ${nextJob.id.substring(0, 8)}`);
  
  // Check if file exists
  if (!fsSync.existsSync(nextJob.uploadedFilePath)) {
    updateJob(nextJob.id, {
      status: 'error',
      currentStage: 'error',
      errorMessage: 'Uploaded file not found',
    });
    logger.error(`Queued job ${nextJob.id.substring(0, 8)} failed: file not found`);
    return null;
  }
  
  // Create a mock file object
  const mockFile = {
    path: nextJob.uploadedFilePath,
    originalname: nextJob.originalFileName,
  } as Express.Multer.File;
  
  // Start processing the queued job
  videoService.processVideoJob(nextJob, mockFile).catch((error: Error) => {
      const errorMessage = error instanceof Error ? error.message : 'Unknown error';
      logger.error(`Processing error for job ${nextJob.id.substring(0, 8)}: ${errorMessage}`);
  });
  
  return nextJob;
};

export const terminateJob = (jobId: string): boolean => {
  const job = jobs.get(jobId);
  if (!job) return false;
  
  // Can't terminate already completed or errored jobs
  if (job.status === 'completed' || job.status === 'error') {
    return false;
  }
  
  // Kill Python process if it exists
  if (job.pythonProcessId) {
    try {
      process.kill(job.pythonProcessId, 'SIGTERM');
      logger.warn(`Killed Python process ${job.pythonProcessId} for job ${jobId.substring(0, 8)}`);
    } catch (error) {
      logger.error(`Failed to kill Python process ${job.pythonProcessId}`);
      // Try SIGKILL as fallback
      try {
        process.kill(job.pythonProcessId, 'SIGKILL');
      } catch (killError) {
        const killErrorMsg = killError instanceof Error ? killError.message : 'Unknown error';
        logger.error(`SIGKILL also failed for PID ${job.pythonProcessId}: ${killErrorMsg}`);
      }
    }
  }
  
  // Mark job as terminated
  updateJob(jobId, {
    status: 'error',
    currentStage: 'terminated by user',
    errorMessage: 'Job was manually terminated',
    pythonProcessId: undefined,
  });
  
  logger.warn(`Job ${jobId.substring(0, 8)} terminated by user`);
  
  // Try to start next queued job
  tryStartNextQueuedJob();
  
  return true;
};

export const deleteJob = async (jobId: string): Promise<boolean> => {
  const job = jobs.get(jobId);
  if (!job) return false;
  
  // Remove from memory
  jobs.delete(jobId);
  
  // Delete job folder
  const jobDir = path.join(env.jobsDir, jobId);
  try {
    await fs.rm(jobDir, { recursive: true, force: true });
    console.log(`🗑️  Deleted job folder: ${jobDir}`);
  } catch (error) {
    console.warn('Failed to delete job folder:', error);
  }
  
  return true;
};

