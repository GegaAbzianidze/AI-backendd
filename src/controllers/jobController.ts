import { Request, Response } from 'express';
import { getJob, getAllJobs, getQueueStats, terminateJob, deleteJob } from '../services/jobService';
import { deleteJobData } from '../services/videoService';

export const getJobStatus = (req: Request, res: Response) => {
  const job = getJob(req.params.id);
  if (!job) {
    return res.status(404).json({
      success: false,
      message: `Job with id "${req.params.id}" was not found.`,
    });
  }

  return res.json({
    success: true,
    job,
  });
};

export const listAllJobs = (_req: Request, res: Response) => {
  const jobs = getAllJobs();
  const stats = getQueueStats();
  
  return res.json({
    success: true,
    jobs,
    stats,
  });
};

export const terminateJobById = (req: Request, res: Response) => {
  const jobId = req.params.id;
  const success = terminateJob(jobId);
  
  if (!success) {
    return res.status(400).json({
      success: false,
      message: 'Cannot terminate job. Job may be already completed or not found.',
    });
  }
  
  return res.json({
    success: true,
    message: 'Job terminated successfully',
  });
};

export const deleteJobById = async (req: Request, res: Response) => {
  const jobId = req.params.id;
  const job = getJob(jobId);
  
  if (!job) {
    return res.status(404).json({
      success: false,
      message: 'Job not found',
    });
  }
  
  try {
    // Delete all associated data (videos, frames, results)
    await deleteJobData(job.videoId, job.uploadedFilePath);
    
    // Delete job from storage
    await deleteJob(jobId);
    
    return res.json({
      success: true,
      message: 'Job and all associated data deleted successfully',
    });
  } catch (error) {
    console.error('Failed to delete job:', error);
    return res.status(500).json({
      success: false,
      message: 'Failed to delete job data',
    });
  }
};

