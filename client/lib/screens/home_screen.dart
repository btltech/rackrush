import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/socket_service.dart';
import '../services/game_state.dart';
import '../theme/app_theme.dart';
import 'mode_select_screen.dart';
import 'match_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _connecting = false;
  
  @override
  void initState() {
    super.initState();
    _initConnection();
  }
  
  Future<void> _initConnection() async {
    final prefs = await SharedPreferences.getInstance();
    String? deviceId = prefs.getString('deviceId');
    
    if (deviceId == null) {
      deviceId = const Uuid().v4();
      await prefs.setString('deviceId', deviceId);
    }
    
    if (mounted) {
      context.read<SocketService>().connect(deviceId);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Consumer<GameState>(
      builder: (context, game, _) {
        // Route based on game state
        switch (game.screen) {
          case GameScreen.modeSelect:
          case GameScreen.queued:
            return const ModeSelectScreen();
          case GameScreen.match:
          case GameScreen.roundResult:
          case GameScreen.matchResult:
            return const MatchScreen();
          case GameScreen.home:
          default:
            return _buildHome(context);
        }
      },
    );
  }
  
  Widget _buildHome(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.surfaceGradient,
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const Spacer(flex: 2),
                
                // Logo / Title
                ShaderMask(
                  shaderCallback: (bounds) =>
                      AppTheme.primaryGradient.createShader(bounds),
                  child: Text(
                    'RACKRUSH',
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      fontSize: 48,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 4,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Word Duel',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppTheme.textSecondary,
                    letterSpacing: 2,
                  ),
                ),
                
                const Spacer(flex: 2),
                
                // Connection status
                Consumer<SocketService>(
                  builder: (context, socket, _) {
                    return AnimatedOpacity(
                      opacity: socket.connected ? 0 : 1,
                      duration: const Duration(milliseconds: 300),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppTheme.secondary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Connecting...',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                
                const SizedBox(height: 32),
                
                // Play Online button
                _MenuButton(
                  label: 'PLAY ONLINE',
                  icon: Icons.public,
                  gradient: AppTheme.primaryGradient,
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    context.read<GameState>().setMatchType(MatchType.pvp);
                    context.read<GameState>().goToModeSelect();
                  },
                ),
                
                const SizedBox(height: 16),
                
                // Vs Bot button
                _MenuButton(
                  label: 'VS BOT',
                  icon: Icons.smart_toy,
                  gradient: AppTheme.warmGradient,
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    context.read<GameState>().setMatchType(MatchType.bot);
                    context.read<GameState>().goToModeSelect();
                  },
                ),
                
                const SizedBox(height: 16),
                
                // Daily Challenge button
                _MenuButton(
                  label: 'DAILY CHALLENGE',
                  icon: Icons.calendar_today,
                  solid: AppTheme.surface,
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    // TODO: Implement daily challenge
                  },
                ),
                
                const Spacer(flex: 3),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MenuButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Gradient? gradient;
  final Color? solid;
  final VoidCallback onTap;
  
  const _MenuButton({
    required this.label,
    required this.icon,
    this.gradient,
    this.solid,
    required this.onTap,
  });
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          gradient: gradient,
          color: solid,
          borderRadius: BorderRadius.circular(16),
          border: solid != null
              ? Border.all(color: AppTheme.surfaceLight, width: 1)
              : null,
          boxShadow: gradient != null
              ? [
                  BoxShadow(
                    color: (gradient as LinearGradient).colors.first.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(width: 12),
            Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontSize: 16,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
