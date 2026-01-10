import { Server, Socket } from 'socket.io';
import { v4 as uuidv4 } from 'uuid';
import {
    ClientMessage,
    ServerMessage,
    GameMode,
    MatchType,
    BotDifficulty,
} from './protocol.js';
import { Room, Player } from '../game/Room.js';
import { BotPlayer, generateRandomName } from '../bot/BotPlayer.js';
import { config } from '../config.js';

// Store for active rooms and queues
const rooms = new Map<string, Room>();
const playerRooms = new Map<string, string>();  // socketId -> roomId
const playerIds = new Map<string, string>();    // socketId -> playerId

// Queue structure: mode -> array of waiting sockets
const pvpQueues = new Map<GameMode, Socket[]>();
for (const mode of [7, 8, 9, 10] as GameMode[]) {
    pvpQueues.set(mode, []);
}

export function setupHandlers(io: Server): void {
    io.on('connection', (socket: Socket) => {
        console.log(`Client connected: ${socket.id}`);

        socket.on('message', (data: ClientMessage) => {
            handleMessage(io, socket, data);
        });

        socket.on('disconnect', () => {
            handleDisconnect(io, socket);
        });
    });
}

function handleMessage(io: Server, socket: Socket, msg: ClientMessage): void {
    switch (msg.type) {
        case 'hello':
            handleHello(socket, msg.deviceId);
            break;

        case 'queue':
            handleQueue(io, socket, msg.mode, msg.matchType, msg.botDifficulty);
            break;

        case 'submitWord':
            handleSubmitWord(io, socket, msg.word);
            break;

        case 'ping':
            send(socket, { type: 'pong' });
            break;

        case 'leave':
            handleLeave(io, socket);
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
    console.log(`Player ${playerId} identified (device: ${deviceId})`);
}

function handleQueue(
    io: Server,
    socket: Socket,
    mode: GameMode,
    matchType: MatchType,
    botDifficulty?: BotDifficulty
): void {
    const playerId = playerIds.get(socket.id) || `player-${uuidv4()}`;
    playerIds.set(socket.id, playerId);

    if (matchType === 'bot') {
        // Create room with bot immediately
        createBotMatch(io, socket, playerId, mode, botDifficulty || 'medium');
    } else {
        // Add to PvP queue
        addToQueue(io, socket, playerId, mode);
    }
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
    difficulty: BotDifficulty
): void {
    const room = new Room(mode);
    const bot = new BotPlayer(difficulty);

    const player: Player = {
        id: playerId,
        socketId: socket.id,
        name: generateRandomName(),
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
        opponent: { name: bot.name, isBot: true },
        mode,
    });

    // Start first round
    setTimeout(() => startRound(io, room), 1500);
}

function startRound(io: Server, room: Room): void {
    const round = room.startRound((r) => onRoundEnd(io, r));

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
            });
        }
    }

    // Schedule bot submission if applicable
    const bot = (room as any).bot as BotPlayer | undefined;
    if (bot) {
        bot.scheduleSubmission(room, (word) => {
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
    }
}

function onRoundEnd(io: Server, room: Room): void {
    // Send round results to all players
    for (const player of room.players) {
        if (player.isBot) continue;

        const socket = io.sockets.sockets.get(player.socketId);
        if (!socket) continue;

        const result = room.getRoundResult(player.id);
        if (result) {
            send(socket, result);
        }
    }

    // Check if match is over
    if (room.status === 'finished') {
        setTimeout(() => {
            for (const player of room.players) {
                if (player.isBot) continue;

                const socket = io.sockets.sockets.get(player.socketId);
                if (!socket) continue;

                const matchResult = room.getMatchResult(player.id);
                if (matchResult) {
                    send(socket, {
                        type: 'matchResult',
                        yourWins: matchResult.yourWins,
                        oppWins: matchResult.oppWins,
                        winner: matchResult.winner,
                    });
                }
            }

            // Clean up room
            cleanupRoom(room);
        }, 2000);
    } else {
        // Start next round after delay
        setTimeout(() => startRound(io, room), 3000);
    }
}

function handleSubmitWord(io: Server, socket: Socket, word: string): void {
    const roomId = playerRooms.get(socket.id);
    if (!roomId) {
        send(socket, { type: 'error', message: 'Not in a match' });
        return;
    }

    const room = rooms.get(roomId);
    if (!room || !room.currentRound) {
        send(socket, { type: 'error', message: 'No active round' });
        return;
    }

    const playerId = playerIds.get(socket.id);
    if (!playerId) return;

    const submission = room.submitWord(playerId, word);
    if (!submission) {
        send(socket, { type: 'error', message: 'Already submitted' });
        return;
    }

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
    // Remove from queues
    for (const queue of pvpQueues.values()) {
        const idx = queue.findIndex(s => s.id === socket.id);
        if (idx !== -1) queue.splice(idx, 1);
    }

    // Handle room cleanup
    const roomId = playerRooms.get(socket.id);
    if (roomId) {
        const room = rooms.get(roomId);
        if (room) {
            // Mark as finished, opponent wins by forfeit
            room.status = 'finished';
            cleanupRoom(room);
        }
    }
}

function handleDisconnect(io: Server, socket: Socket): void {
    console.log(`Client disconnected: ${socket.id}`);
    handleLeave(io, socket);
    playerIds.delete(socket.id);
    playerRooms.delete(socket.id);
}

function cleanupRoom(room: Room): void {
    room.destroy();
    rooms.delete(room.id);

    for (const player of room.players) {
        if (!player.isBot) {
            playerRooms.delete(player.socketId);
        }
    }
}

function send(socket: Socket, msg: ServerMessage): void {
    socket.emit('message', msg);
}
