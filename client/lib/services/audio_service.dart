import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

/// Sound effects for RackRush
/// 
/// Place sound files in assets/sounds/:
/// - tap.mp3 - Letter tile tap
/// - submit.mp3 - Word submitted
/// - win.mp3 - Round/match won
/// - lose.mp3 - Round/match lost
/// - tick.mp3 - Timer warning
/// - match_start.mp3 - Match begins
class AudioService {
  static final AudioService _instance = AudioService._();
  static AudioService get instance => _instance;
  
  AudioService._();
  
  final AudioPlayer _player = AudioPlayer();
  bool _enabled = true;
  
  bool get enabled => _enabled;
  
  void setEnabled(bool value) {
    _enabled = value;
  }
  
  Future<void> playTap() async {
    await _play('tap.mp3');
    HapticFeedback.lightImpact();
  }
  
  Future<void> playSubmit() async {
    await _play('submit.mp3');
    HapticFeedback.mediumImpact();
  }
  
  Future<void> playWin() async {
    await _play('win.mp3');
    HapticFeedback.heavyImpact();
  }
  
  Future<void> playLose() async {
    await _play('lose.mp3');
  }
  
  Future<void> playTick() async {
    await _play('tick.mp3');
  }
  
  Future<void> playMatchStart() async {
    await _play('match_start.mp3');
    HapticFeedback.heavyImpact();
  }
  
  Future<void> _play(String filename) async {
    if (!_enabled) return;
    
    try {
      await _player.play(AssetSource('sounds/$filename'));
    } catch (e) {
      // Sound file might not exist yet - fail silently
      print('Audio error: $e');
    }
  }
  
  void dispose() {
    _player.dispose();
  }
}
