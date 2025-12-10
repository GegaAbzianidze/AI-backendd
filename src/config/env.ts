import path from 'path';
import fs from 'fs';
import dotenv from 'dotenv';

const projectRoot = path.resolve(__dirname, '..', '..');

// Load .env file from project root
const envPath = path.join(projectRoot, '.env');
const envLoaded = dotenv.config({ path: envPath });

if (envLoaded.error && !envLoaded.error.message.includes('ENOENT')) {
  console.warn('Warning: Error loading .env file:', envLoaded.error.message);
} else if (!fs.existsSync(envPath)) {
  console.log('ℹ️  No .env file found, using defaults');
} else {
  console.log('✅ Loaded .env file from:', envPath);
}

const ensureDirectory = (dirPath: string) => {
  if (!fs.existsSync(dirPath)) {
    fs.mkdirSync(dirPath, { recursive: true });
  }
};

const apiKey = process.env.API_KEY ?? 'change-me-in-production';
const maskedKey = apiKey.length > 8 ? `${apiKey.substring(0, 4)}...${apiKey.substring(apiKey.length - 4)}` : '***';
// Only log masked key in development to avoid leaking secrets
if (process.env.NODE_ENV !== 'production') {
  console.log(`🔑 API Key: ${process.env.API_KEY ? `Using custom key (${maskedKey})` : 'Using default key (change-me-in-production)'}`);
}

export const env = {
  nodeEnv: process.env.NODE_ENV ?? 'development',
  port: Number(process.env.PORT) || 3000,
  apiKey,
  uploadDir: path.join(projectRoot, 'uploads'),
  framesDir: path.join(projectRoot, 'frames'),
  jobsDir: path.join(projectRoot, 'jobs'),
  publicDir: path.join(projectRoot, 'public'),
  pythonExecutable: process.env.PYTHON_EXECUTABLE ?? path.join(projectRoot, 'python', 'venv', process.platform === 'win32' ? 'Scripts' : 'bin', 'python'),
  yoloModelPath:
    process.env.YOLO_MODEL_PATH ?? path.join(projectRoot, 'models', 'my_model', 'train', 'weights', 'best.pt'),
  minConfidence: Number(process.env.MIN_CONFIDENCE ?? '0.5'),
};

ensureDirectory(env.uploadDir);
ensureDirectory(env.framesDir);
ensureDirectory(env.jobsDir);

