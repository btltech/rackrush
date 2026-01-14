import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../theme/app_theme.dart';

class ShareCard extends StatelessWidget {
  final int yourWins;
  final int oppWins;
  final String bestWord;
  final int bestScore;
  final int mode;
  final bool won;
  final GlobalKey repaintKey;
  
  const ShareCard({
    super.key,
    required this.yourWins,
    required this.oppWins,
    required this.bestWord,
    required this.bestScore,
    required this.mode,
    required this.won,
    required this.repaintKey,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      key: repaintKey,
      child: Container(
        width: 350,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF1A1A2E),
              won ? const Color(0xFF1A3A2E) : const Color(0xFF2E1A1A),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: won ? AppTheme.success.withOpacity(0.3) : AppTheme.accent.withOpacity(0.3),
            width: 2,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Logo
            ShaderMask(
              shaderCallback: (bounds) =>
                  AppTheme.primaryGradient.createShader(bounds),
              child: const Text(
                'RACKRUSH',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 3,
                  color: Colors.white,
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Result
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: won 
                    ? AppTheme.success.withOpacity(0.15)
                    : AppTheme.accent.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    won ? Icons.emoji_events : Icons.close,
                    color: won ? AppTheme.warning : AppTheme.accent,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    won ? 'VICTORY!' : 'DEFEAT',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: won ? AppTheme.success : AppTheme.accent,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Score
            Text(
              '$yourWins - $oppWins',
              style: const TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Mode badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$mode-letter ${_getModeName(mode)}',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Best word
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surface.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Text(
                    'BEST WORD',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textMuted,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    bestWord.isEmpty ? '-' : bestWord,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.secondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$bestScore pts',
                    style: const TextStyle(
                      fontSize: 16,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Play prompt
            ShaderMask(
              shaderCallback: (bounds) =>
                  AppTheme.primaryGradient.createShader(bounds),
              child: const Text(
                'Play at rackrush.app',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  String _getModeName(int mode) {
    switch (mode) {
      case 7: return 'Quick';
      case 8: return 'Standard';
      case 9: return 'Classic';
      case 10: return 'Master';
      default: return '';
    }
  }
}

// Helper to capture and share the card
class ShareCardHelper {
  static Future<void> shareMatchResult({
    required GlobalKey repaintKey,
    required int yourWins,
    required int oppWins,
    required int mode,
    required bool won,
  }) async {
    try {
      // Capture the widget as an image
      final RenderRepaintBoundary boundary =
          repaintKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      
      if (byteData == null) return;
      
      final Uint8List pngBytes = byteData.buffer.asUint8List();
      
      // Save to temp file
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/rackrush_result.png');
      await file.writeAsBytes(pngBytes);
      
      // Share
      final result = won ? 'Won' : 'Lost';
      await Share.shareXFiles(
        [XFile(file.path)],
        text: '🎮 I $result $yourWins-$oppWins in RackRush $mode-letter mode! Can you beat me?',
      );
    } catch (e) {
      print('Share error: $e');
    }
  }
}
