import { Redis } from 'ioredis';
import { config } from '../config.js';

// Redis client singleton
let redis: Redis | null = null;

export function getRedis(): Redis {
    if (!redis) {
        redis = new Redis(config.redisUrl, {
            maxRetriesPerRequest: 3,
            retryStrategy: (times) => Math.min(times * 100, 3000),
            enableReadyCheck: true,
        });

        redis.on('error', (err) => {
            console.error('Redis error:', err);
        });

        redis.on('connect', () => {
            console.log('Connected to Redis');
        });
    }
    return redis;
}

// Room state helpers
const ROOM_PREFIX = 'room:';
const PLAYER_ROOM_PREFIX = 'player_room:';
const ROOM_TTL = 3600; // 1 hour

export interface RoomState {
    id: string;
    mode: number;
    status: string;
    players: Array<{
        id: string;
        socketId: string;
        name: string;
        isBot: boolean;
    }>;
    wins: Record<string, number>;
    currentRound: number;
    letters: string[];
    bonuses: Array<{ index: number; type: string }>;
    roundEndsAt: number;
    submissions: Record<string, {
        word: string;
        score: number;
        submittedAt: number;
    }>;
}

export async function saveRoomState(room: RoomState): Promise<void> {
    const r = getRedis();
    const key = ROOM_PREFIX + room.id;
    await r.set(key, JSON.stringify(room), 'EX', ROOM_TTL);

    // Map players to room
    for (const player of room.players) {
        if (!player.isBot) {
            await r.set(PLAYER_ROOM_PREFIX + player.id, room.id, 'EX', ROOM_TTL);
        }
    }
}

export async function getRoomState(roomId: string): Promise<RoomState | null> {
    const r = getRedis();
    const data = await r.get(ROOM_PREFIX + roomId);
    if (!data) return null;
    return JSON.parse(data);
}

export async function deleteRoomState(roomId: string): Promise<void> {
    const r = getRedis();
    const room = await getRoomState(roomId);
    if (room) {
        for (const player of room.players) {
            if (!player.isBot) {
                await r.del(PLAYER_ROOM_PREFIX + player.id);
            }
        }
    }
    await r.del(ROOM_PREFIX + roomId);
}

export async function getPlayerRoomId(playerId: string): Promise<string | null> {
    const r = getRedis();
    return r.get(PLAYER_ROOM_PREFIX + playerId);
}

// Reconnect token management
const RECONNECT_PREFIX = 'reconnect:';
const RECONNECT_TTL = 300; // 5 minutes

export async function setReconnectToken(playerId: string, roomId: string): Promise<void> {
    const r = getRedis();
    await r.set(RECONNECT_PREFIX + playerId, roomId, 'EX', RECONNECT_TTL);
}

export async function getReconnectRoom(playerId: string): Promise<string | null> {
    const r = getRedis();
    return r.get(RECONNECT_PREFIX + playerId);
}

export async function clearReconnectToken(playerId: string): Promise<void> {
    const r = getRedis();
    await r.del(RECONNECT_PREFIX + playerId);
}

// Cleanup on shutdown
export async function closeRedis(): Promise<void> {
    if (redis) {
        await redis.quit();
        redis = null;
    }
}
