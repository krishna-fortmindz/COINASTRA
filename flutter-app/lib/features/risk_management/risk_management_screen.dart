import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/glass_card.dart';
import '../../providers/risk_provider.dart';

class RiskManagementScreen extends ConsumerWidget {
  const RiskManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(
              title: 'Risk Management',
              subtitle: 'AI-powered position sizing and risk assessment',
            ),
            const SizedBox(height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      // Sliders: capital, leverage, risk%
                      Consumer(builder: (_, ref, __) {
                        final n = ref.watch(riskProvider);
                        return _CalculatorCard(
                          capital: n.capital,
                          leverage: n.leverage,
                          riskPercent: n.riskPercent,
                          onCapitalChanged: (v) =>
                              ref.read(riskProvider).setCapital(v),
                          onLeverageChanged: (v) =>
                              ref.read(riskProvider).setLeverage(v),
                          onRiskChanged: (v) =>
                              ref.read(riskProvider).setRiskPercent(v),
                        );
                      }),
                      const SizedBox(height: 16),
                      // Text inputs: entry, stop, take profit
                      const _PriceInputsCard(),
                      const SizedBox(height: 16),
                      // Position size API results
                      Consumer(builder: (_, ref, __) {
                        final n = ref.watch(riskProvider);
                        return _ResultsCard(
                          positionSize: n.positionSizeResult?.positionSize ??
                              n.localPositionSize,
                          liquidationPrice:
                              n.positionSizeResult?.liquidationPrice ??
                                  n.localLiquidationPrice,
                          maxLoss:
                              n.positionSizeResult?.maxLoss ?? n.localRiskInDollars,
                          riskLevel:
                              n.positionSizeResult?.riskLevel ?? n.riskLevel,
                          riskColor: n.riskColor,
                          loading: n.positionSizeLoading,
                          isEstimated: n.positionSizeResult == null,
                        );
                      }),
                      const SizedBox(height: 16),
                      // R:R calculator
                      Consumer(builder: (_, ref, __) {
                        final n = ref.watch(riskProvider);
                        return _RrCard(
                          winRate: n.winRate,
                          result: n.rrResult,
                          loading: n.rrLoading,
                          error: n.rrError,
                          onWinRateChanged: (v) =>
                              ref.read(riskProvider).setWinRate(v),
                        );
                      }),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    children: [
                      Consumer(builder: (_, ref, __) {
                        final n = ref.watch(riskProvider);
                        return Column(
                          children: [
                            _AiRiskWarning(
                              leverage: n.leverage,
                              riskPercent: n.riskPercent,
                              riskColor: n.riskColor,
                              liquidationDistance: n.liquidationDistance,
                            ),
                            const SizedBox(height: 16),
                            _LeverageMeter(
                              leverage: n.leverage,
                              color: n.riskColor,
                            ),
                          ],
                        );
                      }),
                      const SizedBox(height: 16),
                      const _MaxDrawdownCard(),
                      const SizedBox(height: 16),
                      const _RiskTips(),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Calculator card (sliders) ─────────────────────────────────────────────────

class _CalculatorCard extends StatelessWidget {
  final double capital, leverage, riskPercent;
  final ValueChanged<double> onCapitalChanged, onLeverageChanged, onRiskChanged;

  const _CalculatorCard({
    required this.capital,
    required this.leverage,
    required this.riskPercent,
    required this.onCapitalChanged,
    required this.onLeverageChanged,
    required this.onRiskChanged,
  });

  @override
  Widget build(BuildContext context) {
    final riskColor = leverage <= 3
        ? AppColors.brandGreen
        : leverage <= 7
            ? AppColors.brandAmber
            : AppColors.brandRed;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Position Calculator'),
          const SizedBox(height: 20),
          _SliderRow(
            'Account Capital',
            '\$${capital.toInt().toString().replaceAllMapped(
                  RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                  (m) => '${m[1]},',
                )}',
            capital,
            1000,
            100000,
            1000,
            AppColors.brandGreen,
            onCapitalChanged,
          ),
          const SizedBox(height: 16),
          _SliderRow('Leverage', '${leverage.toInt()}x', leverage, 1, 20, 1,
              riskColor, onLeverageChanged),
          const SizedBox(height: 8),
          const Row(
            children: [
              _LevTag('1x Safe', AppColors.brandGreen),
              Spacer(),
              _LevTag('10x Risky', AppColors.brandAmber),
              Spacer(),
              _LevTag('20x Danger', AppColors.brandRed),
            ],
          ),
          const SizedBox(height: 16),
          _SliderRow(
              'Risk Per Trade',
              '${riskPercent.toStringAsFixed(1)}%',
              riskPercent,
              0.5,
              10,
              0.5,
              AppColors.brandGreen,
              onRiskChanged),
        ],
      ),
    );
  }
}

