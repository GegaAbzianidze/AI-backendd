import express from 'express';
import path from 'path';
import videoRoutes from './routes/videoRoutes';
import jobRoutes from './routes/jobRoutes';
import skinRoutes from './routes/skinRoutes';
import { env } from './config/env';
import { apiKeyAuth } from './middleware/auth';

const app = express();

app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Protected API routes (require API key)
app.use('/api/videos', apiKeyAuth, videoRoutes);
app.use('/api/jobs', apiKeyAuth, jobRoutes);
app.use('/api/skins', apiKeyAuth, skinRoutes);

app.use(express.static(env.publicDir));
app.use('/frames', express.static(env.framesDir));

app.get('/', (_req, res) => {
  res.sendFile(path.join(env.publicDir, 'index.html'));
});

// Debug endpoint to check API key (only in development)
app.get('/api/test-key', apiKeyAuth, (_req, res) => {
  res.json({ success: true, message: 'API key is valid!' });
});

app.use((err: unknown, _req: express.Request, res: express.Response, _next: express.NextFunction) => {
  console.error('Unhandled error', err);
  const message = err instanceof Error ? err.message : 'Internal server error';
  return res.status(500).json({ success: false, message });
});

app.listen(env.port, () => {
  console.log(`🚀 Video frame API listening on port ${env.port}`);
});
