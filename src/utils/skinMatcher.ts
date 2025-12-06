import fs from 'fs/promises';
import { search } from 'fast-fuzzy';
import { FrameItems, OwnershipStatus } from '../types/media';

interface SkinEntry {
    name: string;
    uuid: string;
    normalized: string;
}

interface OwnedSkinSummary {
    name: string;
    uuid: string;
    count: number;
    equipped: boolean;
}

export class SkinMatcher {
    private skins: SkinEntry[] = [];
    private skinListPath: string;

    constructor(skinListPath: string) {
        this.skinListPath = skinListPath;
    }

    private normalizeName(str: string): string {
        return str.toLowerCase().replace(/[^a-z0-9]/g, '');
    }

    async loadSkins(): Promise<void> {
        try {
            const content = await fs.readFile(this.skinListPath, 'utf-8');
            this.skins = content
                .split('\n')
                .map(line => line.trim())
                .filter(line => line.length > 0)
                .map(line => {
                    const [name, uuid] = line.split('|');
                    if (!name || !uuid) return null;
                    return {
                        name: name.trim(),
                        uuid: uuid.trim(),
                        normalized: this.normalizeName(name)
                    };
                })
                .filter((item): item is SkinEntry => item !== null);

            console.log(`Loaded ${this.skins.length} skins from ${this.skinListPath}`);
        } catch (error) {
            console.error('Failed to load skin list:', error);
            throw error;
        }
    }

    matchSkin(ocrName: string, threshold = 0.6): SkinEntry | null {
        if (!ocrName) return null;
        const normalizedOcr = this.normalizeName(ocrName);

        // First try exact match on normalized string
        const exactMatch = this.skins.find(s => s.normalized === normalizedOcr);
        if (exactMatch) return exactMatch;

        // Then try fuzzy search
        // We search against the original names but use the normalized OCR as query? 
        // fast-fuzzy works best with the original strings usually, but let's try searching against names.
        const candidates = this.skins.map(s => s.name);
        const results = search(ocrName, candidates, {
            returnMatchData: true,
            threshold: threshold
        });

        if (results.length > 0) {
            const bestMatchName = results[0].item;
            return this.skins.find(s => s.name === bestMatchName) || null;
        }

        return null;
    }

    async getOwnedSkins(frames: FrameItems[]): Promise<{ ownedSkins: OwnedSkinSummary[] }> {
        if (this.skins.length === 0) {
            await this.loadSkins();
        }

        const skinCounts = new Map<string, { count: number; equipped: boolean; uuid: string }>();

        for (const frame of frames) {
            for (const item of frame.items) {
                if (item.owned === 'owned' || item.owned === undefined) { // Assuming owned if detected in owned list context, but check logic
                    // The user prompt implies "owned": "owned" is the key.
                    if (item.owned !== 'owned') continue;

                    const match = this.matchSkin(item.name);
                    if (match) {
                        const current = skinCounts.get(match.name) || { count: 0, equipped: false, uuid: match.uuid };
                        current.count++;
                        if (item.equipped) current.equipped = true;
                        skinCounts.set(match.name, current);
                    }
                }
            }
        }

        const ownedSkins: OwnedSkinSummary[] = Array.from(skinCounts.entries()).map(([name, data]) => ({
            name,
            uuid: data.uuid,
            count: data.count,
            equipped: data.equipped
        }));

        // Sort alphabetically
        ownedSkins.sort((a, b) => a.name.localeCompare(b.name));

        return { ownedSkins };
    }
}
