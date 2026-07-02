import 'dart:async';
import 'dart:convert';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/remote/chat_socket.dart';
import 'auth_provider.dart';

// ── Message model ─────────────────────────────────────────────────────────────

class ChatMessage {
  final String id;
  final String text;
  final bool isUser;
  final bool isStreaming;
  final String? coinContext;
  final DateTime? timestamp;

  const ChatMessage({
    required this.id,
    required this.text,
    required this.isUser,
    this.isStreaming = false,
    this.coinContext,
    this.timestamp,
  });

  ChatMessage copyWithText(String text, {bool? isStreaming}) => ChatMessage(
        id: id,
        text: text,
        isUser: isUser,
        isStreaming: isStreaming ?? this.isStreaming,
        coinContext: coinContext,
        timestamp: timestamp,
      );

  ChatMessage withCoinContext(String? ctx) => ChatMessage(
        id: id,
        text: text,
        isUser: isUser,
        isStreaming: false,
        coinContext: ctx,
        timestamp: timestamp,
      );
}

// ── State ─────────────────────────────────────────────────────────────────────

class AiChatState {
  final List<ChatMessage> messages;
  final bool isStreaming;
  final String? selectedCoinId;   // null = general chat
  final String? selectedCoinSymbol;
  final String? error;
  final bool historyLoaded;

  const AiChatState({
    required this.messages,
    this.isStreaming = false,
    this.selectedCoinId,
    this.selectedCoinSymbol,
    this.error,
    this.historyLoaded = false,
  });

  AiChatState copyWith({
    List<ChatMessage>? messages,
    bool? isStreaming,
    String? selectedCoinId,
    String? selectedCoinSymbol,
    String? error,
    bool? historyLoaded,
    bool clearCoin = false,
    bool clearError = false,
  }) =>
      AiChatState(
        messages: messages ?? this.messages,
        isStreaming: isStreaming ?? this.isStreaming,
        selectedCoinId: clearCoin ? null : selectedCoinId ?? this.selectedCoinId,
        selectedCoinSymbol:
            clearCoin ? null : selectedCoinSymbol ?? this.selectedCoinSymbol,
        error: clearError ? null : error ?? this.error,
        historyLoaded: historyLoaded ?? this.historyLoaded,
      );
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class AiChatNotifier extends Notifier<AiChatState> {
  final _socket = ChatSocket.instance;
  StreamSubscription<void>? _startSub;
  StreamSubscription<ChatTokenEvent>? _tokenSub;
  StreamSubscription<ChatDoneEvent>? _doneSub;
  StreamSubscription<String>? _errorSub;
  StreamSubscription<List<ChatHistoryMessage>>? _historySub;

  // For logged-in users: use real user ID stored by Next.js after login.
  // For guests: use 'guest' so the backend treats this as an anonymous session
  // (no history is loaded for guests — each browser session starts fresh).
  String get _userId {
    final userJson = html.window.localStorage['coinastra_user'];
    if (userJson != null) {
      try {
        final map = jsonDecode(userJson) as Map<String, dynamic>;
        final id = map['id']?.toString() ?? map['_id']?.toString() ?? '';
        if (id.isNotEmpty) return id;
      } catch (_) {}
    }
    return 'guest';
  }

  @override
  AiChatState build() {
    ref.onDispose(_dispose);
    _connect();
    return const AiChatState(
      messages: [
        ChatMessage(
          id: 'welcome',
          text: 'Hello! I\'m your AI Trading Copilot. Ask me anything about '
              'crypto markets — or pin a coin to get coin-specific analysis.',
          isUser: false,
        ),
      ],
    );
  }

  void _connect() {
    _socket.connect();

    _startSub = _socket.startStream.listen((_) {
      // Add a blank streaming message placeholder
      final streamingMsg = ChatMessage(
        id: 'stream_${DateTime.now().millisecondsSinceEpoch}',
        text: '',
        isUser: false,
        isStreaming: true,
      );
      state = state.copyWith(
        messages: [...state.messages, streamingMsg],
        isStreaming: true,
        clearError: true,
      );
    });

    _tokenSub = _socket.tokenStream.listen((event) {
      if (state.messages.isEmpty) return;
      final msgs = List<ChatMessage>.from(state.messages);
      final lastIdx = msgs.length - 1;
      if (!msgs[lastIdx].isStreaming) return;
      msgs[lastIdx] = msgs[lastIdx].copyWithText(
        msgs[lastIdx].text + event.token,
        isStreaming: !event.done,
      );
      state = state.copyWith(messages: msgs);
    });

    _doneSub = _socket.doneStream.listen((event) {
      if (state.messages.isEmpty) return;
      final msgs = List<ChatMessage>.from(state.messages);
      final lastIdx = msgs.length - 1;
      // Finalise the streaming message with full response + coinContext
      final finalMsg = event.response.isNotEmpty
          ? msgs[lastIdx]
              .copyWithText(event.response, isStreaming: false)
              .withCoinContext(event.coinContext)
          : msgs[lastIdx]
              .copyWithText(msgs[lastIdx].text, isStreaming: false)
              .withCoinContext(event.coinContext);
      msgs[lastIdx] = finalMsg;
      state = state.copyWith(messages: msgs, isStreaming: false);
    });

    _errorSub = _socket.errorStream.listen((msg) {
      // Remove any blank streaming placeholder
      final msgs = state.messages
          .where((m) => !(m.isStreaming && m.text.isEmpty))
          .toList();
      state = state.copyWith(
          messages: msgs, isStreaming: false, error: msg);
    });

    _historySub = _socket.historyStream.listen((history) {
      if (state.historyLoaded) return;
      final historicMsgs = history
          .map((h) => ChatMessage(
                id: 'hist_${history.indexOf(h)}',
                text: h.content,
                isUser: h.isUser,
                coinContext: h.coinContext,
                timestamp: h.timestamp,
              ))
          .toList();
      // Prepend history before the welcome message
      state = state.copyWith(
        messages: [...historicMsgs, ...state.messages],
        historyLoaded: true,
      );
    });

    // Only load history for authenticated users — anonymous sessions start fresh
    if (ref.read(authProvider)) {
      _socket.loadHistory(_userId);
    }
  }

  void send(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty || state.isStreaming) return;

    final userMsg = ChatMessage(
      id: 'user_${DateTime.now().millisecondsSinceEpoch}',
      text: trimmed,
      isUser: true,
      timestamp: DateTime.now(),
    );
    state = state.copyWith(
      messages: [...state.messages, userMsg],
      clearError: true,
    );

    _socket.sendMessage(_userId, trimmed, coinId: state.selectedCoinId);
  }

  void setCoin(String coinId, String symbol) {
    state = state.copyWith(
      selectedCoinId: coinId,
      selectedCoinSymbol: symbol.toUpperCase(),
    );
  }

  void clearCoin() {
    state = state.copyWith(clearCoin: true);
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  void _dispose() {
    _startSub?.cancel();
    _tokenSub?.cancel();
    _doneSub?.cancel();
    _errorSub?.cancel();
    _historySub?.cancel();
    _socket.disconnect();
  }
}

// Not autoDispose — chat history persists across navigation
final aiChatProvider =
    NotifierProvider<AiChatNotifier, AiChatState>(AiChatNotifier.new);
