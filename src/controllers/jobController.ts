import { Request, Response } from 'express';
import { getJob, getAllJobs, getQueueStats } from '../services/jobService';

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

