import { Server, Socket } from 'socket.io';
import { v4 as uuidv4 } from 'uuid';
import {
    ClientMessage,
    ServerMessage,
    GameMode,
    MatchType,
    BotDifficulty,
    KidsModeSettings,
    KidsAgeGroup,
} from './protocol.js';
import { Room, Player } from '../game/Room.js';
import { BotPlayer, generateRandomName } from '../bot/BotPlayer.js';
import { config } from '../config.js';
import { getOrCreateTodaysChallenge, submitDailyScore, getDailyLeaderboard } from '../game/DailyChallenge.js';
import { validator } from '../game/Validator.js';
import { scorer } from '../game/Scorer.js';

// Only log in development mode to reduce production overhead
const DEBUG = process.env.NODE_ENV !== 'production';

// Store for active rooms and queues
const rooms = new Map<string, Room>();
const playerRooms = new Map<string, string>();  // socketId -> roomId
const playerIds = new Map<string, string>();    // socketId -> playerId
const playerKidsSettings = new Map<string, KidsModeSettings>();  // socketId -> kids settings

// Queue structure: mode -> array of waiting sockets
const pvpQueues = new Map<GameMode, Socket[]>();
for (const mode of [7, 8, 9, 10] as GameMode[]) {
    pvpQueues.set(mode, []);
}

// Rate limiting: socketId -> { count, resetTime }
const rateLimits = new Map<string, { count: number; resetTime: number }>();
const RATE_LIMIT_WINDOW_MS = 1000;  // 1 second window
const RATE_LIMIT_MAX_MESSAGES = 10;  // Max 10 messages per second

// Kids mode queue: ageGroup -> array of waiting sockets (separate from regular queue)
const kidsQueues = new Map<KidsAgeGroup, Socket[]>();
for (const age of ['4-6', '7-9', '10-12'] as KidsAgeGroup[]) {
    kidsQueues.set(age, []);
}

export function setupHandlers(io: Server): void {
    io.on('connection', (socket: Socket) => {
        if (DEBUG) console.log(`Client connected: ${socket.id}`);

        socket.on('message', (data: ClientMessage) => {
            // Rate limiting check
            const now = Date.now();
            let limit = rateLimits.get(socket.id);
            if (!limit || now > limit.resetTime) {
                limit = { count: 0, resetTime: now + RATE_LIMIT_WINDOW_MS };
            }
            limit.count++;
            rateLimits.set(socket.id, limit);

            if (limit.count > RATE_LIMIT_MAX_MESSAGES) {
                if (DEBUG) console.log(`Rate limited: ${socket.id}`);
                return;  // Silently drop message
            }

            if (DEBUG) console.log('Received message:', data);
            handleMessage(io, socket, data);
        });

        socket.on('disconnect', () => {
            handleDisconnect(io, socket);
            rateLimits.delete(socket.id);  // Cleanup rate limit entry
        });
    });
}

function handleMessage(io: Server, socket: Socket, msg: ClientMessage): void {
    switch (msg.type) {
        case 'hello':
            handleHello(socket, msg.deviceId);
            break;

        case 'queue':
            handleQueue(io, socket, msg.mode, msg.matchType, msg.botDifficulty, msg.kidsMode);
            break;

        case 'submit':
            handleSubmitWord(io, socket, msg.word);
            break;

        case 'ping':
            send(socket, { type: 'pong' });
            break;

        case 'leave':
            handleLeave(io, socket);
            break;

        case 'getDailyChallenge':
            handleGetDailyChallenge(socket);
            break;

        case 'submitDailyWord':
            handleSubmitDailyWord(socket, msg.word);
            break;

        case 'getDailyLeaderboard':
            handleGetDailyLeaderboard(socket);
            break;
    }
}

function handleHello(socket: Socket, deviceId: string): void {
    // Generate or retrieve player ID
    let playerId = playerIds.get(socket.id);
    if (!playerId) {
        playerId = `player-${uuidv4()}`;
        playerIds.set(socket.id, playerId);
    }
    if (DEBUG) console.log(`Player ${playerId} identified (device: ${deviceId})`);
}