// ── Price inputs card ─────────────────────────────────────────────────────────

class _PriceInputsCard extends ConsumerStatefulWidget {
  const _PriceInputsCard();

  @override
  ConsumerState<_PriceInputsCard> createState() => _PriceInputsCardState();
}

class _PriceInputsCardState extends ConsumerState<_PriceInputsCard> {
  late final TextEditingController _entryCtrl;
  late final TextEditingController _stopCtrl;
  late final TextEditingController _tpCtrl;

  @override
  void initState() {
    super.initState();
    final n = ref.read(riskProvider);
    _entryCtrl =
        TextEditingController(text: n.entryPrice.toStringAsFixed(0));
    _stopCtrl =
        TextEditingController(text: n.stopLoss.toStringAsFixed(0));
    _tpCtrl =
        TextEditingController(text: n.takeProfit.toStringAsFixed(0));
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _stopCtrl.dispose();
    _tpCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Price Levels'),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _PriceField(
                  label: 'Entry Price',
                  controller: _entryCtrl,
                  onChanged: (v) => ref.read(riskProvider).setEntryPrice(v),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _PriceField(
                  label: 'Stop Loss',
                  controller: _stopCtrl,
                  color: AppColors.brandRed,
                  onChanged: (v) => ref.read(riskProvider).setStopLoss(v),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _PriceField(
                  label: 'Take Profit',
                  controller: _tpCtrl,
                  color: AppColors.brandGreen,
                  onChanged: (v) => ref.read(riskProvider).setTakeProfit(v),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PriceField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final ValueChanged<double> onChanged;
  final Color color;

  const _PriceField({
    required this.label,
    required this.controller,
    required this.onChanged,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: color,
            fontFamily: 'JetBrainsMono',
          ),
          decoration: InputDecoration(
            prefixText: '\$',
            prefixStyle:
                TextStyle(color: color.withAlpha(150), fontSize: 12),
            filled: true,
            fillColor: AppColors.bgPrimary,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.borderSubtle),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.borderSubtle),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: color),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            isDense: true,
          ),
          onChanged: (v) {
            final d = double.tryParse(v.replaceAll(',', ''));
            if (d != null) onChanged(d);
          },
        ),
      ],
    );
  }
}

// ── Results card ──────────────────────────────────────────────────────────────

class _ResultsCard extends StatelessWidget {
  final double positionSize, liquidationPrice, maxLoss;
  final String riskLevel;
  final Color riskColor;
  final bool loading;
  final bool isEstimated;

