// Game modes
export type GameMode = 7 | 8 | 9 | 10;
export type MatchType = 'pvp' | 'bot';
export type BotDifficulty = 'easy' | 'medium' | 'hard';

// Kids Mode settings
export type KidsAgeGroup = '4-6' | '7-9' | '10-12';
export interface KidsModeSettings {
    kidsMode: true;
    ageGroup: KidsAgeGroup;
    timerSeconds: number;
    letterCount: number;
    minWordLength: number;
    roundsPerMatch: number;
}

// Bonus tile types
export type BonusType = 'DL' | 'TL' | 'DW';
export interface BonusTile {
    index: number;  // Position in rack
    type: BonusType;
}

// Client → Server messages
export interface HelloMessage {
    type: 'hello';
    version: string;
    deviceId: string;
}

export interface QueueMessage {
    type: 'queue';
    mode: GameMode;
    matchType: MatchType;
    botDifficulty?: BotDifficulty;
    kidsMode?: KidsModeSettings;  // Kids mode matchmaking settings
}

export interface SubmitWordMessage {
    type: 'submit';
    word: string;
}

export interface PingMessage {
    type: 'ping';
}

export interface LeaveMessage {
    type: 'leave';
}

// Server → Client messages
export interface MatchFoundMessage {
    type: 'matchFound';
    roomId: string;
    opponent: {
        name: string;
        isBot: boolean;
    };
    mode: GameMode;
}

export interface RoundStartMessage {
    type: 'roundStart';
    round: number;
    letters: string[];
    bonuses: BonusTile[];
    endsAt: number;  // Unix timestamp (ms) - for server reference
    durationMs: number;  // Round duration in ms - for client relative timing
    delayMs: number;     // Time in ms before round starts (countdown)
}

export interface OpponentSubmittedMessage {
    type: 'opponentSubmitted';
}

export interface RoundResultMessage {
    type: 'roundResult';
    yourWord: string;
    yourScore: number;
    oppWord: string;
    oppScore: number;
    winner: 'you' | 'opp' | 'tie';
    yourTotalScore: number;  // Cumulative score across all rounds
    oppTotalScore: number;   // Cumulative score across all rounds
    roundNumber: number;     // Current round (1-3)
    totalRounds: number;     // Total rounds (3)
    nextRoundStartsAt?: number; // Timestamp for next round start
}

export interface MatchResultMessage {
    type: 'matchResult';
    yourTotalScore: number;
    oppTotalScore: number;
    winner: 'you' | 'opp' | 'tie';
}

export interface PongMessage {
    type: 'pong';
}

export interface ErrorMessage {
    type: 'error';
    message: string;
}

export interface QueuedMessage {
    type: 'queued';
    mode: GameMode;
}

// Daily Challenge messages
export interface GetDailyChallengeMessage {
    type: 'getDailyChallenge';
}

export interface DailyChallengeMessage {
    type: 'dailyChallenge';
    id: string;
    date: string;
    mode: GameMode;
    letters: string[];
    bonuses: BonusTile[];
}

export interface SubmitDailyWordMessage {
    type: 'submitDailyWord';
    challengeId: string;
    word: string;
}

export interface DailyResultMessage {
    type: 'dailyResult';
    word: string;
    score: number;
    isNewBest: boolean;
    rank: number;
}

export interface GetDailyLeaderboardMessage {
    type: 'getDailyLeaderboard';
}

export interface DailyLeaderboardMessage {
    type: 'dailyLeaderboard';
    challengeId: string;
    entries: Array<{
        rank: number;
        displayName: string | null;
        bestWord: string;
        score: number;
    }>;
}

export type ClientMessage =
    | HelloMessage
    | QueueMessage
    | SubmitWordMessage
    | PingMessage
    | LeaveMessage
    | GetDailyChallengeMessage
    | SubmitDailyWordMessage
    | GetDailyLeaderboardMessage;

export type ServerMessage =
    | MatchFoundMessage
    | RoundStartMessage
    | OpponentSubmittedMessage
    | RoundResultMessage
    | MatchResultMessage
    | PongMessage
    | QueuedMessage
    | ErrorMessage
    | DailyChallengeMessage
    | DailyResultMessage
    | DailyLeaderboardMessage;
