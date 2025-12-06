import { Router } from 'express';
import { getJobStatus, listAllJobs } from '../controllers/jobController';

const router = Router();

router.get('/', listAllJobs);
router.get('/:id/status', getJobStatus);

export default router;

