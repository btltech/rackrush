import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class LetterTile extends StatelessWidget {
  final String letter;
  final String? bonus; // 'DL', 'TL', 'DW'
  final bool isUsed;
  final VoidCallback? onTap;
  
  const LetterTile({
    super.key,
    required this.letter,
    this.bonus,
    this.isUsed = false,
    this.onTap,
  });
  
  // Letter point values
  static int getValue(String letter) {
    const values = {
      'A': 1, 'B': 3, 'C': 3, 'D': 2, 'E': 1, 'F': 4, 'G': 2, 'H': 4, 'I': 1,
      'J': 8, 'K': 5, 'L': 1, 'M': 3, 'N': 1, 'O': 1, 'P': 3, 'Q': 10, 'R': 1,
      'S': 1, 'T': 1, 'U': 1, 'V': 4, 'W': 4, 'X': 8, 'Y': 4, 'Z': 10,
    };
    return values[letter.toUpperCase()] ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final value = getValue(letter);
    final color = AppTheme.getLetterColor(value);
    
    Color? bonusColor;
    String? bonusLabel;
    if (bonus != null) {
      switch (bonus) {
        case 'DL':
          bonusColor = AppTheme.doubleLetter;
          bonusLabel = '2×';
          break;
        case 'TL':
          bonusColor = AppTheme.tripleLetter;
          bonusLabel = '3×';
          break;
        case 'DW':
          bonusColor = AppTheme.doubleWord;
          bonusLabel = 'DW';
          break;
      }
    }
    
    return GestureDetector(
      onTap: isUsed ? null : onTap,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 150),
        opacity: isUsed ? 0.3 : 1.0,
        child: AnimatedScale(
          duration: const Duration(milliseconds: 150),
          scale: isUsed ? 0.9 : 1.0,
          child: Container(
            width: 52,
            height: 60,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color.withOpacity(0.3),
                  color.withOpacity(0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: bonusColor ?? color.withOpacity(0.5),
                width: bonus != null ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: (bonusColor ?? color).withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Letter
                Center(
                  child: Text(
                    letter.toUpperCase(),
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: isUsed ? AppTheme.textMuted : AppTheme.textPrimary,
                    ),
                  ),
                ),
                
                // Point value
                Positioned(
                  right: 4,
                  bottom: 2,
                  child: Text(
                    '$value',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
                
                // Bonus indicator
                if (bonus != null)
                  Positioned(
                    left: 2,
                    top: 2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: bonusColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        bonusLabel!,
                        style: const TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
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
