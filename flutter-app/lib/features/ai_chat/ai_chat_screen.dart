import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/ai_chat_provider.dart';
import '../../providers/dashboard_provider.dart';

class AiChatScreen extends ConsumerStatefulWidget {
  const AiChatScreen({super.key});

  @override
  ConsumerState<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends ConsumerState<AiChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  static const _suggested = [
    'What is BTC doing right now?',
    'Is now a good time to buy ETH?',
    'Explain the current funding rates',
    'What happened to SOL today?',
    'Is the market in a bull or bear phase?',
    'Show me key support/resistance levels',
  ];

  void _send(String text) {
    if (text.trim().isEmpty) return;
    ref.read(aiChatProvider.notifier).send(text);
    _controller.clear();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: LayoutBuilder(builder: (_, constraints) {
        final isMobile = constraints.maxWidth < 700;
        return Row(
          children: [
            Expanded(
              child: Column(
                children: [
                  _ChatHeader(
                    onSend: _send,
                  ),
                  // Error banner
                  Consumer(builder: (_, ref, __) {
                    final error =
                        ref.watch(aiChatProvider.select((s) => s.error));
                    if (error == null) return const SizedBox.shrink();
                    return Container(
                      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.brandRed.withAlpha(15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: AppColors.brandRed.withAlpha(40)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline_rounded,
                              size: 14, color: AppColors.brandRed),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(error,
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.brandRed)),
                          ),
                          GestureDetector(
                            onTap: () =>
                                ref.read(aiChatProvider.notifier).clearError(),
                            child: const Icon(Icons.close_rounded,
                                size: 14, color: AppColors.brandRed),
                          ),
                        ],
                      ),
                    );
                  }),
                  // Messages list
                  Expanded(
                    child: Consumer(builder: (_, ref, __) {
                      final messages =
                          ref.watch(aiChatProvider.select((s) => s.messages));
                      // watch isStreaming so list rebuilds on each token
                      ref.watch(aiChatProvider.select((s) => s.isStreaming));

                      // Auto-scroll on new content
                      WidgetsBinding.instance
                          .addPostFrameCallback((_) => _scrollToBottom());

                      return ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        itemCount: messages.length,
                        itemBuilder: (_, i) => Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: _ChatBubble(message: messages[i]),
                        ),
                      );
                    }),
                  ),
                  _ChatInput(
                    controller: _controller,
                    onSend: _send,
                  ),
                ],
              ),
            ),

            // Suggested sidebar — hidden on mobile
            if (!isMobile)
              Container(
                width: 240,
                decoration: const BoxDecoration(
                  color: AppColors.bgSecondary,
                  border: Border(
                      left: BorderSide(color: AppColors.borderSubtle)),
                ),
                child: _SuggestedPanel(
                  prompts: _suggested,
                  onTap: _send,
                ),
              ),
          ],
        );
      }),
    );
  }
}

// ── Header with coin context selector ─────────────────────────────────────────

class _ChatHeader extends ConsumerStatefulWidget {
  final ValueChanged<String> onSend;
  const _ChatHeader({required this.onSend});

  @override
  ConsumerState<_ChatHeader> createState() => _ChatHeaderState();
}

class _ChatHeaderState extends ConsumerState<_ChatHeader> {
  bool _showCoinSearch = false;
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final coinSymbol = ref
        .watch(aiChatProvider.select((s) => s.selectedCoinSymbol));

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: const BoxDecoration(
            border:
                Border(bottom: BorderSide(color: AppColors.borderSubtle)),
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  gradient: AppColors.gradientGreen,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.psychology_rounded,
                    color: Colors.black, size: 17),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('AI Trading Copilot',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        )),
                    Text(
                      coinSymbol != null
                          ? '$coinSymbol context · GPT-4'
                          : 'General · GPT-4 · Real-time data',
                      style: const TextStyle(
                          fontSize: 10, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              // Coin context toggle
              GestureDetector(
                onTap: () {
                  if (coinSymbol != null) {
                    ref.read(aiChatProvider.notifier).clearCoin();
                  } else {
                    setState(() => _showCoinSearch = !_showCoinSearch);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: coinSymbol != null
                        ? AppColors.brandBlue.withAlpha(20)
                        : AppColors.bgCard,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: coinSymbol != null
                          ? AppColors.brandBlue
                          : AppColors.borderSubtle,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        coinSymbol != null
                            ? Icons.close_rounded
                            : Icons.add_rounded,
                        size: 13,
                        color: coinSymbol != null
                            ? AppColors.brandBlue
                            : AppColors.textMuted,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        coinSymbol ?? 'Pin Coin',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: coinSymbol != null
                              ? AppColors.brandBlue
                              : AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        // Coin search dropdown
        if (_showCoinSearch && coinSymbol == null)
          _CoinContextSearch(
            controller: _searchCtrl,
            query: _query,
            onQueryChange: (v) => setState(() => _query = v),
            onPick: (coinId, symbol) {
              ref.read(aiChatProvider.notifier).setCoin(coinId, symbol);
              setState(() {
                _showCoinSearch = false;
                _query = '';
                _searchCtrl.clear();
              });
            },
          ),
      ],
    );
  }
}

class _CoinContextSearch extends ConsumerWidget {
  final TextEditingController controller;
  final String query;
  final ValueChanged<String> onQueryChange;
  final void Function(String coinId, String symbol) onPick;

  const _CoinContextSearch({
    required this.controller,
    required this.query,
    required this.onQueryChange,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.borderSubtle)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: TextField(
              controller: controller,
              autofocus: true,
              style: const TextStyle(fontSize: 13, color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search coin to pin context…',
                hintStyle: const TextStyle(
                    color: AppColors.textDisabled, fontSize: 13),
                filled: true,
                fillColor: AppColors.bgCard,
                prefixIcon: const Icon(Icons.search_rounded,
                    color: AppColors.textMuted, size: 16),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                        const BorderSide(color: AppColors.borderSubtle)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                        const BorderSide(color: AppColors.borderSubtle)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                        const BorderSide(color: AppColors.brandBlue)),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 8),
                isDense: true,
              ),
              onChanged: onQueryChange,
            ),
          ),
          if (query.length >= 2)
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 200),
              child: _CoinSearchList(query: query, onPick: onPick),
            ),
        ],
      ),
    );
  }
}

