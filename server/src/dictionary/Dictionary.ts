import { readFileSync } from 'fs';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';

const __dirname = dirname(fileURLToPath(import.meta.url));

export class Dictionary {
    private words: Set<string>;
    private wordsByLength: Map<number, string[]>;
    private blockedWords: Set<string>;

    constructor() {
        this.words = new Set();
        this.wordsByLength = new Map();
        this.blockedWords = new Set();
    }

    async load(): Promise<void> {
        // Load ENABLE word list
        const enablePath = join(__dirname, '../../data/enable.txt');
        const content = readFileSync(enablePath, 'utf-8');

        const allWords = content
            .split('\n')
            .map(w => w.trim().toUpperCase())
            .filter(w => w.length >= 3);  // Min 3 letters

        // Load profanity blocklist
        try {
            const blocklistPath = join(__dirname, '../../data/blocklist.txt');
            const blockContent = readFileSync(blocklistPath, 'utf-8');
            blockContent
                .split('\n')
                .map(w => w.trim().toUpperCase())
                .filter(w => w.length > 0)
                .forEach(w => this.blockedWords.add(w));

            console.log(`Loaded ${this.blockedWords.size} blocked words`);
        } catch {
            console.log('No blocklist.txt found, continuing without profanity filter');
        }

        // Filter out blocked words and build lookup structures
        for (const word of allWords) {
            if (this.blockedWords.has(word)) continue;

            this.words.add(word);

            const len = word.length;
            if (!this.wordsByLength.has(len)) {
                this.wordsByLength.set(len, []);
            }
            this.wordsByLength.get(len)!.push(word);
        }

        console.log(`Dictionary loaded: ${this.words.size} words (3+ letters, profanity filtered)`);
    }

    isValid(word: string): boolean {
        return this.words.has(word.toUpperCase());
    }

    isBlocked(word: string): boolean {
        return this.blockedWords.has(word.toUpperCase());
    }

    getWordsOfLength(length: number): string[] {
        return this.wordsByLength.get(length) || [];
    }

    // Find all valid words buildable from given letters
    findValidWords(letters: string[]): string[] {
        const letterCounts = this.countLetters(letters);
        const validWords: string[] = [];

        // Only check words up to the rack length
        for (let len = 3; len <= letters.length; len++) {
            for (const word of this.getWordsOfLength(len)) {
                if (this.canBuildWord(word, letterCounts)) {
                    validWords.push(word);
                }
            }
        }

        return validWords;
    }

    private countLetters(letters: string[]): Map<string, number> {
        const counts = new Map<string, number>();
        for (const letter of letters) {
            const upper = letter.toUpperCase();
            counts.set(upper, (counts.get(upper) || 0) + 1);
        }
        return counts;
    }

    private canBuildWord(word: string, available: Map<string, number>): boolean {
        const needed = this.countLetters(word.split(''));
        for (const [letter, count] of needed) {
            if ((available.get(letter) || 0) < count) {
                return false;
            }
        }
        return true;
    }
}

// Singleton instance
export const dictionary = new Dictionary();
