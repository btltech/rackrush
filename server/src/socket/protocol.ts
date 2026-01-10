// Game modes
export type GameMode = 7 | 8 | 9 | 10;
export type MatchType = 'pvp' | 'bot';
export type BotDifficulty = 'easy' | 'medium' | 'hard';

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
}

export interface SubmitWordMessage {
    type: 'submitWord';
    word: string;
}

export interface PingMessage {
    type: 'ping';
}

export interface LeaveMessage {
    type: 'leave';
}

export type ClientMessage =
    | HelloMessage
    | QueueMessage
    | SubmitWordMessage
    | PingMessage
    | LeaveMessage;

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
    endsAt: number;  // Unix timestamp (ms)
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
    yourWins: number;
    oppWins: number;
}

export interface MatchResultMessage {
    type: 'matchResult';
    yourWins: number;
    oppWins: number;
    winner: 'you' | 'opp';
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

export type ServerMessage =
    | MatchFoundMessage
    | RoundStartMessage
    | OpponentSubmittedMessage
    | RoundResultMessage
    | MatchResultMessage
    | PongMessage
    | QueuedMessage
    | ErrorMessage;
