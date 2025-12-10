import express from 'express';
import path from 'path';
import videoRoutes from './routes/videoRoutes';
import jobRoutes from './routes/jobRoutes';
import jobFilesRoutes from './routes/jobFilesRoutes';
import skinRoutes from './routes/skinRoutes';
import statusRoutes from './routes/statusRoutes';
import { env } from './config/env';
import { apiKeyAuth } from './middleware/auth';
import { logger } from './services/logService';

const app = express();

app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Protected API routes (require API key)
app.use('/api/videos', apiKeyAuth, videoRoutes);
app.use('/api/jobs', apiKeyAuth, jobRoutes);
app.use('/api/job-files', apiKeyAuth, jobFilesRoutes);
app.use('/api/skins', apiKeyAuth, skinRoutes);
app.use('/api/status', apiKeyAuth, statusRoutes);

app.use(express.static(env.publicDir));
app.use('/frames', express.static(env.framesDir));

app.get('/', (_req, res) => {
  res.sendFile(path.join(env.publicDir, 'index.html'));
});

// Debug endpoint to check API key (only in development)
if (process.env.NODE_ENV !== 'production') {
  app.get('/api/test-key', apiKeyAuth, (_req, res) => {
    res.json({ success: true, message: 'API key is valid!' });
  });
}

app.use((err: unknown, _req: express.Request, res: express.Response, _next: express.NextFunction) => {
  const message = err instanceof Error ? err.message : 'Internal server error';
  const errorStack = err instanceof Error ? err.stack : undefined;
  
  // Log full error in development, sanitized in production
  if (process.env.NODE_ENV !== 'production') {
    console.error('[Express] Unhandled error:', err);
    if (errorStack) {
      console.error('[Express] Stack trace:', errorStack);
    }
  } else {
    console.error('[Express] Unhandled error:', message);
  }
  
  logger.error(`Unhandled error: ${message}`);
  return res.status(500).json({ success: false, message });
});

app.listen(env.port, () => {
  console.log(`🚀 Video frame API listening on port ${env.port}`);
  console.log(`📁 Upload directory: ${env.uploadDir}`);
  console.log(`🎞️  Frames directory: ${env.framesDir}`);
  console.log(`📂 Jobs directory: ${env.jobsDir}`);
  
  // Log to monitoring system
  logger.success(`Server started on port ${env.port}`);
  logger.info(`Environment: ${env.nodeEnv}`);
  logger.info(`Max concurrent jobs: 3`);
});