function handleQueue(
    io: Server,
    socket: Socket,
    mode: GameMode,
    matchType: MatchType,
    botDifficulty?: BotDifficulty,
    kidsSettings?: KidsModeSettings
): void {
    const playerId = playerIds.get(socket.id) || `player-${uuidv4()}`;
    playerIds.set(socket.id, playerId);

    // Store kids settings if provided
    if (kidsSettings?.kidsMode) {
        playerKidsSettings.set(socket.id, kidsSettings);
    }

    if (matchType === 'bot') {
        // Create room with bot immediately
        // For kids mode, use age-appropriate bot difficulty
        let difficulty = botDifficulty || 'medium';
        if (kidsSettings?.kidsMode) {
            switch (kidsSettings.ageGroup) {
                case '4-6': difficulty = 'easy'; break;
                case '7-9': difficulty = 'easy'; break;
                case '10-12': difficulty = 'medium'; break;
            }
        }
        createBotMatch(io, socket, playerId, mode, difficulty, kidsSettings);
    } else {
        // Kids mode uses separate queue for safety
        if (kidsSettings?.kidsMode) {
            addToKidsQueue(io, socket, playerId, kidsSettings);
        } else {
            // Add to regular PvP queue
            addToQueue(io, socket, playerId, mode);
        }
    }
}

// Kids-only matchmaking queue (separate from regular queue)
function addToKidsQueue(
    io: Server,
    socket: Socket,
    playerId: string,
    kidsSettings: KidsModeSettings
): void {
    const ageGroup = kidsSettings.ageGroup;
    const queue = kidsQueues.get(ageGroup)!;

    // Check if already in queue
    if (queue.some(s => s.id === socket.id)) {
        send(socket, { type: 'queued', mode: kidsSettings.letterCount as GameMode });
        return;
    }

    queue.push(socket);
    send(socket, { type: 'queued', mode: kidsSettings.letterCount as GameMode });

    if (DEBUG) console.log(`Kids queue [${ageGroup}]: ${queue.length} waiting`);

    // Try to match with another kid in same age group
    if (queue.length >= 2) {
        const socket1 = queue.shift()!;
        const socket2 = queue.shift()!;

        const player1Id = playerIds.get(socket1.id)!;
        const player2Id = playerIds.get(socket2.id)!;
        const settings1 = playerKidsSettings.get(socket1.id)!;

        // Use the first player's settings (should be same age group)
        createKidsMatch(io, socket1, socket2, player1Id, player2Id, settings1);
    }
}

// Create a kids-only match with appropriate settings
function createKidsMatch(
    io: Server,
    socket1: Socket,
    socket2: Socket,
    player1Id: string,
    player2Id: string,
    kidsSettings: KidsModeSettings
): void {
    const mode = kidsSettings.letterCount as GameMode;
    const room = new Room(mode);

    // Override room settings for kids mode
    room.kidsMode = kidsSettings;

    const player1: Player = {
        id: player1Id,
        socketId: socket1.id,
        name: generateKidsName(),
        isBot: false,
    };

    const player2: Player = {
        id: player2Id,
        socketId: socket2.id,
        name: generateKidsName(),
        isBot: false,
    };

    room.addPlayer(player1);
    room.addPlayer(player2);
    rooms.set(room.id, room);
    playerRooms.set(socket1.id, room.id);
    playerRooms.set(socket2.id, room.id);

    socket1.join(room.id);
    socket2.join(room.id);

    // Send match found to both
    send(socket1, {
        type: 'matchFound',
        roomId: room.id,
        opponent: { name: player2.name, isBot: false },
        mode,
    });

    send(socket2, {
        type: 'matchFound',
        roomId: room.id,
        opponent: { name: player1.name, isBot: false },
        mode,
    });

    if (DEBUG) console.log(`Kids match created: ${room.id} [${kidsSettings.ageGroup}]`);

    // Start first round after short delay
    setTimeout(() => {
        startRound(io, room);
    }, 1500);
}

