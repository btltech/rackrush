import { readFile } from 'fs/promises';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';

const __dirname = dirname(fileURLToPath(import.meta.url));

/**
 * Optimized Dictionary with signature-based indexing for fast word lookups.
 * 
 * Instead of scanning 172k+ words for each bot query, we:
 * 1. Pre-index words by their "signature" (sorted letter counts)
 * 2. At query time, generate all subset signatures of the rack
 * 3. Look up matching words with O(1) hash access
 * 
 * Complexity: O(2^n) subsets where n ≤ 10, vs O(172k) scans
 */
export class Dictionary {
    private words: Set<string>;
    private wordsByLength: Map<number, string[]>;
    private wordsBySignature: Map<string, string[]>;
    private blockedWords: Set<string>;

    constructor() {
        this.words = new Set();
        this.wordsByLength = new Map();
        this.wordsBySignature = new Map();
        this.blockedWords = new Set();
    }

    async load(): Promise<void> {
        // Load ENABLE word list (async to avoid blocking event loop)
        const enablePath = join(__dirname, '../../data/enable.txt');
        const content = await readFile(enablePath, 'utf-8');

        const allWords = content
            .split('\n')
            .map(w => w.trim().toUpperCase())
            .filter(w => w.length >= 3);  // Min 3 letters

        // Load profanity blocklist
        try {
            const blocklistPath = join(__dirname, '../../data/blocklist.txt');
            const blockContent = await readFile(blocklistPath, 'utf-8');
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

            // Index by length (for fallback)
            const len = word.length;
            if (!this.wordsByLength.has(len)) {
                this.wordsByLength.set(len, []);
            }
            this.wordsByLength.get(len)!.push(word);

            // Index by signature for fast lookup
            const sig = this.getSignature(word);
            if (!this.wordsBySignature.has(sig)) {
                this.wordsBySignature.set(sig, []);
            }
            this.wordsBySignature.get(sig)!.push(word);
        }

        console.log(`Dictionary loaded: ${this.words.size} words, ${this.wordsBySignature.size} signatures`);
    }

    /**
     * Get a signature for a word: sorted letters joined.
     * E.g., "APPLE" -> "AELPP"
     */
    private getSignature(word: string): string {
        return word.split('').sort().join('');
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

    /**
     * Find all valid words buildable from given rack letters.
     * Uses signature-based lookup for O(2^n) complexity instead of O(dictionary_size).
     */
    findValidWords(letters: string[]): string[] {
        const upperLetters = letters.map(l => l.toUpperCase());
        const validWords: string[] = [];
        const seenSignatures = new Set<string>();

        // Generate all non-empty subsets of letters (length 3+)
        this.generateSubsets(upperLetters, 0, [], (subset) => {
            if (subset.length < 3) return;

            const sig = subset.sort().join('');
            if (seenSignatures.has(sig)) return;
            seenSignatures.add(sig);

            const words = this.wordsBySignature.get(sig);
            if (words) {
                validWords.push(...words);
            }
        });

        return validWords;
    }

    /**
     * Generate all subsets of letters recursively.
     */
    private generateSubsets(
        letters: string[],
        index: number,
        current: string[],
        callback: (subset: string[]) => void
    ): void {
        if (index === letters.length) {
            callback([...current]);
            return;
        }

        // Include current letter
        current.push(letters[index]);
        this.generateSubsets(letters, index + 1, current, callback);
        current.pop();

        // Exclude current letter
        this.generateSubsets(letters, index + 1, current, callback);
    }

    private countLetters(letters: string[]): Map<string, number> {
        const counts = new Map<string, number>();
        for (const letter of letters) {
            const upper = letter.toUpperCase();
            counts.set(upper, (counts.get(upper) || 0) + 1);
        }
        return counts;
    }
}

// Singleton instance
export const dictionary = new Dictionary();