  const _ResultsCard({
    required this.positionSize,
    required this.liquidationPrice,
    required this.maxLoss,
    required this.riskLevel,
    required this.riskColor,
    required this.loading,
    required this.isEstimated,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        children: [
          if (loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      color: AppColors.brandGreen,
                      strokeWidth: 2,
                    ),
                  ),
                  SizedBox(width: 8),
                  Text('Calculating…',
                      style: TextStyle(
                          fontSize: 11, color: AppColors.textMuted)),
                ],
              ),
            ),
          Row(
            children: [
              _Metric('Position Size', '\$${positionSize.toStringAsFixed(0)}',
                  AppColors.brandGreen),
              _Metric('Liq. Price', '\$${liquidationPrice.toStringAsFixed(0)}',
                  riskColor),
              _Metric('Max Loss', '\$${maxLoss.toStringAsFixed(0)}',
                  AppColors.brandRed),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: riskColor.withAlpha(15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: riskColor.withAlpha(30)),
            ),
            child: Row(
              children: [
                const Text('Risk Level',
                    style: TextStyle(
                        fontSize: 12, color: AppColors.textMuted)),
                const Spacer(),
                if (isEstimated && !loading)
                  const Text('est. ',
                      style: TextStyle(
                          fontSize: 9, color: AppColors.textDisabled)),
                Text(riskLevel,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: riskColor)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── R:R Calculator card ───────────────────────────────────────────────────────

class _RrCard extends StatelessWidget {
  final double winRate;
  final RrResult? result;
  final bool loading;
  final String? error;
  final ValueChanged<double> onWinRateChanged;

  const _RrCard({
    required this.winRate,
    required this.result,
    required this.loading,
    required this.error,
    required this.onWinRateChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Risk:Reward Calculator'),
          const SizedBox(height: 16),
          _SliderRow(
            'Win Rate',
            '${winRate.toStringAsFixed(0)}%',
            winRate,
            10,
            100,
            5,
            AppColors.brandGreen,
            onWinRateChanged,
          ),
          const SizedBox(height: 16),
          if (loading)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    color: AppColors.brandGreen,
                    strokeWidth: 2,
                  ),
                ),
              ),
            )
          else if (result != null) ...[
            Row(
              children: [
                _Metric(
                  'R:R Ratio',
                  '${result!.riskRewardRatio.toStringAsFixed(2)}:1',
                  AppColors.brandGreen,
                ),
                _Metric(
                  'Breakeven',
                  '${result!.breakEvenWinRate.toStringAsFixed(1)}%',
                  AppColors.brandAmber,
                ),
                _Metric(
                  'Exp. Value',
                  '\$${result!.expectedValue.toStringAsFixed(0)}',
                  result!.expectedValue >= 0
                      ? AppColors.brandGreen
                      : AppColors.brandRed,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _Metric(
                  'Pot. Profit',
                  '\$${result!.potentialProfit.toStringAsFixed(0)}',
                  AppColors.brandGreen,
                ),
                _Metric(
                  'Pot. Loss',
                  '\$${result!.potentialLoss.toStringAsFixed(0)}',
                  AppColors.brandRed,
                ),
                const Expanded(child: SizedBox()),
              ],
            ),
          ] else
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  error == null
                      ? 'Set entry < take profit to calculate'
                      : 'Set price levels to calculate R:R',
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textMuted),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Max drawdown card ─────────────────────────────────────────────────────────

class _MaxDrawdownCard extends ConsumerWidget {
  const _MaxDrawdownCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async =
        ref.watch(maxDrawdownProvider(const DrawdownParams()));

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text('Max Drawdown',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white)),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.borderSubtle,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text('BTC · 30D',
                    style: TextStyle(
                        fontSize: 9, color: AppColors.textMuted)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          async.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    color: AppColors.brandGreen,
                    strokeWidth: 2,
                  ),
                ),
              ),
            ),
            error: (_, __) => const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('Could not load drawdown data',
                    style: TextStyle(
                        fontSize: 11, color: AppColors.textMuted)),
              ),
            ),
            data: (d) => Row(
              children: [
                _DrawdownMetric(
                    'Max', '-${d.maxDrawdown.toStringAsFixed(1)}%',
                    AppColors.brandRed),
                _DrawdownMetric(
                    'Average', '-${d.avgDrawdown.toStringAsFixed(1)}%',
                    AppColors.brandAmber),
                _DrawdownMetric(
                    'Current', '-${d.currentDrawdown.toStringAsFixed(1)}%',
                    AppColors.textMuted),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DrawdownMetric extends StatelessWidget {
  final String label, value;
  final Color color;
  const _DrawdownMetric(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 9, color: AppColors.textMuted),
              textAlign: TextAlign.center),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: color,
                  fontFamily: 'JetBrainsMono'),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

// ── Shared sub-widgets ────────────────────────────────────────────────────────

class _LevTag extends StatelessWidget {
  final String label;
  final Color color;
  const _LevTag(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Text(label,
        style: TextStyle(fontSize: 9, color: color.withAlpha(120)));
  }
}

class _SliderRow extends StatelessWidget {
  final String label;
  final String value;
  final double current, min, max, divisions;
  final Color color;
  final ValueChanged<double> onChanged;

  const _SliderRow(this.label, this.value, this.current, this.min, this.max,
      this.divisions, this.color, this.onChanged);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textMuted)),
          const Spacer(),
          Text(value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: color,
                fontFamily: 'JetBrainsMono',
              )),
        ]),
        SliderTheme(
          data: SliderThemeData(
            trackHeight: 3,
            activeTrackColor: color,
            inactiveTrackColor: AppColors.borderSubtle,
            thumbColor: color,
            overlayColor: color.withAlpha(20),
          ),
          child: Slider(
            value: current,
            min: min,
            max: max,
            divisions: ((max - min) / divisions).toInt(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

class _Metric extends StatelessWidget {
  final String label, value;
  final Color color;
  const _Metric(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 10, color: AppColors.textMuted)),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: color,
                fontFamily: 'JetBrainsMono',
              )),
        ],
      ),
    );
  }
}