// Generate kid-friendly anonymous names
function generateKidsName(): string {
    const adjectives = ['Happy', 'Brave', 'Clever', 'Quick', 'Bright', 'Cool', 'Swift', 'Lucky'];
    const animals = ['Panda', 'Tiger', 'Eagle', 'Dolphin', 'Fox', 'Owl', 'Wolf', 'Bear'];
    const adj = adjectives[Math.floor(Math.random() * adjectives.length)];
    const animal = animals[Math.floor(Math.random() * animals.length)];
    return `${adj}${animal}`;
}

function addToQueue(io: Server, socket: Socket, playerId: string, mode: GameMode): void {
    const queue = pvpQueues.get(mode)!;

    // Check if already in queue
    if (queue.some(s => s.id === socket.id)) {
        send(socket, { type: 'queued', mode });
        return;
    }

    queue.push(socket);
    send(socket, { type: 'queued', mode });

    // Try to match
    if (queue.length >= 2) {
        const socket1 = queue.shift()!;
        const socket2 = queue.shift()!;

        const player1Id = playerIds.get(socket1.id)!;
        const player2Id = playerIds.get(socket2.id)!;

        createPvpMatch(io, socket1, socket2, player1Id, player2Id, mode);
    }
}

function createPvpMatch(
    io: Server,
    socket1: Socket,
    socket2: Socket,
    player1Id: string,
    player2Id: string,
    mode: GameMode
): void {
    const room = new Room(mode);

    const p1: Player = {
        id: player1Id,
        socketId: socket1.id,
        name: generateRandomName(),
        isBot: false,
    };

    const p2: Player = {
        id: player2Id,
        socketId: socket2.id,
        name: generateRandomName(),
        isBot: false,
    };

    room.addPlayer(p1);
    room.addPlayer(p2);

    rooms.set(room.id, room);
    playerRooms.set(socket1.id, room.id);
    playerRooms.set(socket2.id, room.id);

    // Join socket.io room
    socket1.join(room.id);
    socket2.join(room.id);

    // Notify players
    send(socket1, {
        type: 'matchFound',
        roomId: room.id,
        opponent: { name: p2.name, isBot: false },
        mode,
    });

    send(socket2, {
        type: 'matchFound',
        roomId: room.id,
        opponent: { name: p1.name, isBot: false },
        mode,
    });

    // Start first round after short delay
    setTimeout(() => startRound(io, room), 1500);
}

function createBotMatch(
    io: Server,
    socket: Socket,
    playerId: string,
    mode: GameMode,
    difficulty: BotDifficulty,
    kidsSettings?: KidsModeSettings
): void {
    const room = new Room(mode);
    const bot = new BotPlayer(difficulty);

    // Apply kids mode settings if provided
    if (kidsSettings?.kidsMode) {
        room.kidsMode = kidsSettings;
    }

    // B1 Fix: Generate names once and reuse
    const isKids = kidsSettings?.kidsMode;
    const playerDisplayName = isKids ? generateKidsName() : generateRandomName();
    const botDisplayName = isKids ? generateKidsName() : bot.name;

    const player: Player = {
        id: playerId,
        socketId: socket.id,
        name: playerDisplayName,
        isBot: false,
    };

    room.addPlayer(player);
    room.addPlayer(bot.toPlayer());

    rooms.set(room.id, room);
    playerRooms.set(socket.id, room.id);

    // Store bot reference on room for later
    (room as any).bot = bot;

    socket.join(room.id);

    send(socket, {
        type: 'matchFound',
        roomId: room.id,
        opponent: { name: botDisplayName, isBot: true },
        mode,
    });

    // Start first round
    setTimeout(() => startRound(io, room), 1500);
}

