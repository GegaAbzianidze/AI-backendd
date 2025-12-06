
import { SkinMatcher } from './skinMatcher';
import path from 'path';

async function test() {
    const skinListPath = path.join(__dirname, '../../skin_list.txt');
    const matcher = new SkinMatcher(skinListPath);
    await matcher.loadSkins();

    const testCases = [
        "SPECTRUEACLASSIC",
        "SPECTRURACLASSIC",
        "SPECTRUMACLASSIC",
        "SPECTRUMCLASSIC",
        "SPECTRUEA GLASSIC",
        "SPECTRURA CLASSIC",
        "SPECTRUMGLASSIC"
    ];

    console.log("Testing matches...");
    for (const testCase of testCases) {
        const match = matcher.matchSkin(testCase);
        console.log(`Input: "${testCase}" -> Match: "${match ? match.name : 'null'}"`);
    }
}

test().catch(console.error);
