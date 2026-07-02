import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as sio;
import '../end_points.dart';

// ── Event models ──────────────────────────────────────────────────────────────

class ChatTokenEvent {
  final String token;
  final bool done;
  const ChatTokenEvent({required this.token, required this.done});

  factory ChatTokenEvent.fromData(dynamic d) {
    final m = d is Map ? Map<String, dynamic>.from(d) : <String, dynamic>{};
    return ChatTokenEvent(
      token: m['token']?.toString() ?? '',
      done: m['done'] == true,
    );
  }
}

class ChatDoneEvent {
  final String response;
  final String? coinContext;
  final String? model;
  const ChatDoneEvent(
      {required this.response, this.coinContext, this.model});

  factory ChatDoneEvent.fromData(dynamic d) {
    final m = d is Map ? Map<String, dynamic>.from(d) : <String, dynamic>{};
    return ChatDoneEvent(
      response: m['response']?.toString() ?? '',
      coinContext: m['coinContext']?.toString(),
      model: m['model']?.toString(),
    );
  }
}

class ChatHistoryMessage {
  final String role;   // 'user' | 'assistant'
  final String content;
  final String? coinContext;
  final DateTime? timestamp;

  const ChatHistoryMessage({
    required this.role,
    required this.content,
    this.coinContext,
    this.timestamp,
  });

  bool get isUser => role == 'user';

  factory ChatHistoryMessage.fromJson(Map<String, dynamic> j) =>
      ChatHistoryMessage(
        role: j['role']?.toString() ?? 'user',
        content: j['content']?.toString() ?? j['message']?.toString() ?? '',
        coinContext: j['coinContext']?.toString(),
        timestamp: _parseDate(j['timestamp'] ?? j['createdAt']),
      );
}

DateTime? _parseDate(dynamic v) {
  if (v == null) return null;
  try {
    return DateTime.parse(v.toString());
  } catch (_) {
    return null;
  }
}

// ── ChatSocket singleton ───────────────────────────────────────────────────────

class ChatSocket {
  ChatSocket._();
  static final ChatSocket instance = ChatSocket._();

  sio.Socket? _socket;

  final _tokenCtrl = StreamController<ChatTokenEvent>.broadcast();
  final _startCtrl = StreamController<void>.broadcast();
  final _doneCtrl = StreamController<ChatDoneEvent>.broadcast();
  final _errorCtrl = StreamController<String>.broadcast();
  final _historyCtrl = StreamController<List<ChatHistoryMessage>>.broadcast();

  Stream<ChatTokenEvent> get tokenStream => _tokenCtrl.stream;
  Stream<void> get startStream => _startCtrl.stream;
  Stream<ChatDoneEvent> get doneStream => _doneCtrl.stream;
  Stream<String> get errorStream => _errorCtrl.stream;
  Stream<List<ChatHistoryMessage>> get historyStream => _historyCtrl.stream;

  bool get isConnected => _socket?.connected ?? false;

  void connect() {
    if (_socket != null) return;

    _socket = sio.io(
      EndPoints.socketUrl,
      sio.OptionBuilder()
          .setPath(EndPoints.socketPath)
          .setTransports(['websocket', 'polling'])
          .setExtraHeaders({'ngrok-skip-browser-warning': 'true'})
          .disableAutoConnect()
          .build(),
    );

    _socket!
      ..onConnect((_) {
        print('[ChatSocket] connected');
      })
      ..on('chat:start', (_) => _startCtrl.add(null))
      ..on('chat:token', (data) {
        _tokenCtrl.add(ChatTokenEvent.fromData(data));
      })
      ..on('chat:done', (data) {
        _doneCtrl.add(ChatDoneEvent.fromData(data));
      })
      ..on('chat:error', (data) {
        final msg = data is Map
            ? data['message']?.toString() ?? 'Unknown error'
            : data.toString();
        _errorCtrl.add(msg);
      })
      ..on('chat:history', (data) {
        final list = data is List ? data : [];
        final messages = list
            .whereType<Map>()
            .map((m) =>
                ChatHistoryMessage.fromJson(Map<String, dynamic>.from(m)))
            .toList();
        _historyCtrl.add(messages);
      })
      ..onDisconnect((_) => print('[ChatSocket] disconnected'))
      ..onError((e) => print('[ChatSocket] error: $e'))
      ..connect();
  }

  void sendMessage(String userId, String message, {String? coinId}) {
    final payload = <String, dynamic>{
      'userId': userId,
      'message': message,
      if (coinId != null && coinId.isNotEmpty) 'coinId': coinId,
    };
    _socket?.emit('chat:message', payload);
  }

  void loadHistory(String userId, {int limit = 50}) {
    _socket?.emit('chat:history', {'userId': userId, 'limit': limit});
  }

  void disconnect() {
    _socket?.dispose();
    _socket = null;
  }

  void dispose() {
    disconnect();
    _tokenCtrl.close();
    _startCtrl.close();
    _doneCtrl.close();
    _errorCtrl.close();
    _historyCtrl.close();
  }
}
