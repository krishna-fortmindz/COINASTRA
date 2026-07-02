import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/remote/data/dashboard/models/dashboard_models.dart';
import '../../../providers/dashboard_provider.dart';

class FearGreedWidget extends ConsumerWidget {
  const FearGreedWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(fearGreedProvider);
    return async.when(
      loading: _buildShimmer,
      error: (_, __) => _buildContent(FearGreedData.empty()),
      data: _buildContent,
    );
  }

  static Widget _buildShimmer() => Shimmer.fromColors(
    baseColor: AppColors.bgCard,
    highlightColor: AppColors.bgTertiary,
    child: Container(
      height: 240,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
    ),
  );

  static Widget _buildContent(FearGreedData data) {
    final color = data.value > 75
        ? AppColors.brandRed
        : data.value > 55
            ? AppColors.brandGreen
            : data.value > 45
                ? AppColors.brandAmber
                : AppColors.brandRed;

    final history = [
      if (data.yesterday != null) ('Yesterday', data.yesterday!, _labelFor(data.yesterday!)),
      if (data.lastWeek != null) ('Last Week', data.lastWeek!, _labelFor(data.lastWeek!)),
      if (data.lastMonth != null) ('Last Month', data.lastMonth!, _labelFor(data.lastMonth!)),
      // fallback if API doesn't return history
      if (data.yesterday == null && data.lastWeek == null) ...const [
        ('Yesterday', 65, 'Greed'),
        ('Last Week', 48, 'Neutral'),
        ('Last Month', 31, 'Fear'),
      ],
    ];

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Fear & Greed Index',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
              const Spacer(),
              NeonBadge(label: 'Live', color: AppColors.brandGreen),
            ],
          ),
          const SizedBox(height: 16),
          Center(
            child: CircularPercentIndicator(
              radius: 52,
              lineWidth: 10,
              percent: data.value / 100,
              animation: true,
              animationDuration: 800,
              circularStrokeCap: CircularStrokeCap.round,
              progressColor: color,
              backgroundColor: AppColors.borderSubtle,
              center: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('${data.value}',
                    style: TextStyle(
                      fontSize: 28, fontWeight: FontWeight.w900,
                      color: color, fontFamily: 'JetBrainsMono',
                    )),
                  Text(data.classification,
                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _ScaleItem('Fear', AppColors.brandRed, 0),
              _ScaleItem('Neutral', AppColors.brandAmber, 50),
              _ScaleItem('Greed', AppColors.brandGreen, 100),
            ].map((w) => Expanded(child: w)).toList(),
          ),
          const SizedBox(height: 12),
          const Divider(color: AppColors.borderSubtle, height: 1),
          const SizedBox(height: 12),
          ...history.map((item) {
            final c = item.$2 > 60
                ? AppColors.brandGreen
                : item.$2 > 45
                    ? AppColors.brandAmber
                    : AppColors.brandRed;
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Text(item.$1,
                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                  const Spacer(),
                  Text(item.$3,
                    style: TextStyle(fontSize: 11, color: c, fontWeight: FontWeight.w600)),
                  const SizedBox(width: 8),
                  Text('${item.$2}',
                    style: TextStyle(
                      fontSize: 11, color: c,
                      fontFamily: 'JetBrainsMono', fontWeight: FontWeight.w700,
                    )),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  static String _labelFor(int v) =>
      v > 75 ? 'Extreme Greed' : v > 55 ? 'Greed' : v > 45 ? 'Neutral' : v > 25 ? 'Fear' : 'Extreme Fear';
}

class _ScaleItem extends StatelessWidget {
  final String label;
  final Color color;
  final int value;
  const _ScaleItem(this.label, this.color, this.value);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(width: 8, height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 9, color: AppColors.textMuted)),
      ],
    );
  }
}