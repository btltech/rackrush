-- RackRush Database Schema
-- Run this on your PostgreSQL database

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Players table (anonymous, identified by device ID)
CREATE TABLE IF NOT EXISTS players (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  device_id TEXT UNIQUE NOT NULL,
  display_name TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Player stats (aggregated)
CREATE TABLE IF NOT EXISTS player_stats (
  player_id UUID PRIMARY KEY REFERENCES players(id),
  total_matches INT DEFAULT 0,
  wins INT DEFAULT 0,
  losses INT DEFAULT 0,
  best_word TEXT,
  best_score INT DEFAULT 0,
  current_streak INT DEFAULT 0,
  longest_streak INT DEFAULT 0,
  last_played_at TIMESTAMPTZ
);

-- Match history
CREATE TABLE IF NOT EXISTS matches (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  mode INT NOT NULL,
  player1_id UUID REFERENCES players(id),
  player2_id UUID REFERENCES players(id),  -- NULL if bot
  player1_wins INT NOT NULL,
  player2_wins INT NOT NULL,
  winner_id UUID REFERENCES players(id),
  played_at TIMESTAMPTZ DEFAULT NOW()
);

-- Daily challenges
CREATE TABLE IF NOT EXISTS daily_challenges (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  date DATE UNIQUE NOT NULL,
  seed TEXT NOT NULL,
  mode INT DEFAULT 8,
  letters TEXT NOT NULL,   -- JSON array
  bonuses TEXT NOT NULL    -- JSON array
);

-- Daily challenge scores
CREATE TABLE IF NOT EXISTS daily_scores (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  challenge_id UUID REFERENCES daily_challenges(id),
  player_id UUID REFERENCES players(id),
  best_word TEXT NOT NULL,
  score INT NOT NULL,
  submitted_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(challenge_id, player_id)
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_matches_player1 ON matches(player1_id);
CREATE INDEX IF NOT EXISTS idx_matches_player2 ON matches(player2_id);
CREATE INDEX IF NOT EXISTS idx_matches_played_at ON matches(played_at);
CREATE INDEX IF NOT EXISTS idx_daily_scores_challenge ON daily_scores(challenge_id);
CREATE INDEX IF NOT EXISTS idx_daily_scores_score ON daily_scores(score DESC);
CREATE INDEX IF NOT EXISTS idx_player_stats_wins ON player_stats(wins DESC);