class _CoinSearchList extends ConsumerWidget {
  final String query;
  final void Function(String coinId, String symbol) onPick;
  const _CoinSearchList({required this.query, required this.onPick});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(coinSearchProvider(query));
    return async.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(12),
        child: Center(
            child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
              strokeWidth: 2, color: AppColors.brandGreen),
        )),
      ),
      error: (_, __) => const Padding(
        padding: EdgeInsets.all(10),
        child: Text('Search failed',
            style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
      ),
      data: (coins) => ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
        children: coins
            .take(5)
            .map((c) => InkWell(
                  onTap: () => onPick(c.id, c.symbol),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 8),
                    child: Row(
                      children: [
                        if (c.imageUrl != null)
                          ClipOval(
                            child: Image.network(c.imageUrl!,
                                width: 22,
                                height: 22,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(
                                    Icons.circle,
                                    size: 22,
                                    color: AppColors.textMuted)),
                          )
                        else
                          const Icon(Icons.circle,
                              size: 22, color: AppColors.textMuted),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(c.name,
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500)),
                        ),
                        Text(c.symbol.toUpperCase(),
                            style: const TextStyle(
                                fontSize: 10,
                                color: AppColors.textMuted,
                                fontFamily: 'JetBrainsMono')),
                      ],
                    ),
                  ),
                ))
            .toList(),
      ),
    );
  }
}

// ── Chat bubble ───────────────────────────────────────────────────────────────

class _ChatBubble extends StatelessWidget {
  final ChatMessage message;
  const _ChatBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment:
          message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!message.isUser) ...[
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              gradient: AppColors.gradientGreen,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.psychology_rounded,
                color: Colors.black, size: 14),
          ),
          const SizedBox(width: 8),
        ],
        Flexible(
          child: Column(
            crossAxisAlignment: message.isUser
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              // Coin context badge (AI messages only)
              if (!message.isUser && message.coinContext != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.brandBlue.withAlpha(20),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: AppColors.brandBlue.withAlpha(40)),
                    ),
                    child: Text(
                      message.coinContext!.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: AppColors.brandBlue,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: message.isUser
                      ? AppColors.brandGreen.withAlpha(20)
                      : AppColors.bgCard,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(12),
                    topRight: const Radius.circular(12),
                    bottomLeft:
                        Radius.circular(message.isUser ? 12 : 2),
                    bottomRight:
                        Radius.circular(message.isUser ? 2 : 12),
                  ),
                  border: Border.all(
                    color: message.isUser
                        ? AppColors.brandGreen.withAlpha(30)
                        : AppColors.borderSubtle,
                  ),
                ),
                child: message.isStreaming && message.text.isEmpty
                    ? const _TypingDots()
                    : message.isUser
                        ? Text(
                            message.text,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xCCFFFFFF),
                              height: 1.6,
                            ),
                          )
                        : MarkdownBody(
                            data: message.text,
                            selectable: true,
                            styleSheet: MarkdownStyleSheet(
                              p: const TextStyle(
                                fontSize: 13,
                                color: Color(0xCCFFFFFF),
                                height: 1.6,
                              ),
                              strong: const TextStyle(
                                fontSize: 13,
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                height: 1.6,
                              ),
                              em: const TextStyle(
                                fontSize: 13,
                                color: Color(0xCCFFFFFF),
                                fontStyle: FontStyle.italic,
                                height: 1.6,
                              ),
                              code: const TextStyle(
                                fontSize: 12,
                                color: AppColors.brandGreen,
                                fontFamily: 'JetBrainsMono',
                                backgroundColor: Colors.transparent,
                              ),
                              codeblockDecoration: BoxDecoration(
                                color: AppColors.bgPrimary,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                    color: AppColors.borderSubtle),
                              ),
                              blockquoteDecoration: BoxDecoration(
                                border: Border(
                                  left: BorderSide(
                                    color: AppColors.brandGreen
                                        .withAlpha(120),
                                    width: 3,
                                  ),
                                ),
                              ),
                              blockquotePadding: const EdgeInsets.only(
                                  left: 12),
                              h1: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700),
                              h2: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700),
                              h3: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600),
                              listBullet: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.brandGreen),
                              tableHead: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600),
                              tableBody: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xCCFFFFFF)),
                              tableBorder: TableBorder.all(
                                  color: AppColors.borderSubtle,
                                  width: 0.5),
                              horizontalRuleDecoration: BoxDecoration(
                                border: Border(
                                  top: BorderSide(
                                      color: AppColors.borderSubtle,
                                      width: 0.5),
                                ),
                              ),
                            ),
                          ),
              ),
              // Streaming cursor
              if (message.isStreaming && message.text.isNotEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 2, left: 4),
                  child: _BlinkingCursor(),
                ),
            ],
          ),
        ),
        if (message.isUser) const SizedBox(width: 8),
      ],
    );
  }
}

