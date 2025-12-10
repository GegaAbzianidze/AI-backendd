import { Request, Response, NextFunction } from 'express';
import { env } from '../config/env';

export const apiKeyAuth = (req: Request, res: Response, next: NextFunction) => {
  const apiKey = req.header('X-API-Key');
  const serverKey = env.apiKey;

  if (!serverKey || serverKey === 'change-me-in-production') {
    console.error('[Auth] API_KEY not properly configured in environment variables');
    return res.status(500).json({ success: false, message: 'API key not configured on server' });
  }

  if (!apiKey) {
    return res.status(401).json({ success: false, message: 'Missing API key. Please provide X-API-Key header.' });
  }

  if (apiKey !== serverKey) {
    return res.status(401).json({ success: false, message: 'Invalid API key' });
  }

  next();
};

