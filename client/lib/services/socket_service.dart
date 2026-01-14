import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

class SocketService extends ChangeNotifier {
  io.Socket? _socket;
  bool _connected = false;
  String? _deviceId;
  
  bool get connected => _connected;
  io.Socket? get socket => _socket;
  
  // Server URL - change for production
  static const String _devUrl = 'http://localhost:3000';
  static const String _prodUrl = 'https://rackrush-server-production.up.railway.app';
  
  // Always use production URL for physical device testing
  String get serverUrl => _prodUrl;
  
  void connect(String deviceId) {
    _deviceId = deviceId;
    
    _socket = io.io(serverUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
    });
    
    _socket!.onConnect((_) {
      print('Connected to server');
      _connected = true;
      
      // Send hello message
      _socket!.emit('message', {
        'type': 'hello',
        'version': '1.0.0',
        'deviceId': deviceId,
      });
      
      notifyListeners();
    });
    
    _socket!.onDisconnect((_) {
      print('Disconnected from server');
      _connected = false;
      notifyListeners();
    });
    
    _socket!.onError((error) {
      print('Socket error: $error');
    });
    
    _socket!.connect();
  }
  
  void disconnect() {
    _socket?.disconnect();
    _socket = null;
    _connected = false;
    notifyListeners();
  }
  
  void send(Map<String, dynamic> message) {
    if (_socket != null && _connected) {
      _socket!.emit('message', message);
    }
  }
  
  void onMessage(void Function(dynamic) callback) {
    _socket?.on('message', callback);
  }
  
  void offMessage() {
    _socket?.off('message');
  }
  
  // Queue for a match
  void queue({
    required int mode,
    required String matchType,
    String? botDifficulty,
  }) {
    send({
      'type': 'queue',
      'mode': mode,
      'matchType': matchType,
      if (botDifficulty != null) 'botDifficulty': botDifficulty,
    });
  }
  
  // Submit a word
  void submitWord(String word) {
    send({
      'type': 'submitWord',
      'word': word,
    });
  }
  
  // Leave current match
  void leave() {
    send({'type': 'leave'});
  }
  
  // Ping for keepalive
  void ping() {
    send({'type': 'ping'});
  }
  
  @override
  void dispose() {
    disconnect();
    super.dispose();
  }
}
