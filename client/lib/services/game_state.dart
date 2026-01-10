import 'package:flutter/foundation.dart';
import 'socket_service.dart';

enum GameScreen {
  home,
  modeSelect,
  queued,
  match,
  roundResult,
  matchResult,
}

enum MatchType { pvp, bot }
enum BotDifficulty { easy, medium, hard }

class BonusTile {
  final int index;
  final String type; // 'DL', 'TL', 'DW'
  
  BonusTile({required this.index, required this.type});
  
  factory BonusTile.fromJson(Map<String, dynamic> json) {
    return BonusTile(
      index: json['index'] as int,
      type: json['type'] as String,
    );
  }
}

class RoundResult {
  final String yourWord;
  final int yourScore;
  final String oppWord;
  final int oppScore;
  final String winner;
  final int yourWins;
  final int oppWins;
  
  RoundResult({
    required this.yourWord,
    required this.yourScore,
    required this.oppWord,
    required this.oppScore,
    required this.winner,
    required this.yourWins,
    required this.oppWins,
  });
  
  factory RoundResult.fromJson(Map<String, dynamic> json) {
    return RoundResult(
      yourWord: json['yourWord'] as String,
      yourScore: json['yourScore'] as int,
      oppWord: json['oppWord'] as String,
      oppScore: json['oppScore'] as int,
      winner: json['winner'] as String,
      yourWins: json['yourWins'] as int,
      oppWins: json['oppWins'] as int,
    );
  }
}

class GameState extends ChangeNotifier {
  SocketService? _socket;
  
  GameScreen _screen = GameScreen.home;
  
  // Mode selection
  int _selectedMode = 8;
  MatchType _matchType = MatchType.bot;
  BotDifficulty _botDifficulty = BotDifficulty.medium;
  
  // Match state
  String? _roomId;
  String? _opponentName;
  bool _opponentIsBot = false;
  
  // Round state
  int _currentRound = 0;
  List<String> _letters = [];
  List<BonusTile> _bonuses = [];
  int _roundEndsAt = 0;
  bool _submitted = false;
  bool _opponentSubmitted = false;
  String _currentWord = '';
  
  // Results
  RoundResult? _lastRoundResult;
  int _myWins = 0;
  int _oppWins = 0;
  String? _matchWinner;
  
  // Getters
  GameScreen get screen => _screen;
  int get selectedMode => _selectedMode;
  MatchType get matchType => _matchType;
  BotDifficulty get botDifficulty => _botDifficulty;
  String? get roomId => _roomId;
  String? get opponentName => _opponentName;
  bool get opponentIsBot => _opponentIsBot;
  int get currentRound => _currentRound;
  List<String> get letters => _letters;
  List<BonusTile> get bonuses => _bonuses;
  int get roundEndsAt => _roundEndsAt;
  bool get submitted => _submitted;
  bool get opponentSubmitted => _opponentSubmitted;
  String get currentWord => _currentWord;
  RoundResult? get lastRoundResult => _lastRoundResult;
  int get myWins => _myWins;
  int get oppWins => _oppWins;
  String? get matchWinner => _matchWinner;
  
  void updateSocket(SocketService socket) {
    if (_socket == socket) return;
    
    _socket?.offMessage();
    _socket = socket;
    _socket?.onMessage(_handleMessage);
  }
  
  void _handleMessage(dynamic data) {
    final msg = data as Map<String, dynamic>;
    final type = msg['type'] as String;
    
    switch (type) {
      case 'queued':
        _screen = GameScreen.queued;
        break;
        
      case 'matchFound':
        _roomId = msg['roomId'] as String;
        _opponentName = msg['opponent']['name'] as String;
        _opponentIsBot = msg['opponent']['isBot'] as bool;
        _screen = GameScreen.match;
        _myWins = 0;
        _oppWins = 0;
        break;
        
      case 'roundStart':
        _currentRound = msg['round'] as int;
        _letters = List<String>.from(msg['letters'] as List);
        _bonuses = (msg['bonuses'] as List)
            .map((b) => BonusTile.fromJson(b as Map<String, dynamic>))
            .toList();
        _roundEndsAt = msg['endsAt'] as int;
        _submitted = false;
        _opponentSubmitted = false;
        _currentWord = '';
        _screen = GameScreen.match;
        break;
        
      case 'opponentSubmitted':
        _opponentSubmitted = true;
        break;
        
      case 'roundResult':
        _lastRoundResult = RoundResult.fromJson(msg);
        _myWins = _lastRoundResult!.yourWins;
        _oppWins = _lastRoundResult!.oppWins;
        _screen = GameScreen.roundResult;
        break;
        
      case 'matchResult':
        _myWins = msg['yourWins'] as int;
        _oppWins = msg['oppWins'] as int;
        _matchWinner = msg['winner'] as String;
        _screen = GameScreen.matchResult;
        break;
        
      case 'error':
        print('Server error: ${msg['message']}');
        break;
    }
    
    notifyListeners();
  }
  
  // Actions
  void setMode(int mode) {
    _selectedMode = mode;
    notifyListeners();
  }
  
  void setMatchType(MatchType type) {
    _matchType = type;
    notifyListeners();
  }
  
  void setBotDifficulty(BotDifficulty difficulty) {
    _botDifficulty = difficulty;
    notifyListeners();
  }
  
  void goToModeSelect() {
    _screen = GameScreen.modeSelect;
    notifyListeners();
  }
  
  void goHome() {
    _screen = GameScreen.home;
    _socket?.leave();
    _reset();
    notifyListeners();
  }
  
  void startQueue() {
    _socket?.queue(
      mode: _selectedMode,
      matchType: _matchType == MatchType.pvp ? 'pvp' : 'bot',
      botDifficulty: _matchType == MatchType.bot ? _botDifficulty.name : null,
    );
  }
  
  void addLetter(String letter) {
    if (_submitted) return;
    
    // Check if letter is available in rack
    final usedLetters = _currentWord.split('');
    final availableLetters = List<String>.from(_letters);
    
    for (final used in usedLetters) {
      final idx = availableLetters.indexOf(used);
      if (idx != -1) availableLetters.removeAt(idx);
    }
    
    if (availableLetters.contains(letter)) {
      _currentWord += letter;
      notifyListeners();
    }
  }
  
  void removeLetter() {
    if (_submitted || _currentWord.isEmpty) return;
    _currentWord = _currentWord.substring(0, _currentWord.length - 1);
    notifyListeners();
  }
  
  void clearWord() {
    if (_submitted) return;
    _currentWord = '';
    notifyListeners();
  }
  
  void submitWord() {
    if (_submitted || _currentWord.isEmpty) return;
    
    _socket?.submitWord(_currentWord);
    _submitted = true;
    notifyListeners();
  }
  
  void continueAfterRound() {
    _screen = GameScreen.match;
    notifyListeners();
  }
  
  void _reset() {
    _roomId = null;
    _opponentName = null;
    _opponentIsBot = false;
    _currentRound = 0;
    _letters = [];
    _bonuses = [];
    _roundEndsAt = 0;
    _submitted = false;
    _opponentSubmitted = false;
    _currentWord = '';
    _lastRoundResult = null;
    _myWins = 0;
    _oppWins = 0;
    _matchWinner = null;
  }
}
