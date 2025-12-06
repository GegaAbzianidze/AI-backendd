import { Router } from 'express';
import { getRefinedSkins } from '../controllers/skinController';

const router = Router();

router.get('/refined', getRefinedSkins);
router.post('/refined', getRefinedSkins);

export default router;
