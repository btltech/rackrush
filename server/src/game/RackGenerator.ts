import { GameMode, BonusTile, BonusType } from '../socket/protocol.js';
import { config } from '../config.js';

// Letter frequencies (Scrabble-inspired but adjusted)
const LETTER_POOL: { letter: string; weight: number; isVowel: boolean; isRare: boolean }[] = [
    // Vowels
    { letter: 'A', weight: 9, isVowel: true, isRare: false },
    { letter: 'E', weight: 12, isVowel: true, isRare: false },
    { letter: 'I', weight: 9, isVowel: true, isRare: false },
    { letter: 'O', weight: 8, isVowel: true, isRare: false },
    { letter: 'U', weight: 4, isVowel: true, isRare: false },

    // Common consonants
    { letter: 'R', weight: 6, isVowel: false, isRare: false },
    { letter: 'S', weight: 6, isVowel: false, isRare: false },
    { letter: 'T', weight: 6, isVowel: false, isRare: false },
    { letter: 'N', weight: 6, isVowel: false, isRare: false },
    { letter: 'L', weight: 4, isVowel: false, isRare: false },

    // Medium consonants
    { letter: 'C', weight: 3, isVowel: false, isRare: false },
    { letter: 'D', weight: 4, isVowel: false, isRare: false },
    { letter: 'G', weight: 3, isVowel: false, isRare: false },
    { letter: 'H', weight: 2, isVowel: false, isRare: false },
    { letter: 'M', weight: 3, isVowel: false, isRare: false },
    { letter: 'P', weight: 3, isVowel: false, isRare: false },
    { letter: 'B', weight: 2, isVowel: false, isRare: false },
    { letter: 'F', weight: 2, isVowel: false, isRare: false },
    { letter: 'W', weight: 2, isVowel: false, isRare: false },
    { letter: 'Y', weight: 2, isVowel: false, isRare: false },
    { letter: 'K', weight: 1, isVowel: false, isRare: false },
    { letter: 'V', weight: 2, isVowel: false, isRare: false },

    // Rare consonants (J, Q, X, Z)
    { letter: 'J', weight: 1, isVowel: false, isRare: true },
    { letter: 'Q', weight: 1, isVowel: false, isRare: true },
    { letter: 'X', weight: 1, isVowel: false, isRare: true },
    { letter: 'Z', weight: 1, isVowel: false, isRare: true },
];

const COMMON_CONSONANTS = ['R', 'S', 'T', 'N', 'L'];

export class RackGenerator {
    // Generate a rack for the given mode
    generate(mode: GameMode): { letters: string[]; bonuses: BonusTile[] } {
        const settings = config.modes[mode];
        const letters = this.generateLetters(settings.letters, settings.minVowels, settings.maxRare);
        const bonuses = this.generateBonuses(settings.letters);

        return { letters, bonuses };
    }

    private generateLetters(count: number, minVowels: number, maxRare: number): string[] {
        const letters: string[] = [];
        let vowelCount = 0;
        let rareCount = 0;
        let hasCommonConsonant = false;

        // Build weighted pool
        const pool = this.buildWeightedPool();

        while (letters.length < count) {
            const letter = this.pickWeighted(pool);
            const info = LETTER_POOL.find(l => l.letter === letter)!;

            // Check constraints
            if (info.isRare && rareCount >= maxRare) continue;

            letters.push(letter);

            if (info.isVowel) vowelCount++;
            if (info.isRare) rareCount++;
            if (COMMON_CONSONANTS.includes(letter)) hasCommonConsonant = true;
        }

        // Ensure minimum vowels
        while (vowelCount < minVowels) {
            // Replace a non-vowel with a vowel
            const nonVowelIdx = letters.findIndex(l =>
                !LETTER_POOL.find(p => p.letter === l)?.isVowel
            );
            if (nonVowelIdx === -1) break;

            const vowel = this.pickRandomVowel();
            letters[nonVowelIdx] = vowel;
            vowelCount++;
        }

        // Ensure at least one common consonant
        if (!hasCommonConsonant) {
            const vowelIndices = letters
                .map((l, i) => ({ l, i }))
                .filter(({ l }) => LETTER_POOL.find(p => p.letter === l)?.isVowel && vowelCount > minVowels);

            if (vowelIndices.length > 0) {
                const idx = vowelIndices[0].i;
                letters[idx] = COMMON_CONSONANTS[Math.floor(Math.random() * COMMON_CONSONANTS.length)];
                vowelCount--;
            }
        }

        // Shuffle the rack
        return this.shuffle(letters);
    }

    private generateBonuses(rackSize: number): BonusTile[] {
        const bonuses: BonusTile[] = [];
        const bonusCount = Math.floor(rackSize / 3);  // 2-3 bonuses per rack
        const usedIndices = new Set<number>();

        const bonusTypes: BonusType[] = ['DL', 'TL', 'DW'];

        for (let i = 0; i < bonusCount; i++) {
            let index: number;
            do {
                index = Math.floor(Math.random() * rackSize);
            } while (usedIndices.has(index));

            usedIndices.add(index);

            // DW is rarer
            const type = Math.random() < 0.2
                ? 'DW'
                : (Math.random() < 0.5 ? 'DL' : 'TL');

            bonuses.push({ index, type });
        }

        return bonuses;
    }

    private buildWeightedPool(): { letter: string; cumWeight: number }[] {
        let cumulative = 0;
        return LETTER_POOL.map(l => {
            cumulative += l.weight;
            return { letter: l.letter, cumWeight: cumulative };
        });
    }

    private pickWeighted(pool: { letter: string; cumWeight: number }[]): string {
        const total = pool[pool.length - 1].cumWeight;
        const rand = Math.random() * total;

        for (const item of pool) {
            if (rand <= item.cumWeight) {
                return item.letter;
            }
        }
        return pool[pool.length - 1].letter;
    }

    private pickRandomVowel(): string {
        const vowels = ['A', 'E', 'I', 'O', 'U'];
        // E is most common
        const weights = [2, 3, 2, 2, 1];
        const total = weights.reduce((a, b) => a + b, 0);
        let rand = Math.random() * total;

        for (let i = 0; i < vowels.length; i++) {
            rand -= weights[i];
            if (rand <= 0) return vowels[i];
        }
        return 'E';
    }

    private shuffle<T>(arr: T[]): T[] {
        const result = [...arr];
        for (let i = result.length - 1; i > 0; i--) {
            const j = Math.floor(Math.random() * (i + 1));
            [result[i], result[j]] = [result[j], result[i]];
        }
        return result;
    }
}

export const rackGenerator = new RackGenerator();
