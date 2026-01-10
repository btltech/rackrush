import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/game_state.dart';
import '../theme/app_theme.dart';
import '../widgets/letter_tile.dart';
import '../widgets/timer_bar.dart';

class MatchScreen extends StatelessWidget {
  const MatchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GameState>(
      builder: (context, game, _) {
        switch (game.screen) {
          case GameScreen.roundResult:
            return _RoundResultView(game: game);
          case GameScreen.matchResult:
            return _MatchResultView(game: game);
          default:
            return _GameplayView(game: game);
        }
      },
    );
  }
}

class _GameplayView extends StatefulWidget {
  final GameState game;
  
  const _GameplayView({required this.game});

  @override
  State<_GameplayView> createState() => _GameplayViewState();
}

class _GameplayViewState extends State<_GameplayView> {
  Timer? _timer;
  int _remainingMs = 0;
  
  @override
  void initState() {
    super.initState();
    _startTimer();
  }
  
  @override
  void didUpdateWidget(_GameplayView old) {
    super.didUpdateWidget(old);
    if (widget.game.roundEndsAt != old.game.roundEndsAt) {
      _startTimer();
    }
  }
  
  void _startTimer() {
    _timer?.cancel();
    _remainingMs = widget.game.roundEndsAt - DateTime.now().millisecondsSinceEpoch;
    
    _timer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      setState(() {
        _remainingMs = widget.game.roundEndsAt - DateTime.now().millisecondsSinceEpoch;
        if (_remainingMs <= 0) {
          _remainingMs = 0;
          _timer?.cancel();
        }
      });
    });
  }
  
  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final game = widget.game;
    final remainingSec = (_remainingMs / 1000).ceil();
    
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.surfaceGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Back button
                    GestureDetector(
                      onTap: () => game.goHome(),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.close, size: 20),
                      ),
                    ),
                    const SizedBox(width: 16),
                    
                    // Round indicator
                    Text(
                      'Round ${game.currentRound}/5',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    
                    const Spacer(),
                    
                    // Score
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Text(
                            '${game.myWins}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.success,
                            ),
                          ),
                          const Text(
                            ' - ',
                            style: TextStyle(color: AppTheme.textSecondary),
                          ),
                          Text(
                            '${game.oppWins}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.accent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Timer bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TimerBar(
                  remainingMs: _remainingMs,
                  totalMs: game.selectedMode == 7 ? 25000
                      : game.selectedMode == 8 ? 30000
                      : game.selectedMode == 9 ? 35000
                      : 45000,
                ),
              ),
              
              const SizedBox(height: 8),
              
              // Timer text
              Text(
                '${remainingSec}s',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: remainingSec <= 5 ? AppTheme.accent : AppTheme.textPrimary,
                ),
              ),
              
              const Spacer(),
              
              // Opponent status
              if (game.opponentSubmitted && !game.submitted)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.warning.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check, size: 16, color: AppTheme.warning),
                      const SizedBox(width: 8),
                      Text(
                        '${game.opponentName} submitted!',
                        style: TextStyle(color: AppTheme.warning),
                      ),
                    ],
                  ),
                ),
              
              // Current word display
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: game.submitted
                        ? AppTheme.success
                        : AppTheme.surfaceLight,
                    width: game.submitted ? 2 : 1,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (game.currentWord.isEmpty)
                      Text(
                        'Tap letters to build a word',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppTheme.textMuted,
                        ),
                      )
                    else
                      ...game.currentWord.split('').map((letter) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: Text(
                          letter,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.secondary,
                          ),
                        ),
                      )),
                    if (game.submitted)
                      const Padding(
                        padding: EdgeInsets.only(left: 12),
                        child: Icon(Icons.check_circle, color: AppTheme.success),
                      ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Letter rack
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: List.generate(game.letters.length, (index) {
                    final letter = game.letters[index];
                    final bonus = game.bonuses
                        .where((b) => b.index == index)
                        .firstOrNull;
                    
                    // Check if letter is used
                    final usedLetters = game.currentWord.split('');
                    final availableLetters = List<String>.from(game.letters);
                    bool isUsed = false;
                    
                    for (final used in usedLetters) {
                      final idx = availableLetters.indexOf(used);
                      if (idx != -1) {
                        if (idx == index && !isUsed) {
                          isUsed = true;
                        }
                        availableLetters.removeAt(idx);
                      }
                    }
                    
                    return LetterTile(
                      letter: letter,
                      bonus: bonus?.type,
                      isUsed: isUsed,
                      onTap: game.submitted
                          ? null
                          : () {
                              HapticFeedback.lightImpact();
                              game.addLetter(letter);
                            },
                    );
                  }),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Action buttons
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    // Clear button
                    Expanded(
                      child: GestureDetector(
                        onTap: game.submitted
                            ? null
                            : () {
                                HapticFeedback.mediumImpact();
                                game.clearWord();
                              },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: AppTheme.surface,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Center(
                            child: Icon(Icons.clear, color: AppTheme.textSecondary),
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(width: 12),
                    
                    // Backspace button
                    Expanded(
                      child: GestureDetector(
                        onTap: game.submitted
                            ? null
                            : () {
                                HapticFeedback.lightImpact();
                                game.removeLetter();
                              },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: AppTheme.surface,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Center(
                            child: Icon(Icons.backspace_outlined, color: AppTheme.textSecondary),
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(width: 12),
                    
                    // Submit button
                    Expanded(
                      flex: 2,
                      child: GestureDetector(
                        onTap: game.submitted || game.currentWord.length < 3
                            ? null
                            : () {
                                HapticFeedback.heavyImpact();
                                game.submitWord();
                              },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            gradient: (game.submitted || game.currentWord.length < 3)
                                ? null
                                : AppTheme.primaryGradient,
                            color: (game.submitted || game.currentWord.length < 3)
                                ? AppTheme.surface
                                : null,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              game.submitted ? 'SUBMITTED' : 'SUBMIT',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: (game.submitted || game.currentWord.length < 3)
                                    ? AppTheme.textMuted
                                    : Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoundResultView extends StatelessWidget {
  final GameState game;
  
  const _RoundResultView({required this.game});

  @override
  Widget build(BuildContext context) {
    final result = game.lastRoundResult;
    if (result == null) return const SizedBox();
    
    final won = result.winner == 'you';
    final tied = result.winner == 'tie';
    
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.surfaceGradient,
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Spacer(),
                
                // Result icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: tied
                        ? AppTheme.warning.withOpacity(0.2)
                        : won
                            ? AppTheme.success.withOpacity(0.2)
                            : AppTheme.accent.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    tied
                        ? Icons.handshake
                        : won
                            ? Icons.emoji_events
                            : Icons.close,
                    size: 40,
                    color: tied
                        ? AppTheme.warning
                        : won
                            ? AppTheme.success
                            : AppTheme.accent,
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Result text
                Text(
                  tied ? 'TIE!' : won ? 'YOU WIN!' : 'THEY WIN!',
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                
                const SizedBox(height: 48),
                
                // Words comparison
                Row(
                  children: [
                    // Your word
                    Expanded(
                      child: _WordCard(
                        label: 'YOU',
                        word: result.yourWord.isEmpty ? '-' : result.yourWord,
                        score: result.yourScore,
                        isWinner: result.yourScore >= result.oppScore,
                      ),
                    ),
                    
                    const SizedBox(width: 16),
                    
                    // Opponent word
                    Expanded(
                      child: _WordCard(
                        label: game.opponentName ?? 'OPP',
                        word: result.oppWord.isEmpty ? '-' : result.oppWord,
                        score: result.oppScore,
                        isWinner: result.oppScore > result.yourScore,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 32),
                
                // Match score
                Text(
                  '${result.yourWins} - ${result.oppWins}',
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                
                const Spacer(),
                
                // Continue button
                GestureDetector(
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    game.continueAfterRound();
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Center(
                      child: Text(
                        'NEXT ROUND',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MatchResultView extends StatelessWidget {
  final GameState game;
  
  const _MatchResultView({required this.game});

  @override
  Widget build(BuildContext context) {
    final won = game.matchWinner == 'you';
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: won
              ? LinearGradient(
                  colors: [
                    AppTheme.success.withOpacity(0.3),
                    AppTheme.background,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                )
              : AppTheme.surfaceGradient,
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Spacer(),
                
                // Trophy
                Icon(
                  won ? Icons.emoji_events : Icons.sentiment_dissatisfied,
                  size: 100,
                  color: won ? AppTheme.warning : AppTheme.textMuted,
                ),
                
                const SizedBox(height: 24),
                
                // Result text
                Text(
                  won ? 'VICTORY!' : 'DEFEAT',
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    color: won ? AppTheme.warning : AppTheme.textSecondary,
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Final score
                Text(
                  '${game.myWins} - ${game.oppWins}',
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                
                const SizedBox(height: 8),
                
                Text(
                  'vs ${game.opponentName}',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                
                const Spacer(),
                
                // Play again
                GestureDetector(
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    game.startQueue();
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Center(
                      child: Text(
                        'PLAY AGAIN',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Home button
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    game.goHome();
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.surfaceLight),
                    ),
                    child: const Center(
                      child: Text(
                        'HOME',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          letterSpacing: 1,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WordCard extends StatelessWidget {
  final String label;
  final String word;
  final int score;
  final bool isWinner;
  
  const _WordCard({
    required this.label,
    required this.word,
    required this.score,
    required this.isWinner,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isWinner
            ? AppTheme.success.withOpacity(0.1)
            : AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isWinner ? AppTheme.success : AppTheme.surfaceLight,
          width: isWinner ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textMuted,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            word,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isWinner ? AppTheme.success : AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$score pts',
            style: TextStyle(
              fontSize: 16,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
