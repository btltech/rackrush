import { v4 as uuidv4 } from 'uuid';
import { BotDifficulty } from '../socket/protocol.js';
import { config } from '../config.js';
import { dictionary } from '../dictionary/Dictionary.js';
import { scorer } from '../game/Scorer.js';
import { Room, Player } from '../game/Room.js';

// Random name generator for bots and anonymous players
const ADJECTIVES = [
    'Swift', 'Clever', 'Quick', 'Sharp', 'Bright', 'Bold', 'Keen', 'Witty',
    'Smart', 'Agile', 'Noble', 'Grand', 'Prime', 'Elite', 'Alpha', 'Mega'
];

const NOUNS = [
    'Fox', 'Hawk', 'Wolf', 'Bear', 'Lion', 'Tiger', 'Eagle', 'Falcon',
    'Raven', 'Cobra', 'Viper', 'Phoenix', 'Dragon', 'Knight', 'Wizard', 'Ninja'
];

export function generateRandomName(): string {
    const adj = ADJECTIVES[Math.floor(Math.random() * ADJECTIVES.length)];
    const noun = NOUNS[Math.floor(Math.random() * NOUNS.length)];
    const num = Math.floor(Math.random() * 100);
    return `${adj}${noun}${num}`;
}

export class BotPlayer {
    id: string;
    name: string;
    difficulty: BotDifficulty;

    constructor(difficulty: BotDifficulty = 'medium') {
        this.id = `bot-${uuidv4()}`;
        this.name = `${generateRandomName()} (Bot)`;
        this.difficulty = difficulty;
    }

    toPlayer(): Player {
        return {
            id: this.id,
            socketId: '',  // Bots don't have sockets
            name: this.name,
            isBot: true,
        };
    }

    // Schedule bot's word submission - returns timeout ID for cleanup
    scheduleSubmission(room: Room, onSubmit: (word: string) => void): NodeJS.Timeout | null {
        if (!room.currentRound) return null;

        const letters = room.currentRound.letters;
        const bonuses = room.currentRound.bonuses;

        // Find all valid words
        const validWords = dictionary.findValidWords(letters);

        if (validWords.length === 0) {
            // No valid words - submit empty after delay
            const delay = this.getDelay();
            return setTimeout(() => onSubmit(''), delay);
        }

        // Score all words
        const scoredWords = validWords.map(word => ({
            word,
            score: scorer.calculate(word, letters, bonuses),
        })).sort((a, b) => b.score - a.score);

        // Pick word based on difficulty
        const word = this.pickWord(scoredWords);
        const delay = this.getDelay();

        return setTimeout(() => onSubmit(word), delay);
    }

    private pickWord(scoredWords: { word: string; score: number }[]): string {
        const total = scoredWords.length;
        if (total === 0) return '';

        let pickIndex: number;

        switch (this.difficulty) {
            case 'easy':
                // Pick from bottom 30-40%
                pickIndex = Math.floor(total * (0.6 + Math.random() * 0.4));
                break;

            case 'medium':
                // Pick from top 10-30%
                pickIndex = Math.floor(total * (Math.random() * 0.3));
                break;

            case 'hard':
                // Pick from top 5-10% (often best)
                pickIndex = Math.floor(total * (Math.random() * 0.1));
                break;

            default:
                pickIndex = 0;
        }

        // Clamp index
        pickIndex = Math.min(pickIndex, total - 1);
        pickIndex = Math.max(pickIndex, 0);

        return scoredWords[pickIndex].word;
    }

    private getDelay(): number {
        const delays = config.botDelays[this.difficulty];
        return delays.min + Math.random() * (delays.max - delays.min);
    }
}
