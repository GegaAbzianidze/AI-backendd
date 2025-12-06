import { randomUUID } from 'crypto';
import { Job, JobStatus } from '../types/media';

const jobs = new Map<string, Job>();
const MAX_CONCURRENT_JOBS = 3;

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

export const createJob = (originalFileName: string) => {
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
    createdAt: new Date(),
    updatedAt: new Date(),
  };

  jobs.set(job.id, job);
  return job;
};

export const updateJob = (jobId: string, payload: Partial<Omit<Job, 'id' | 'createdAt' | 'videoId'>>) => {
  const job = jobs.get(jobId);
  if (!job) {
    return;
  }

  Object.assign(job, payload);
  updateTimestamp(job);
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
export const tryStartNextQueuedJob = () => {
  if (!canStartJob()) return null;
  
  const queuedJobs = getQueuedJobs();
  if (queuedJobs.length === 0) return null;
  
  const nextJob = queuedJobs[0];
  updateJob(nextJob.id, {
    status: 'uploading',
    currentStage: 'ready to upload',
  });
  
  return nextJob;
};

