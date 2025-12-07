import { Router } from 'express';
import { getSystemStatus, getHealthCheck, getLogs } from '../controllers/statusController';

const router = Router();

router.get('/health', getHealthCheck);
router.get('/system', getSystemStatus);
router.get('/logs', getLogs);

export default router;

