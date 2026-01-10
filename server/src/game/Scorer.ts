import { BonusTile } from '../socket/protocol.js';

// Letter point values (Scrabble-style)
const LETTER_VALUES: Record<string, number> = {
    A: 1, B: 3, C: 3, D: 2, E: 1, F: 4, G: 2, H: 4, I: 1,
    J: 8, K: 5, L: 1, M: 3, N: 1, O: 1, P: 3, Q: 10, R: 1,
    S: 1, T: 1, U: 1, V: 4, W: 4, X: 8, Y: 4, Z: 10
};

// Length bonuses
const LENGTH_BONUSES: Record<number, number> = {
    6: 2,
    7: 5,
    8: 8,
    9: 12,
    10: 12,
};

export class Scorer {
    // Calculate score for a word with bonus tiles
    calculate(word: string, rackLetters: string[], bonuses: BonusTile[]): number {
        if (!word || word.length === 0) return 0;

        const upperWord = word.toUpperCase();

        // Map each letter in the word to the rack position it uses
        const usedIndices = this.mapWordToRack(upperWord, rackLetters);
        if (!usedIndices) return 0;  // Word can't be built from rack

        // Create bonus lookup by rack index
        const bonusMap = new Map<number, BonusTile>();
        for (const bonus of bonuses) {
            bonusMap.set(bonus.index, bonus);
        }

        let baseScore = 0;
        let wordMultiplier = 1;

        // Calculate letter scores with bonuses
        for (let i = 0; i < upperWord.length; i++) {
            const letter = upperWord[i];
            const rackIdx = usedIndices[i];
            let letterScore = LETTER_VALUES[letter] || 0;

            // Apply letter bonuses
            const bonus = bonusMap.get(rackIdx);
            if (bonus) {
                switch (bonus.type) {
                    case 'DL':
                        letterScore *= 2;
                        break;
                    case 'TL':
                        letterScore *= 3;
                        break;
                    case 'DW':
                        wordMultiplier *= 2;
                        break;
                }
            }

            baseScore += letterScore;
        }

        // Apply word multiplier
        let finalScore = baseScore * wordMultiplier;

        // Apply length bonus
        const lengthBonus = LENGTH_BONUSES[upperWord.length] ||
            (upperWord.length > 10 ? 12 : 0);
        finalScore += lengthBonus;

        return finalScore;
    }

    // Map each character in word to a rack index (handles duplicates)
    private mapWordToRack(word: string, rack: string[]): number[] | null {
        const rackUpper = rack.map(l => l.toUpperCase());
        const usedIndices = new Set<number>();
        const result: number[] = [];

        for (const char of word) {
            let found = false;
            for (let i = 0; i < rackUpper.length; i++) {
                if (rackUpper[i] === char && !usedIndices.has(i)) {
                    usedIndices.add(i);
                    result.push(i);
                    found = true;
                    break;
                }
            }
            if (!found) return null;  // Letter not available in rack
        }

        return result;
    }

    // Get base letter value (for UI display)
    getLetterValue(letter: string): number {
        return LETTER_VALUES[letter.toUpperCase()] || 0;
    }
}

export const scorer = new Scorer();
