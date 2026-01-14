import { v4 as uuidv4 } from 'uuid';
import { GameMode, BonusTile, RoundResultMessage } from '../socket/protocol.js';
import { config } from '../config.js';
import { rackGenerator } from './RackGenerator.js';
import { validator } from './Validator.js';
import { scorer } from './Scorer.js';

export interface Player {
    id: string;
    socketId: string;
    name: string;
    isBot: boolean;
}

export interface Submission {
    word: string;
    score: number;
    valid: boolean;
    reason?: string;
    submittedAt: number;
}

export interface RoundState {
    round: number;
    letters: string[];
    bonuses: BonusTile[];
    startedAt: number;
    endsAt: number;
    submissions: Map<string, Submission>;  // playerId -> submission
}

export type RoomStatus = 'waiting' | 'playing' | 'finished';

// Kids mode settings (optional, only set for kids matches)
export interface KidsModeRoomSettings {
    kidsMode: true;
    ageGroup: '4-6' | '7-9' | '10-12';
    timerSeconds: number;
    letterCount: number;
    minWordLength: number;
    roundsPerMatch: number;
}

export class Room {
    id: string;
    mode: GameMode;
    status: RoomStatus;
    players: Player[];
    totalScores: Map<string, number>;  // playerId -> cumulative score across all rounds
    currentRound: RoundState | null;
    roundHistory: RoundState[];
    kidsMode?: KidsModeRoomSettings;  // Kids mode settings if applicable

    private roundTimer: NodeJS.Timeout | null = null;
    private onRoundEnd: ((room: Room) => void) | null = null;

    constructor(mode: GameMode) {
        this.id = uuidv4();
        this.mode = mode;
        this.status = 'waiting';
        this.players = [];
        this.totalScores = new Map();
        this.currentRound = null;
        this.roundHistory = [];
    }

    // Add a player to the room
    addPlayer(player: Player): boolean {
        if (this.players.length >= 2) return false;

        this.players.push(player);
        this.totalScores.set(player.id, 0);

        if (this.players.length === 2) {
            this.status = 'playing';
        }

        return true;
    }

    // Get opponent for a player
    getOpponent(playerId: string): Player | undefined {
        return this.players.find(p => p.id !== playerId);
    }

    // Start a new round
    startRound(onEnd: (room: Room) => void, delayMs: number = 0): RoundState {
        const roundNum = this.roundHistory.length + 1;

        // Use kids mode settings if available, otherwise use default config
        const effectiveMode = this.kidsMode?.letterCount ?? this.mode;
        const timerSeconds = this.kidsMode?.timerSeconds ?? config.modes[this.mode].timer;

        const { letters, bonuses } = rackGenerator.generate(effectiveMode as GameMode);
        const now = Date.now();
        const startTimestamp = now + delayMs;

        this.currentRound = {
            round: roundNum,
            letters,
            bonuses,
            startedAt: startTimestamp,
            endsAt: startTimestamp + timerSeconds * 1000,
            submissions: new Map(),
        };

        this.onRoundEnd = onEnd;

        // Set timer for round end
        this.roundTimer = setTimeout(() => {
            this.endRound();
        }, delayMs + timerSeconds * 1000);

        return this.currentRound;
    }

    // Submit a word for a player
    submitWord(playerId: string, word: string): Submission | null {
        if (!this.currentRound) return null;
        if (this.currentRound.submissions.has(playerId)) return null;  // Already submitted

        const now = Date.now();
        if (now > this.currentRound.endsAt) {
            // Time's up - submit empty
            word = '';
        }

        const validation = validator.validate(word, this.currentRound.letters);
        const score = validation.valid
            ? scorer.calculate(word, this.currentRound.letters, this.currentRound.bonuses)
            : 0;

        const submission: Submission = {
            word: validation.valid ? word.toUpperCase() : '',
            score,
            valid: validation.valid,
            reason: validation.reason,
            submittedAt: now,
        };

        this.currentRound.submissions.set(playerId, submission);

        // Check if both players have submitted
        if (this.currentRound.submissions.size >= 2) {
            this.endRound();
        }

        return submission;
    }

    // Force end the round (timer expired)
    private endRound(): void {
        if (!this.currentRound) return;

        // Clear timer if still running
        if (this.roundTimer) {
            clearTimeout(this.roundTimer);
            this.roundTimer = null;
        }

        // Add empty submissions for players who didn't submit
        for (const player of this.players) {
            if (!this.currentRound.submissions.has(player.id)) {
                this.currentRound.submissions.set(player.id, {
                    word: '',
                    score: 0,
                    valid: false,
                    reason: 'Time expired',
                    submittedAt: Date.now(),
                });
            }
        }

        // Add scores to cumulative totals
        const [p1, p2] = this.players;
        const sub1 = this.currentRound.submissions.get(p1.id)!;
        const sub2 = this.currentRound.submissions.get(p2.id)!;

        this.totalScores.set(p1.id, (this.totalScores.get(p1.id) || 0) + sub1.score);
        this.totalScores.set(p2.id, (this.totalScores.get(p2.id) || 0) + sub2.score);

        // Archive round
        this.roundHistory.push(this.currentRound);

        // Check for match end (after configured rounds)
        const totalRounds = this.kidsMode?.roundsPerMatch ?? config.totalRounds;
        if (this.roundHistory.length >= totalRounds) {
            this.status = 'finished';
        }

        // Notify callback
        if (this.onRoundEnd) {
            this.onRoundEnd(this);
        }
    }

    // Get round result for a specific player
    getRoundResult(playerId: string, nextRoundStartsAt?: number): RoundResultMessage | null {
        const lastRound = this.roundHistory[this.roundHistory.length - 1];
        if (!lastRound) return null;

        const opponent = this.getOpponent(playerId);
        if (!opponent) return null;

        const mySub = lastRound.submissions.get(playerId)!;
        const oppSub = lastRound.submissions.get(opponent.id)!;

        let winner: 'you' | 'opp' | 'tie';
        if (mySub.score > oppSub.score) winner = 'you';
        else if (oppSub.score > mySub.score) winner = 'opp';
        else winner = 'tie';

        return {
            type: 'roundResult',
            yourWord: mySub.word,
            yourScore: mySub.score,
            oppWord: oppSub.word,
            oppScore: oppSub.score,
            winner,
            yourTotalScore: this.totalScores.get(playerId) || 0,
            oppTotalScore: this.totalScores.get(opponent.id) || 0,
            roundNumber: this.roundHistory.length,
            totalRounds: this.kidsMode?.roundsPerMatch ?? config.totalRounds,
            nextRoundStartsAt,
        };
    }

    // Get match result for a player
    getMatchResult(playerId: string): { yourTotalScore: number; oppTotalScore: number; winner: 'you' | 'opp' | 'tie' } | null {
        if (this.status !== 'finished') return null;

        const opponent = this.getOpponent(playerId);
        if (!opponent) return null;

        const yourTotalScore = this.totalScores.get(playerId) || 0;
        const oppTotalScore = this.totalScores.get(opponent.id) || 0;

        return {
            yourTotalScore,
            oppTotalScore,
            winner: yourTotalScore > oppTotalScore ? 'you' : (yourTotalScore < oppTotalScore ? 'opp' : 'tie'),
        };
    }

    // Clean up
    destroy(): void {
        if (this.roundTimer) {
            clearTimeout(this.roundTimer);
        }
    }
}
