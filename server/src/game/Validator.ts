import { dictionary } from '../dictionary/Dictionary.js';

// Only log in development mode to reduce production overhead
const DEBUG = process.env.NODE_ENV !== 'production';

export class Validator {
    // Check if word is valid (buildable from rack AND in dictionary)
    validate(word: string, rackLetters: string[]): { valid: boolean; reason?: string } {
        if (DEBUG) console.log(`Validating word: "${word}" against rack: ${rackLetters.join(',')}`);

        if (!word || word.length === 0) {
            if (DEBUG) console.log('Validation failed: No word submitted');
            return { valid: false, reason: 'No word submitted' };
        }

        const upperWord = word.toUpperCase();

        // Check minimum length
        if (upperWord.length < 3) {
            if (DEBUG) console.log('Validation failed: Too short');
            return { valid: false, reason: 'Word must be at least 3 letters' };
        }

        // Check if buildable from rack
        if (!this.canBuildFromRack(upperWord, rackLetters)) {
            if (DEBUG) console.log('Validation failed: Cannot build from rack');
            return { valid: false, reason: 'Word cannot be built from available letters' };
        }

        // Check if blocked (profanity)
        if (dictionary.isBlocked(upperWord)) {
            if (DEBUG) console.log('Validation failed: Blocked word');
            return { valid: false, reason: 'Word is not allowed' };
        }

        // Check if in dictionary
        if (!dictionary.isValid(upperWord)) {
            if (DEBUG) console.log(`Validation failed: "${upperWord}" not in dictionary`);
            return { valid: false, reason: 'Word not in dictionary' };
        }

        if (DEBUG) console.log(`Validation passed: "${upperWord}" is valid!`);
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