class _AiRiskWarning extends StatelessWidget {
  final double leverage, riskPercent, liquidationDistance;
  final Color riskColor;

  const _AiRiskWarning({
    required this.leverage,
    required this.riskPercent,
    required this.riskColor,
    required this.liquidationDistance,
  });

  @override
  Widget build(BuildContext context) {
    final isHigh = leverage > 7;
    final color = isHigh ? AppColors.brandRed : AppColors.brandAmber;

    return GlassCard(
      borderColor: color.withAlpha(40),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withAlpha(20),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isHigh ? Icons.warning_rounded : Icons.info_rounded,
              color: color,
              size: 17,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isHigh ? 'AI Risk Warning' : 'AI Tip',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: color),
                ),
                const SizedBox(height: 4),
                Text(
                  isHigh
                      ? '${leverage.toInt()}x leverage is very high during current '
                          'volatility. A ${liquidationDistance.toStringAsFixed(1)}% adverse '
                          'move liquidates your position. Consider reducing to 3–5x.'
                      : 'Current leverage of ${leverage.toInt()}x is moderate. '
                          'Ensure your stop loss is set below key support.',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textMuted,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LeverageMeter extends StatelessWidget {
  final double leverage;
  final Color color;
  const _LeverageMeter({required this.leverage, required this.color});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Leverage Risk Meter',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white)),
          const SizedBox(height: 12),
          LayoutBuilder(builder: (context, constraints) {
            final trackWidth = constraints.maxWidth;
            final position = (leverage / 20).clamp(0.0, 1.0) * trackWidth - 4;
            return Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    height: 20,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.brandGreen,
                          AppColors.brandAmber,
                          AppColors.brandRed,
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: position.clamp(0.0, trackWidth - 8),
                  child: Container(
                    width: 8,
                    height: 20,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(2),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withAlpha(100),
                            blurRadius: 4)
                      ],
                    ),
                  ),
                ),
              ],
            );
          }),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text('1x Safe',
                  style: TextStyle(
                      fontSize: 9, color: AppColors.brandGreen)),
              const Spacer(),
              Text('${leverage.toInt()}x',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: color,
                    fontFamily: 'JetBrainsMono',
                  )),
              const Spacer(),
              const Text('20x Danger',
                  style: TextStyle(fontSize: 9, color: AppColors.brandRed)),
            ],
          ),
        ],
      ),
    );
  }
}

class _RiskTips extends StatelessWidget {
  const _RiskTips();

  static const _tips = [
    'Never risk more than 1–2% of capital per trade',
    'Always set stop loss before entering a position',
    'Reduce leverage during high volatility periods',
    'Use position size calculator for every trade',
  ];

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Risk Management Rules',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white)),
          const SizedBox(height: 12),
          ..._tips.map((t) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 5,
                      height: 5,
                      margin: const EdgeInsets.only(top: 5, right: 8),
                      decoration: const BoxDecoration(
                        color: AppColors.brandGreen,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Expanded(
                        child: Text(t,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textMuted,
                              height: 1.4,
                            ))),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