// ── Blinking cursor shown while AI is streaming ────────────────────────────────

class _BlinkingCursor extends StatefulWidget {
  const _BlinkingCursor();

  @override
  State<_BlinkingCursor> createState() => _BlinkingCursorState();
}

class _BlinkingCursorState extends State<_BlinkingCursor>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) => Opacity(
        opacity: _c.value,
        child: Container(
          width: 2,
          height: 14,
          color: AppColors.brandGreen,
        ),
      ),
    );
  }
}

// ── Typing dots (while waiting for first token) ────────────────────────────────

class _TypingDots extends StatefulWidget {
  const _TypingDots();

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) => Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(
          3,
          (i) => Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: AppColors.brandGreen.withAlpha(
                (80 + 120 * ((_c.value + i * 0.3) % 1.0)).toInt(),
              ),
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Input ─────────────────────────────────────────────────────────────────────

class _ChatInput extends ConsumerWidget {
  final TextEditingController controller;
  final ValueChanged<String> onSend;
  const _ChatInput({required this.controller, required this.onSend});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isStreaming =
        ref.watch(aiChatProvider.select((s) => s.isStreaming));

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.borderSubtle)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.bgCard,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: TextField(
                controller: controller,
                style: const TextStyle(fontSize: 14, color: Colors.white),
                minLines: 1,
                maxLines: 6,
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.newline,
                onSubmitted: isStreaming ? null : onSend,
                enabled: !isStreaming,
                decoration: InputDecoration(
                  hintText: isStreaming
                      ? 'AI is responding…'
                      : 'Ask anything about crypto markets…',
                  hintStyle: const TextStyle(
                      color: AppColors.textDisabled, fontSize: 13),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  isDense: true,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: isStreaming ? null : () => onSend(controller.text),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: isStreaming ? null : AppColors.gradientGreen,
                color: isStreaming ? AppColors.bgCard : null,
                borderRadius: BorderRadius.circular(12),
                boxShadow: isStreaming
                    ? null
                    : [
                        BoxShadow(
                          color: AppColors.brandGreen.withAlpha(80),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        )
                      ],
              ),
              child: isStreaming
                  ? const Center(
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.brandGreen),
                      ),
                    )
                  : const Icon(Icons.send_rounded,
                      color: Colors.black, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Suggested panel ───────────────────────────────────────────────────────────

class _SuggestedPanel extends StatelessWidget {
  final List<String> prompts;
  final ValueChanged<String> onTap;
  const _SuggestedPanel({required this.prompts, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(14, 16, 14, 8),
          child: Text('Suggested Prompts',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textMuted,
                letterSpacing: 0.5,
              )),
        ),
        ...prompts.map((p) => GestureDetector(
              onTap: () => onTap(p),
              child: Container(
                margin: const EdgeInsets.fromLTRB(10, 0, 10, 6),
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: AppColors.bgCard,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Row(
                  children: [
                    Expanded(
                        child: Text(p,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textMuted,
                            ))),
                    const Icon(Icons.arrow_forward_rounded,
                        size: 13, color: AppColors.textDisabled),
                  ],
                ),
              ),
            )),
      ],
    );
  }
}
