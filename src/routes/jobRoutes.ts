import { Router } from 'express';
import { getJobStatus, listAllJobs, terminateJobById, deleteJobById } from '../controllers/jobController';

const router = Router();

router.get('/', listAllJobs);
router.get('/:id/status', getJobStatus);
router.post('/:id/terminate', terminateJobById);
router.delete('/:id', deleteJobById);

export default router;

