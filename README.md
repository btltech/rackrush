# RackRush

Real-time 1v1 word duel game. Build the best word from your rack before time runs out!

![RackRush](https://img.shields.io/badge/status-in%20development-yellow)
![Platform](https://img.shields.io/badge/platform-iOS%20%7C%20Android-blue)
![Backend](https://img.shields.io/badge/backend-Railway-purple)

---

## 🎮 Game Overview

**RackRush** is a fast-paced word game where two players compete in real-time. Each round, both players receive the same rack of letters and race to form the highest-scoring word before the timer ends.

### Core Loop
1. **Match starts** — You're paired with an opponent (or bot)
2. **Round begins** — You receive a rack of letters + bonus tiles
3. **Build a word** — Tap letters to form your best word
4. **Submit** — Lock in your word before time runs out
5. **Score** — Server validates and scores both submissions
6. **Winner** — Higher score wins the round
7. **Best of 5** — First to 3 round wins takes the match

---

## 🎯 Game Modes

| Mode | Letters | Timer | Difficulty | Target |
|------|:-------:|:-----:|------------|--------|
| **Quick** | 7 | 25s | ⭐ | Beginners, casual players |
| **Standard** | 8 | 30s | ⭐⭐ | Most players (default) |
| **Classic** | 9 | 35s | ⭐⭐⭐ | Competitive players |
| **Master** | 10 | 45s | ⭐⭐⭐⭐ | Word game experts |

---

## 📊 Scoring System

### Letter Values
```
1 pt:  E, A, I, O, N, R, T, L, S, U
2 pt:  D, G
3 pt:  B, C, M, P
4 pt:  F, H, V, W, Y
5 pt:  K
8 pt:  J, X
10 pt: Q, Z
```

### Bonus Tiles
- **DL** (Double Letter) — 2× letter value
- **TL** (Triple Letter) — 3× letter value
- **DW** (Double Word) — 2× total word score

### Length Bonuses
| Word Length | Bonus |
|:-----------:|:-----:|
| 6 letters | +2 |
| 7 letters | +5 |
| 8 letters | +8 |
| 9+ letters | +12 |

---

## 🏗 Project Structure

```
rackrush/
├── README.md
│
├── server/                    # Node.js + Socket.IO backend
│   ├── src/
│   │   ├── index.ts           # Entry point
│   │   ├── config.ts          # Game settings & timers
│   │   ├── socket/
│   │   │   ├── handlers.ts    # WebSocket message handlers
│   │   │   └── protocol.ts    # Message type definitions
│   │   ├── game/
│   │   │   ├── Room.ts        # Match & round management
│   │   │   ├── RackGenerator.ts # Fair letter distribution
│   │   │   ├── Scorer.ts      # Word scoring logic
│   │   │   └── Validator.ts   # Dictionary + rack validation
│   │   ├── bot/
│   │   │   └── BotPlayer.ts   # AI opponent (3 difficulties)
│   │   └── dictionary/
│   │       └── Dictionary.ts  # ENABLE word list loader
│   ├── data/
│   │   ├── enable.txt         # ENABLE word list (~173k words)
│   │   └── blocklist.txt      # Profanity filter
│   ├── package.json
│   ├── tsconfig.json
│   └── railway.json           # Railway deployment config
│
└── client/                    # Flutter app (iOS + Android)
    ├── lib/
    │   ├── main.dart          # App entry point
    │   ├── theme/
    │   │   └── app_theme.dart # Premium dark theme
    │   ├── services/
    │   │   ├── socket_service.dart # WebSocket connection
    │   │   └── game_state.dart     # Match state management
    │   ├── screens/
    │   │   ├── home_screen.dart
    │   │   ├── mode_select_screen.dart
    │   │   └── match_screen.dart
    │   └── widgets/
    │       ├── letter_tile.dart
    │       └── timer_bar.dart
    ├── pubspec.yaml
    └── analysis_options.yaml
```

---

## 🚀 Getting Started

### Backend Setup

```bash
cd server

# Install dependencies
npm install

# Download ENABLE word list (one-time)
curl -o data/enable.txt https://raw.githubusercontent.com/dolph/dictionary/master/enable1.txt

# Run development server
npm run dev

# Build for production
npm run build
npm run start
```

The server runs on `http://localhost:3000` by default.

### Flutter Client Setup

```bash
cd client

# Get dependencies
flutter pub get

# Run on iOS simulator
flutter run -d ios

# Run on Android emulator
flutter run -d android
```

Update the server URL in `lib/services/socket_service.dart`:
```dart
static const String _devUrl = 'http://localhost:3000';
static const String _prodUrl = 'wss://your-app.up.railway.app';
```

---

## 🌐 Deploy to Railway

### 1. Prepare Repository
```bash
git init
git add .
git commit -m "Initial commit"
git remote add origin https://github.com/yourusername/rackrush.git
git push -u origin main
```

### 2. Create Railway Project
1. Go to [railway.app](https://railway.app)
2. Click "New Project" → "Deploy from GitHub repo"
3. Select your repository

### 3. Add Services
- **Redis** — Click "New" → "Database" → "Redis"
- **PostgreSQL** — Click "New" → "Database" → "PostgreSQL"

### 4. Configure Environment
Railway auto-injects these variables:
- `PORT` — Server port (auto-assigned)
- `REDIS_URL` — Redis connection string
- `DATABASE_URL` — PostgreSQL connection string

### 5. Deploy
Push to main branch — Railway deploys automatically.

---

## 📡 WebSocket Protocol

### Client → Server

| Message | Fields | Description |
|---------|--------|-------------|
| `hello` | `version`, `deviceId` | Identify client on connect |
| `queue` | `mode`, `matchType`, `botDifficulty?` | Join matchmaking queue |
| `submitWord` | `word` | Submit word for current round |
| `leave` | — | Leave current match/queue |
| `ping` | — | Keepalive heartbeat |

### Server → Client

| Message | Fields | Description |
|---------|--------|-------------|
| `queued` | `mode` | Confirmed in queue |
| `matchFound` | `roomId`, `opponent`, `mode` | Match ready to start |
| `roundStart` | `round`, `letters`, `bonuses`, `endsAt` | New round begins |
| `opponentSubmitted` | — | Opponent locked in their word |
| `roundResult` | `yourWord`, `yourScore`, `oppWord`, `oppScore`, `winner` | Round ended |
| `matchResult` | `yourWins`, `oppWins`, `winner` | Match ended |
| `pong` | — | Heartbeat response |
| `error` | `message` | Error occurred |

---

## 🤖 Bot Difficulty

| Difficulty | Word Selection | Response Time |
|------------|---------------|---------------|
| **Easy** | Bottom 30-40% of valid words | 15-22 seconds |
| **Medium** | Top 10-30% of valid words | 8-15 seconds |
| **Hard** | Top 5-10% of valid words | 4-8 seconds |

---

## 📋 Rack Generation Rules

To ensure fair, playable racks:
- ✅ Minimum 2 vowels (7-8 letters) or 3 vowels (9-10 letters)
- ✅ Maximum 1 rare letter (J, Q, X, Z)
- ✅ At least 1 common consonant (R, S, T, N, L)
- ✅ Weighted letter distribution (E appears more than Q)

---

## 🛡 Word Validation

1. **Minimum length** — 3+ letters required
2. **Buildable from rack** — Each letter used once
3. **In dictionary** — Must be in ENABLE word list
4. **Not blocked** — Profanity filtered via `blocklist.txt`

---

## 📦 Tech Stack

| Layer | Technology |
|-------|------------|
| **Client** | Flutter 3.x (iOS + Android) |
| **Backend** | Node.js + Socket.IO + TypeScript |
| **Database** | PostgreSQL (stats, leaderboards) |
| **Cache** | Redis (room state, reconnect) |
| **Dictionary** | ENABLE (~173k words) |
| **Hosting** | Railway |

---

## 📄 License

MIT License

---

## 🙏 Credits

- **ENABLE Word List** — Public domain dictionary
- **Socket.IO** — Real-time WebSocket framework
- **Railway** — Simple cloud deployment
