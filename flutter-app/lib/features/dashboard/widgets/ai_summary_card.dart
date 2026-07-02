import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../providers/ai_summary_provider.dart';
import '../../../providers/analysis_provider.dart';

// Outer card frame is static — only the typewriter text rebuilds every 18ms
class AiSummaryCard extends ConsumerWidget {
  const AiSummaryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Listen for live market AI analysis and feed the typewriter text
    ref.listen(marketAiProvider, (_, next) {
      next.whenData((a) {
        if (a.analysis.summary.isNotEmpty) {
          ref.read(aiSummaryProvider).setText(a.analysis.summary);
        }
      });
    });
    return GlassCard(
      borderColor: AppColors.brandGreen.withAlpha(40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                    color: AppColors.brandGreen, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              const Text('AI Market Summary',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textMuted,
                      letterSpacing: 0.5)),
              const Spacer(),
              const NeonBadge(label: 'GPT-4', color: AppColors.brandPurple),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  gradient: AppColors.gradientGreen,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.bolt_rounded,
                    color: Colors.black, size: 16),
              ),
              const SizedBox(width: 12),
              // Only this Consumer rebuilds on each typewriter tick
              Expanded(
                child: Consumer(
                  builder: (_, ref, __) {
                    final charCount =
                        ref.watch(aiSummaryProvider.select((n) => n.charCount));
                    final isTyping =
                        ref.watch(aiSummaryProvider.select((n) => n.isTyping));
                    final fullText = ref.read(aiSummaryProvider).fullText;
                    final safe = charCount.clamp(0, fullText.length);
                    return RichText(
                      text: TextSpan(
                        text: fullText.substring(0, safe),
                        style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xCCFFFFFF),
                            height: 1.6,
                            fontFamily: 'Inter'),
                        children: [
                          if (isTyping) const WidgetSpan(child: _Cursor()),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: AppColors.borderSubtle, height: 1),
          const SizedBox(height: 12),
          Consumer(
            builder: (_, ref, __) {
              final sentiment = ref.watch(marketAiProvider).whenOrNull(
                    data: (a) => a.analysis.sentimentBreakdown,
                  );
              final bullish = sentiment?.bullish ?? 74;
              final neutral = sentiment?.neutral ?? 18;
              final bearish = sentiment?.bearish ?? 8;
              return Row(
                children: [
                  _SentimentChip('Bullish', bullish, AppColors.brandGreen),
                  const SizedBox(width: 8),
                  _SentimentChip('Neutral', neutral, AppColors.brandAmber),
                  const SizedBox(width: 8),
                  _SentimentChip('Bearish', bearish, AppColors.brandRed),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {},
                    child: const Row(
                      children: [
                        Text('Ask AI',
                            style: TextStyle(
                                fontSize: 12,
                                color: AppColors.brandGreen,
                                fontWeight: FontWeight.w600)),
                        SizedBox(width: 4),
                        Icon(Icons.arrow_forward_rounded,
                            size: 14, color: AppColors.brandGreen),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _Cursor extends StatefulWidget {
  const _Cursor();
  @override
  State<_Cursor> createState() => _CursorState();
}

class _CursorState extends State<_Cursor> with SingleTickerProviderStateMixin {
  late AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600))
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
          margin: const EdgeInsets.only(left: 1),
          decoration: BoxDecoration(
            color: AppColors.brandGreen,
            borderRadius: BorderRadius.circular(1),
          ),
        ),
      ),
    );
  }
}

class _SentimentChip extends StatelessWidget {
  final String label;
  final int percent;
  final Color color;
  const _SentimentChip(this.label, this.percent, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(40)),
      ),
      child: Text('$label $percent%',
          style: TextStyle(
              fontSize: 10, fontWeight: FontWeight.w600, color: color)),
    );
  }
}
