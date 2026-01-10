import { dictionary } from '../dictionary/Dictionary.js';

export class Validator {
    // Check if word is valid (buildable from rack AND in dictionary)
    validate(word: string, rackLetters: string[]): { valid: boolean; reason?: string } {
        if (!word || word.length === 0) {
            return { valid: false, reason: 'No word submitted' };
        }

        const upperWord = word.toUpperCase();

        // Check minimum length
        if (upperWord.length < 3) {
            return { valid: false, reason: 'Word must be at least 3 letters' };
        }

        // Check if buildable from rack
        if (!this.canBuildFromRack(upperWord, rackLetters)) {
            return { valid: false, reason: 'Word cannot be built from available letters' };
        }

        // Check if blocked (profanity)
        if (dictionary.isBlocked(upperWord)) {
            return { valid: false, reason: 'Word is not allowed' };
        }

        // Check if in dictionary
        if (!dictionary.isValid(upperWord)) {
            return { valid: false, reason: 'Word not in dictionary' };
        }

        return { valid: true };
    }

    // Check if word can be built from the rack letters
    private canBuildFromRack(word: string, rack: string[]): boolean {
        const available = new Map<string, number>();

        for (const letter of rack) {
            const upper = letter.toUpperCase();
            available.set(upper, (available.get(upper) || 0) + 1);
        }

        for (const char of word) {
            const count = available.get(char) || 0;
            if (count === 0) return false;
            available.set(char, count - 1);
        }

        return true;
    }
}

export const validator = new Validator();
