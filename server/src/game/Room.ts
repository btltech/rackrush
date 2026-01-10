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

export class Room {
    id: string;
    mode: GameMode;
    status: RoomStatus;
    players: Player[];
    wins: Map<string, number>;  // playerId -> win count
    currentRound: RoundState | null;
    roundHistory: RoundState[];

    private roundTimer: NodeJS.Timeout | null = null;
    private onRoundEnd: ((room: Room) => void) | null = null;

    constructor(mode: GameMode) {
        this.id = uuidv4();
        this.mode = mode;
        this.status = 'waiting';
        this.players = [];
        this.wins = new Map();
        this.currentRound = null;
        this.roundHistory = [];
    }

    // Add a player to the room
    addPlayer(player: Player): boolean {
        if (this.players.length >= 2) return false;

        this.players.push(player);
        this.wins.set(player.id, 0);

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
    startRound(onEnd: (room: Room) => void): RoundState {
        const roundNum = this.roundHistory.length + 1;
        const { letters, bonuses } = rackGenerator.generate(this.mode);
        const timerSeconds = config.modes[this.mode].timer;
        const now = Date.now();

        this.currentRound = {
            round: roundNum,
            letters,
            bonuses,
            startedAt: now,
            endsAt: now + timerSeconds * 1000,
            submissions: new Map(),
        };

        this.onRoundEnd = onEnd;

        // Set timer for round end
        this.roundTimer = setTimeout(() => {
            this.endRound();
        }, timerSeconds * 1000);

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

        // Determine round winner
        const [p1, p2] = this.players;
        const sub1 = this.currentRound.submissions.get(p1.id)!;
        const sub2 = this.currentRound.submissions.get(p2.id)!;

        if (sub1.score > sub2.score) {
            this.wins.set(p1.id, (this.wins.get(p1.id) || 0) + 1);
        } else if (sub2.score > sub1.score) {
            this.wins.set(p2.id, (this.wins.get(p2.id) || 0) + 1);
        }
        // Tie: no points awarded

        // Archive round
        this.roundHistory.push(this.currentRound);

        // Check for match end
        const p1Wins = this.wins.get(p1.id) || 0;
        const p2Wins = this.wins.get(p2.id) || 0;

        if (p1Wins >= config.roundsToWin || p2Wins >= config.roundsToWin ||
            this.roundHistory.length >= config.maxRounds) {
            this.status = 'finished';
        }

        // Notify callback
        if (this.onRoundEnd) {
            this.onRoundEnd(this);
        }
    }

    // Get round result for a specific player
    getRoundResult(playerId: string): RoundResultMessage | null {
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
            yourWins: this.wins.get(playerId) || 0,
            oppWins: this.wins.get(opponent.id) || 0,
        };
    }

    // Get match result for a player
    getMatchResult(playerId: string): { yourWins: number; oppWins: number; winner: 'you' | 'opp' } | null {
        if (this.status !== 'finished') return null;

        const opponent = this.getOpponent(playerId);
        if (!opponent) return null;

        const yourWins = this.wins.get(playerId) || 0;
        const oppWins = this.wins.get(opponent.id) || 0;

        return {
            yourWins,
            oppWins,
            winner: yourWins >= oppWins ? 'you' : 'opp',
        };
    }

    // Clean up
    destroy(): void {
        if (this.roundTimer) {
            clearTimeout(this.roundTimer);
        }
    }
}
