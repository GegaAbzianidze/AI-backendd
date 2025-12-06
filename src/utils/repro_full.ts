
import { SkinMatcher } from './skinMatcher';
import path from 'path';

const rawData = [
    {
        "frameIndex": 18,
        "items": [
            {
                "name": "SPECTRUEACLASSIC",
                "owned": "owned",
                "equipped": true
            }
        ]
    },
    {
        "frameIndex": 19,
        "items": [
            {
                "name": "SPECTRURACLASSIC",
                "owned": "owned",
                "equipped": true
            }
        ]
    },
    {
        "frameIndex": 20,
        "items": [
            {
                "name": "SPECTRUMACLASSIC",
                "owned": "owned",
                "equipped": true
            }
        ]
    },
    {
        "frameIndex": 21,
        "items": [
            {
                "name": "SPECTRUMCLASSIC",
                "owned": "owned",
                "equipped": true
            }
        ]
    },
    {
        "frameIndex": 22,
        "items": [
            {
                "name": "SPECTRUMACLASSIC",
                "owned": "owned",
                "equipped": true
            }
        ]
    },
    {
        "frameIndex": 23,
        "items": [
            {
                "name": "SPECTRUMCLASSIC",
                "owned": "owned",
                "equipped": true
            }
        ]
    },
    {
        "frameIndex": 24,
        "items": [
            {
                "name": "SPECTRUEA GLASSIC",
                "owned": "owned",
                "equipped": true
            }
        ]
    },
    {
        "frameIndex": 25,
        "items": [
            {
                "name": "SPECTRURA CLASSIC",
                "owned": "owned",
                "equipped": true
            }
        ]
    },
    {
        "frameIndex": 27,
        "items": [
            {
                "name": "SPECTRUMCLASSIC",
                "owned": "owned",
                "equipped": true
            }
        ]
    },
    {
        "frameIndex": 28,
        "items": [
            {
                "name": "SPECTRUMCLASSIC",
                "owned": "owned",
                "equipped": true
            }
        ]
    },
    {
        "frameIndex": 29,
        "items": [
            {
                "name": "SPECTRUMGLASSIC",
                "owned": "owned",
                "equipped": true
            }
        ]
    },
    {
        "frameIndex": 30,
        "items": [
            {
                "name": "SPECTRUMCLASSIC",
                "owned": "owned",
                "equipped": true
            }
        ]
    }
];

async function test() {
    const skinListPath = path.join(__dirname, '../../skin_list.txt');
    const matcher = new SkinMatcher(skinListPath);
    await matcher.loadSkins();

    console.log("Processing raw data...");
    // @ts-ignore
    const result = await matcher.getOwnedSkins(rawData);
    console.log("Result:", JSON.stringify(result, null, 2));
}

test().catch(console.error);
