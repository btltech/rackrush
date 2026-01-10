import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/game_state.dart';
import '../theme/app_theme.dart';

class ModeSelectScreen extends StatelessWidget {
  const ModeSelectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GameState>(
      builder: (context, game, _) {
        final isQueued = game.screen == GameScreen.queued;
        
        return Scaffold(
          body: Container(
            decoration: const BoxDecoration(
              gradient: AppTheme.surfaceGradient,
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    
                    // Back button
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        game.goHome();
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.arrow_back,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Title
                    Text(
                      game.matchType == MatchType.pvp
                          ? 'PLAY ONLINE'
                          : 'VS BOT',
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                    Text(
                      'Choose your mode',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Mode cards
                    Expanded(
                      child: ListView(
                        children: [
                          _ModeCard(
                            letters: 7,
                            label: 'Quick',
                            description: 'Fast games, 25s timer',
                            color: AppTheme.success,
                            selected: game.selectedMode == 7,
                            onTap: () => game.setMode(7),
                          ),
                          const SizedBox(height: 12),
                          _ModeCard(
                            letters: 8,
                            label: 'Standard',
                            description: 'Balanced, 30s timer',
                            color: AppTheme.secondary,
                            selected: game.selectedMode == 8,
                            onTap: () => game.setMode(8),
                          ),
                          const SizedBox(height: 12),
                          _ModeCard(
                            letters: 9,
                            label: 'Classic',
                            description: 'Competitive, 35s timer',
                            color: AppTheme.primary,
                            selected: game.selectedMode == 9,
                            onTap: () => game.setMode(9),
                          ),
                          const SizedBox(height: 12),
                          _ModeCard(
                            letters: 10,
                            label: 'Master',
                            description: 'Hardcore, 45s timer',
                            color: AppTheme.accent,
                            selected: game.selectedMode == 10,
                            onTap: () => game.setMode(10),
                          ),
                          
                          // Bot difficulty (only for bot matches)
                          if (game.matchType == MatchType.bot) ...[
                            const SizedBox(height: 32),
                            Text(
                              'Bot Difficulty',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                _DifficultyChip(
                                  label: 'Easy',
                                  selected: game.botDifficulty == BotDifficulty.easy,
                                  onTap: () => game.setBotDifficulty(BotDifficulty.easy),
                                ),
                                const SizedBox(width: 12),
                                _DifficultyChip(
                                  label: 'Medium',
                                  selected: game.botDifficulty == BotDifficulty.medium,
                                  onTap: () => game.setBotDifficulty(BotDifficulty.medium),
                                ),
                                const SizedBox(width: 12),
                                _DifficultyChip(
                                  label: 'Hard',
                                  selected: game.botDifficulty == BotDifficulty.hard,
                                  onTap: () => game.setBotDifficulty(BotDifficulty.hard),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    
                    // Play button
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: GestureDetector(
                        onTap: isQueued
                            ? null
                            : () {
                                HapticFeedback.heavyImpact();
                                game.startQueue();
                              },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          decoration: BoxDecoration(
                            gradient: isQueued ? null : AppTheme.primaryGradient,
                            color: isQueued ? AppTheme.surface : null,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: isQueued
                                ? null
                                : [
                                    BoxShadow(
                                      color: AppTheme.primary.withOpacity(0.3),
                                      blurRadius: 20,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (isQueued) ...[
                                const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppTheme.secondary,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'FINDING MATCH...',
                                  style: Theme.of(context).textTheme.labelLarge,
                                ),
                              ] else ...[
                                const Icon(Icons.play_arrow, color: Colors.white),
                                const SizedBox(width: 8),
                                Text(
                                  'PLAY',
                                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                    fontSize: 18,
                                    letterSpacing: 2,
                                  ),
                                ),
                              ],
                            ],
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
      },
    );
  }
}

class _ModeCard extends StatelessWidget {
  final int letters;
  final String label;
  final String description;
  final Color color;
  final bool selected;
  final VoidCallback onTap;
  
  const _ModeCard({
    required this.letters,
    required this.label,
    required this.description,
    required this.color,
    required this.selected,
    required this.onTap,
  });
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.15) : AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? color : AppTheme.surfaceLight,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  '$letters',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: selected ? color : AppTheme.textPrimary,
                    ),
                  ),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            if (selected)
              Icon(Icons.check_circle, color: color),
          ],
        ),
      ),
    );
  }
}

class _DifficultyChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  
  const _DifficultyChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: selected ? AppTheme.primary.withOpacity(0.2) : AppTheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? AppTheme.primary : AppTheme.surfaceLight,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: selected ? AppTheme.primary : AppTheme.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
