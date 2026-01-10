import { drizzle } from 'drizzle-orm/node-postgres';
import { pgTable, uuid, text, integer, timestamp, date, unique } from 'drizzle-orm/pg-core';
import { sql } from 'drizzle-orm';
import pg from 'pg';
import { config } from '../config.js';

// ============================================
// Schema Definitions
// ============================================

// Players table (anonymous, identified by device ID)
export const players = pgTable('players', {
    id: uuid('id').primaryKey().default(sql`gen_random_uuid()`),
    deviceId: text('device_id').notNull().unique(),
    displayName: text('display_name'),
    createdAt: timestamp('created_at').defaultNow(),
});

// Match history
export const matches = pgTable('matches', {
    id: uuid('id').primaryKey().default(sql`gen_random_uuid()`),
    mode: integer('mode').notNull(),
    player1Id: uuid('player1_id').references(() => players.id),
    player2Id: uuid('player2_id').references(() => players.id), // null if bot
    player1Wins: integer('player1_wins').notNull(),
    player2Wins: integer('player2_wins').notNull(),
    winnerId: uuid('winner_id').references(() => players.id),
    playedAt: timestamp('played_at').defaultNow(),
});

// Daily challenges
export const dailyChallenges = pgTable('daily_challenges', {
    id: uuid('id').primaryKey().default(sql`gen_random_uuid()`),
    date: date('date').notNull().unique(),
    seed: text('seed').notNull(),
    mode: integer('mode').default(8),
    letters: text('letters').notNull(), // JSON array of letters
    bonuses: text('bonuses').notNull(), // JSON array of bonuses
});

// Daily challenge scores
export const dailyScores = pgTable('daily_scores', {
    id: uuid('id').primaryKey().default(sql`gen_random_uuid()`),
    challengeId: uuid('challenge_id').references(() => dailyChallenges.id),
    playerId: uuid('player_id').references(() => players.id),
    bestWord: text('best_word').notNull(),
    score: integer('score').notNull(),
    submittedAt: timestamp('submitted_at').defaultNow(),
}, (t) => ({
    uniquePlayerChallenge: unique().on(t.challengeId, t.playerId),
}));

// Player stats (aggregated)
export const playerStats = pgTable('player_stats', {
    playerId: uuid('player_id').primaryKey().references(() => players.id),
    totalMatches: integer('total_matches').default(0),
    wins: integer('wins').default(0),
    losses: integer('losses').default(0),
    bestWord: text('best_word'),
    bestScore: integer('best_score').default(0),
    currentStreak: integer('current_streak').default(0),
    longestStreak: integer('longest_streak').default(0),
    lastPlayedAt: timestamp('last_played_at'),
});

// ============================================
// Database Client
// ============================================

let pool: pg.Pool | null = null;
let db: ReturnType<typeof drizzle> | null = null;

export function getDb() {
    if (!db) {
        pool = new pg.Pool({
            connectionString: config.databaseUrl,
            max: 10,
        });

        pool.on('error', (err) => {
            console.error('PostgreSQL pool error:', err);
        });

        db = drizzle(pool);
        console.log('Connected to PostgreSQL');
    }
    return db;
}

export async function closeDb(): Promise<void> {
    if (pool) {
        await pool.end();
        pool = null;
        db = null;
    }
}

// ============================================
// Helper Functions
// ============================================

export async function getOrCreatePlayer(deviceId: string, displayName?: string) {
    const database = getDb();

    // Try to find existing player
    const [existing] = await database
        .select()
        .from(players)
        .where(sql`${players.deviceId} = ${deviceId}`)
        .limit(1);

    if (existing) return existing;

    // Create new player
    const [newPlayer] = await database
        .insert(players)
        .values({ deviceId, displayName })
        .returning();

    // Initialize stats
    await database
        .insert(playerStats)
        .values({ playerId: newPlayer.id });

    return newPlayer;
}

export async function recordMatch(
    mode: number,
    player1Id: string,
    player2Id: string | null,
    player1Wins: number,
    player2Wins: number,
    winnerId: string | null
) {
    const database = getDb();

    await database.insert(matches).values({
        mode,
        player1Id,
        player2Id,
        player1Wins,
        player2Wins,
        winnerId,
    });

    // Update player stats
    if (player1Id) {
        await database.execute(sql`
      UPDATE player_stats 
      SET 
        total_matches = total_matches + 1,
        wins = wins + ${winnerId === player1Id ? 1 : 0},
        losses = losses + ${winnerId !== player1Id && winnerId !== null ? 1 : 0},
        last_played_at = NOW()
      WHERE player_id = ${player1Id}
    `);
    }
}

export async function getLeaderboard(limit = 20) {
    const database = getDb();

    return database
        .select({
            playerId: playerStats.playerId,
            displayName: players.displayName,
            wins: playerStats.wins,
            totalMatches: playerStats.totalMatches,
            bestScore: playerStats.bestScore,
        })
        .from(playerStats)
        .innerJoin(players, sql`${players.id} = ${playerStats.playerId}`)
        .orderBy(sql`${playerStats.wins} DESC`)
        .limit(limit);
}

export async function getTodaysChallenge() {
    const database = getDb();
    const today = new Date().toISOString().split('T')[0];

    const [challenge] = await database
        .select()
        .from(dailyChallenges)
        .where(sql`${dailyChallenges.date} = ${today}`)
        .limit(1);

    return challenge;
}

export async function submitDailyScore(
    challengeId: string,
    playerId: string,
    word: string,
    score: number
) {
    const database = getDb();

    // Upsert - only update if new score is higher
    await database.execute(sql`
    INSERT INTO daily_scores (challenge_id, player_id, best_word, score)
    VALUES (${challengeId}, ${playerId}, ${word}, ${score})
    ON CONFLICT (challenge_id, player_id)
    DO UPDATE SET
      best_word = CASE WHEN ${score} > daily_scores.score THEN ${word} ELSE daily_scores.best_word END,
      score = GREATEST(daily_scores.score, ${score})
  `);
}

export async function getDailyChallengeLeaderboard(challengeId: string, limit = 50) {
    const database = getDb();

    return database
        .select({
            playerId: dailyScores.playerId,
            displayName: players.displayName,
            bestWord: dailyScores.bestWord,
            score: dailyScores.score,
        })
        .from(dailyScores)
        .innerJoin(players, sql`${players.id} = ${dailyScores.playerId}`)
        .where(sql`${dailyScores.challengeId} = ${challengeId}`)
        .orderBy(sql`${dailyScores.score} DESC`)
        .limit(limit);
}