function startRound(io: Server, room: Room): void {
    const DELAY_MS = 3000; // 3 second countdown
    const round = room.startRound((r) => onRoundEnd(io, r), DELAY_MS);

    // Notify all players
    for (const player of room.players) {
        if (player.isBot) continue;

        const socket = io.sockets.sockets.get(player.socketId);
        if (socket) {
            send(socket, {
                type: 'roundStart',
                round: round.round,
                letters: round.letters,
                bonuses: round.bonuses,
                endsAt: round.endsAt,
                durationMs: (room.kidsMode?.timerSeconds ?? config.modes[room.mode].timer) * 1000,
                delayMs: DELAY_MS,
            });
        }
    }

    // Schedule bot submission if applicable
    const bot = (room as any).bot as BotPlayer | undefined;
    if (bot) {
        // B4 Fix: Store timeout ID for cleanup
        const botTimeout = bot.scheduleSubmission(room, (word) => {
            room.submitWord(bot.id, word);

            // Notify human player that opponent submitted
            for (const player of room.players) {
                if (!player.isBot) {
                    const socket = io.sockets.sockets.get(player.socketId);
                    if (socket && !room.currentRound?.submissions.has(player.id)) {
                        send(socket, { type: 'opponentSubmitted' });
                    }
                }
            }
        });
        if (botTimeout) {
            (room as any).botTimeout = botTimeout;
        }
    }
}

function onRoundEnd(io: Server, room: Room): void {
    const isMatchFinished = room.status === 'finished';
    const INTER_ROUND_DELAY = 7000;
    const nextRoundStartsAt = isMatchFinished ? undefined : Date.now() + INTER_ROUND_DELAY;

    // Send round results to all players
    for (const player of room.players) {
        if (player.isBot) continue;

        const socket = io.sockets.sockets.get(player.socketId);
        if (!socket) continue;

        const result = room.getRoundResult(player.id, nextRoundStartsAt);
        if (result) {
            send(socket, result);
        }
    }

    // Check if match is over
    if (isMatchFinished) {
        setTimeout(() => {
            for (const player of room.players) {
                if (player.isBot) continue;

                const socket = io.sockets.sockets.get(player.socketId);
                if (!socket) continue;

                const matchResult = room.getMatchResult(player.id);
                if (matchResult) {
                    send(socket, {
                        type: 'matchResult',
                        yourTotalScore: matchResult.yourTotalScore,
                        oppTotalScore: matchResult.oppTotalScore,
                        winner: matchResult.winner,
                    });
                }
            }

            // Clean up room
            cleanupRoom(room);
        }, 2000);
    } else {
        // Start next round after delay
        setTimeout(() => startRound(io, room), INTER_ROUND_DELAY);
    }
}

function handleSubmitWord(io: Server, socket: Socket, word: string): void {
    if (DEBUG) console.log(`handleSubmitWord called for socket ${socket.id} with word "${word}"`);

    const roomId = playerRooms.get(socket.id);
    if (!roomId) {
        if (DEBUG) console.log(`No roomId for socket ${socket.id}`);
        send(socket, { type: 'error', message: 'Not in a match' });
        return;
    }

    const room = rooms.get(roomId);
    if (!room || !room.currentRound) {
        if (DEBUG) console.log(`No room or no current round for roomId ${roomId}`);
        send(socket, { type: 'error', message: 'No active round' });
        return;
    }

    const playerId = playerIds.get(socket.id);
    if (!playerId) {
        if (DEBUG) console.log(`No playerId for socket ${socket.id}`);
        return;
    }

    if (DEBUG) console.log(`Calling room.submitWord for player ${playerId} with word "${word}"`);

    const submission = room.submitWord(playerId, word);
    if (!submission) {
        if (DEBUG) console.log(`Submission failed (already submitted) for player ${playerId}`);
        send(socket, { type: 'error', message: 'Already submitted' });
        return;
    }

    if (DEBUG) console.log(`Submission result: valid=${submission.valid}, score=${submission.score}`);

    // Notify opponent that this player submitted
    const opponent = room.getOpponent(playerId);
    if (opponent && !opponent.isBot) {
        const oppSocket = io.sockets.sockets.get(opponent.socketId);
        if (oppSocket) {
            send(oppSocket, { type: 'opponentSubmitted' });
        }
    }
}

