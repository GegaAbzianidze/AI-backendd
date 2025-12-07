import { Request, Response } from 'express';
import os from 'os';
import fs from 'fs';
import path from 'path';
import { getAllJobs, getQueueStats } from '../services/jobService';
import { env } from '../config/env';
import { logger } from '../services/logService';

export const getHealthCheck = (_req: Request, res: Response) => {
  return res.json({
    success: true,
    status: 'healthy',
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
  });
};

export const getLogs = (req: Request, res: Response) => {
  const limit = parseInt(req.query.limit as string) || 50;
  const logs = logger.getLogs(limit);
  
  return res.json({
    success: true,
    logs,
  });
};

export const getSystemStatus = (_req: Request, res: Response) => {
  const jobs = getAllJobs();
  const stats = getQueueStats();
  
  // CPU Info
  const cpus = os.cpus();
  const cpuUsage = process.cpuUsage();
  
  // Memory Info
  const totalMemory = os.totalmem();
  const freeMemory = os.freemem();
  const usedMemory = totalMemory - freeMemory;
  const memoryUsagePercent = (usedMemory / totalMemory) * 100;
  
  // Process Memory
  const processMemory = process.memoryUsage();
  
  // Disk Usage
  const diskUsage = getDiskUsage();
  
  // Job Statistics
  const jobStats = {
    total: jobs.length,
    queued: jobs.filter(j => j.status === 'queued').length,
    processing: jobs.filter(j => j.status === 'processing').length,
    uploading: jobs.filter(j => j.status === 'uploading').length,
    completed: jobs.filter(j => j.status === 'completed').length,
    error: jobs.filter(j => j.status === 'error').length,
  };
  
  // Active Python Processes
  const activePythonProcesses = jobs
    .filter(j => j.pythonProcessId && (j.status === 'processing' || j.status === 'uploading'))
    .map(j => ({
      jobId: j.id,
      pid: j.pythonProcessId,
      stage: j.currentStage,
    }));
  
  return res.json({
    success: true,
    timestamp: new Date().toISOString(),
    system: {
      platform: os.platform(),
      arch: os.arch(),
      hostname: os.hostname(),
      uptime: os.uptime(),
      nodeVersion: process.version,
    },
    cpu: {
      model: cpus[0]?.model || 'Unknown',
      cores: cpus.length,
      usage: {
        user: cpuUsage.user,
        system: cpuUsage.system,
      },
    },
    memory: {
      total: totalMemory,
      free: freeMemory,
      used: usedMemory,
      usagePercent: memoryUsagePercent,
      process: {
        heapUsed: processMemory.heapUsed,
        heapTotal: processMemory.heapTotal,
        external: processMemory.external,
        rss: processMemory.rss,
      },
    },
    disk: diskUsage,
    jobs: jobStats,
    queue: {
      running: stats.running,
      queued: stats.queued,
      maxConcurrent: stats.maxConcurrent,
      availableSlots: stats.availableSlots,
    },
    pythonProcesses: activePythonProcesses,
    config: {
      port: env.port,
      nodeEnv: env.nodeEnv,
      uploadDir: env.uploadDir,
      framesDir: env.framesDir,
      jobsDir: env.jobsDir,
      pythonExecutable: env.pythonExecutable,
      yoloModelPath: env.yoloModelPath,
      minConfidence: env.minConfidence,
    },
  });
};

function getDiskUsage() {
  try {
    // Get sizes of key directories
    const uploadsSize = getDirectorySize(env.uploadDir);
    const framesSize = getDirectorySize(env.framesDir);
    const jobsSize = getDirectorySize(env.jobsDir);
    
    return {
      uploads: uploadsSize,
      frames: framesSize,
      jobs: jobsSize,
      total: uploadsSize + framesSize + jobsSize,
    };
  } catch (error) {
    console.error('Error getting disk usage:', error);
    return {
      uploads: 0,
      frames: 0,
      jobs: 0,
      total: 0,
    };
  }
}

function getDirectorySize(dirPath: string): number {
  let size = 0;
  
  try {
    if (!fs.existsSync(dirPath)) {
      return 0;
    }
    
    const files = fs.readdirSync(dirPath, { withFileTypes: true });
    
    for (const file of files) {
      const filePath = path.join(dirPath, file.name);
      
      if (file.isDirectory()) {
        size += getDirectorySize(filePath);
      } else {
        try {
          const stats = fs.statSync(filePath);
          size += stats.size;
        } catch (err) {
          // Skip files that can't be accessed
        }
      }
    }
  } catch (error) {
    // Directory might not exist or be accessible
  }
  
  return size;
}

