import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class TimerBar extends StatelessWidget {
  final int remainingMs;
  final int totalMs;
  
  const TimerBar({
    super.key,
    required this.remainingMs,
    required this.totalMs,
  });

  @override
  Widget build(BuildContext context) {
    final progress = (remainingMs / totalMs).clamp(0.0, 1.0);
    
    // Color transitions: green -> yellow -> red
    Color barColor;
    if (progress > 0.5) {
      barColor = AppTheme.success;
    } else if (progress > 0.2) {
      barColor = AppTheme.warning;
    } else {
      barColor = AppTheme.accent;
    }
    
    return Container(
      height: 8,
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Stack(
        children: [
          // Progress bar
          AnimatedFractionallySizedBox(
            duration: const Duration(milliseconds: 100),
            widthFactor: progress,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    barColor,
                    barColor.withOpacity(0.7),
                  ],
                ),
                borderRadius: BorderRadius.circular(4),
                boxShadow: [
                  BoxShadow(
                    color: barColor.withOpacity(0.5),
                    blurRadius: 8,
                    offset: const Offset(0, 0),
                  ),
                ],
              ),
            ),
          ),
          
          // Pulse effect when low
          if (progress <= 0.2)
            AnimatedOpacity(
              duration: const Duration(milliseconds: 300),
              opacity: (remainingMs ~/ 500) % 2 == 0 ? 0.8 : 0.4,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      barColor.withOpacity(0.3),
                      Colors.transparent,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class AnimatedFractionallySizedBox extends StatelessWidget {
  final Duration duration;
  final double widthFactor;
  final Widget child;
  
  const AnimatedFractionallySizedBox({
    super.key,
    required this.duration,
    required this.widthFactor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: duration,
      width: MediaQuery.of(context).size.width * widthFactor,
      child: child,
    );
  }
}