function handleLeave(io: Server, socket: Socket): void {
    // Remove from regular queues
    for (const queue of pvpQueues.values()) {
        const idx = queue.findIndex(s => s.id === socket.id);
        if (idx !== -1) queue.splice(idx, 1);
    }

    // Remove from kids queues
    for (const queue of kidsQueues.values()) {
        const idx = queue.findIndex(s => s.id === socket.id);
        if (idx !== -1) queue.splice(idx, 1);
    }

    // Clear kids settings
    playerKidsSettings.delete(socket.id);

    // Handle room cleanup
    const roomId = playerRooms.get(socket.id);
    if (roomId) {
        const room = rooms.get(roomId);
        if (room) {
            // Notify opponent about disconnect/forfeit
            for (const player of room.players) {
                if (player.socketId !== socket.id && !player.isBot) {
                    const oppSocket = io.sockets.sockets.get(player.socketId);
                    if (oppSocket) {
                        send(oppSocket, {
                            type: 'matchResult',
                            yourTotalScore: room.totalScores.get(player.id) || 0,
                            oppTotalScore: 0,
                            winner: 'you',
                        });
                    }
                }
            }
            // Mark as finished, opponent wins by forfeit
            room.status = 'finished';
            cleanupRoom(room);
        }
    }
}

function handleDisconnect(io: Server, socket: Socket): void {
    if (DEBUG) console.log(`Client disconnected: ${socket.id}`);
    handleLeave(io, socket);
    playerIds.delete(socket.id);
    playerRooms.delete(socket.id);
}

function cleanupRoom(room: Room): void {
    // Clear bot timeout if exists
    if ((room as any).botTimeout) {
        clearTimeout((room as any).botTimeout);
    }

    room.destroy();
    rooms.delete(room.id);

    for (const player of room.players) {
        if (!player.isBot) {
            playerRooms.delete(player.socketId);
        }
    }
}

function send(socket: Socket, msg: ServerMessage): void {
    if (DEBUG) console.log('Sending message to client:', msg.type, socket.id);
    socket.emit('message', msg);
}

// Daily Challenge Handlers
async function handleGetDailyChallenge(socket: Socket): Promise<void> {
    try {
        const challenge = await getOrCreateTodaysChallenge();
        send(socket, {
            type: 'dailyChallenge',
            id: challenge.id,
            date: challenge.date,
            mode: challenge.mode,
            letters: challenge.letters,
            bonuses: challenge.bonuses.map(b => ({ index: b.index, type: b.type as 'DL' | 'TL' | 'DW' })),
        });
    } catch (error) {
        console.error('Error getting daily challenge:', error);
        send(socket, { type: 'error', message: 'Failed to get daily challenge' });
    }
}

async function handleSubmitDailyWord(socket: Socket, word: string): Promise<void> {
    try {
        const playerId = playerIds.get(socket.id);
        if (!playerId) {
            send(socket, { type: 'error', message: 'Not identified' });
            return;
        }

        const challenge = await getOrCreateTodaysChallenge();

        // Validate the word
        const validation = validator.validate(word, challenge.letters);
        if (!validation.valid) {
            send(socket, {
                type: 'dailyResult',
                word: '',
                score: 0,
                isNewBest: false,
                rank: 0,
            });
            return;
        }

        // Calculate score - cast bonus types
        const bonusTiles = challenge.bonuses.map(b => ({
            index: b.index,
            type: b.type as 'DL' | 'TL' | 'DW'
        }));
        const score = scorer.calculate(word, challenge.letters, bonusTiles);

        // Submit score and get result
        const result = await submitDailyScore(challenge.id, playerId, word, score);

        send(socket, {
            type: 'dailyResult',
            word: word.toUpperCase(),
            score,
            isNewBest: result.isNewBest,
            rank: result.rank,
        });
    } catch (error) {
        console.error('Error submitting daily word:', error);
        send(socket, { type: 'error', message: 'Failed to submit word' });
    }
}

async function handleGetDailyLeaderboard(socket: Socket): Promise<void> {
    try {
        const challenge = await getOrCreateTodaysChallenge();
        const entries = await getDailyLeaderboard(challenge.id, 50);

        send(socket, {
            type: 'dailyLeaderboard',
            challengeId: challenge.id,
            entries: entries.map((e, i) => ({
                rank: i + 1,
                displayName: e.displayName,
                bestWord: e.bestWord,
                score: e.score,
            })),
        });
    } catch (error) {
        console.error('Error getting leaderboard:', error);
        send(socket, { type: 'error', message: 'Failed to get leaderboard' });
    }
}
