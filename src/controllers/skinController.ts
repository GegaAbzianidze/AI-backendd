import { Request, Response } from 'express';
import path from 'path';
import fs from 'fs/promises';
import { SkinMatcher } from '../utils/skinMatcher';
import { env } from '../config/env';
import { FrameItems } from '../types/media';

const skinListPath = path.join(process.cwd(), 'skin_list.txt');
const skinMatcher = new SkinMatcher(skinListPath);

// Initialize matcher on startup
skinMatcher.loadSkins().catch((error) => {
  const errorMessage = error instanceof Error ? error.message : 'Unknown error';
  console.error('[SkinController] Failed to load skin list:', errorMessage);
});

export const getRefinedSkins = async (req: Request, res: Response) => {
    try {
        const videoId = req.query.videoId as string;
        let items: FrameItems[] = [];

        if (req.body && Array.isArray(req.body) && req.body.length > 0) {
            items = req.body;
        } else if (videoId) {
            const itemsPath = path.join(env.framesDir, videoId, 'items.json');
            try {
                const content = await fs.readFile(itemsPath, 'utf-8');
                items = JSON.parse(content);
            } catch (e) {
                return res.status(404).json({ error: 'Items file not found for this video ID' });
            }
        } else {
            return res.status(400).json({ error: 'Please provide videoId query parameter or JSON body with frames.' });
        }

        const result = await skinMatcher.getOwnedSkins(items);

        // The user requested a "small list of filtered names".
        // Let's return the simple list of names as requested before, but maybe with more info if needed.
        // The previous request was for { "owned_skins": ["Name 1", "Name 2"] }
        // I'll stick to that format as it's clean.

        const simpleList = {
            owned_skins: result.ownedSkins.map(s => s.name)
        };
        res.json(simpleList);
    } catch (error) {
        const errorMessage = error instanceof Error ? error.message : 'Internal server error';
        console.error('[SkinController] Error getting refined skins:', errorMessage);
        res.status(500).json({ error: 'Internal server error' });
    }
};
