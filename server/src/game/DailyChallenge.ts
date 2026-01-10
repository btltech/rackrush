import { v4 as uuidv4 } from 'uuid';
import { rackGenerator } from '../game/RackGenerator.js';
import { getDb, dailyChallenges, dailyScores, players } from '../db/postgres.js';
import { sql } from 'drizzle-orm';
import { GameMode } from '../socket/protocol.js';

// Generate seed from date for deterministic rack
function dateSeed(date: Date): string {
    return `rackrush-${date.toISOString().split('T')[0]}`;
}

// Seeded random number generator
function seededRandom(seed: string): () => number {
    let h = 0;
    for (let i = 0; i < seed.length; i++) {
        h = Math.imul(31, h) + seed.charCodeAt(i) | 0;
    }
    return () => {
        h = Math.imul(h ^ (h >>> 15), h | 1);
        h ^= h + Math.imul(h ^ (h >>> 7), h | 61);
        return ((h ^ (h >>> 14)) >>> 0) / 4294967296;
    };
}

export interface DailyChallenge {
    id: string;
    date: string;
    mode: GameMode;
    letters: string[];
    bonuses: { index: number; type: string }[];
}

export async function getOrCreateTodaysChallenge(): Promise<DailyChallenge> {
    const db = getDb();
    const today = new Date().toISOString().split('T')[0];

    // Check if today's challenge exists
    const [existing] = await db
        .select()
        .from(dailyChallenges)
        .where(sql`${dailyChallenges.date} = ${today}`)
        .limit(1);

    if (existing) {
        return {
            id: existing.id,
            date: existing.date as string,
            mode: (existing.mode || 8) as GameMode,
            letters: JSON.parse(existing.letters),
            bonuses: JSON.parse(existing.bonuses),
        };
    }

    // Generate new challenge
    const seed = dateSeed(new Date());
    const mode: GameMode = 8; // Standard mode for daily

    // Use seeded random to generate deterministic rack
    const random = seededRandom(seed);

    // Generate rack (we'll use the rack generator but with fixed seed)
    const { letters, bonuses } = rackGenerator.generate(mode);

    // Insert into database
    const [newChallenge] = await db
        .insert(dailyChallenges)
        .values({
            date: today,
            seed,
            mode,
            letters: JSON.stringify(letters),
            bonuses: JSON.stringify(bonuses),
        })
        .returning();

    return {
        id: newChallenge.id,
        date: newChallenge.date as string,
        mode: mode,
        letters,
        bonuses,
    };
}

export interface DailyScore {
    playerId: string;
    displayName: string | null;
    bestWord: string;
    score: number;
    rank: number;
}

export async function getDailyLeaderboard(challengeId: string, limit = 50): Promise<DailyScore[]> {
    const db = getDb();

    const results = await db
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

    return results.map((r, i) => ({
        playerId: r.playerId!,
        displayName: r.displayName,
        bestWord: r.bestWord,
        score: r.score,
        rank: i + 1,
    }));
}

export async function submitDailyScore(
    challengeId: string,
    playerId: string,
    word: string,
    score: number
): Promise<{ isNewBest: boolean; rank: number }> {
    const db = getDb();

    // Check existing score
    const [existing] = await db
        .select()
        .from(dailyScores)
        .where(sql`${dailyScores.challengeId} = ${challengeId} AND ${dailyScores.playerId} = ${playerId}`)
        .limit(1);

    let isNewBest = false;

    if (existing) {
        if (score > existing.score) {
            // Update with new best
            await db.execute(sql`
        UPDATE daily_scores 
        SET best_word = ${word}, score = ${score}, submitted_at = NOW()
        WHERE challenge_id = ${challengeId} AND player_id = ${playerId}
      `);
            isNewBest = true;
        }
    } else {
        // Insert new score
        await db.insert(dailyScores).values({
            challengeId,
            playerId,
            bestWord: word,
            score,
        });
        isNewBest = true;
    }

    // Get rank
    const [rankResult] = await db.execute<{ rank: number }>(sql`
    SELECT COUNT(*) + 1 as rank 
    FROM daily_scores 
    WHERE challenge_id = ${challengeId} AND score > ${score}
  `);

    return {
        isNewBest,
        rank: (rankResult as any)?.rank || 1,
    };
}
