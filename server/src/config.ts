export const config = {
    port: parseInt(process.env.PORT || '3000', 10),
    redisUrl: process.env.REDIS_URL || 'redis://localhost:6379',
    databaseUrl: process.env.DATABASE_URL || 'postgres://localhost:5432/rackrush',

    // Game settings per mode
    modes: {
        7: { letters: 7, minVowels: 2, maxRare: 1, timer: 25 },
        8: { letters: 8, minVowels: 2, maxRare: 1, timer: 30 },
        9: { letters: 9, minVowels: 3, maxRare: 1, timer: 35 },
        10: { letters: 10, minVowels: 3, maxRare: 1, timer: 45 },
    } as const,

    // Fixed 7 rounds (Jangle-inspired)
    totalRounds: 7,

    // Bot delays (ms)
    botDelays: {
        easy: { min: 15000, max: 22000 },
        medium: { min: 8000, max: 15000 },
        hard: { min: 4000, max: 8000 },
    },

    // WebSocket heartbeat
    pingInterval: 25000,
    pingTimeout: 10000,
};
