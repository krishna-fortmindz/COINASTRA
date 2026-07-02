import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/glass_card.dart';
import '../../providers/profile_provider.dart';
import '../../providers/auth_provider.dart';

// Outer build is static — ProfileCard, SubscriptionCard, ExchangeConnections never rebuild
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: LayoutBuilder(builder: (_, c) {
          const leftColumn = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ProfileCard(),
              SizedBox(height: 16),
              _SubscriptionCard(),
              SizedBox(height: 16),
              _ExchangeConnections(),
            ],
          );

          final rightColumn = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Consumer(
                builder: (_, ref, __) {
                  final darkMode = ref.watch(profileProvider.select((n) => n.darkMode));
                  final notifications = ref.watch(profileProvider.select((n) => n.notifications));
                  return _SettingsCard(
                    darkMode: darkMode,
                    notifications: notifications,
                    onDarkChanged: (v) => ref.read(profileProvider).setDarkMode(v),
                    onNotifChanged: (v) => ref.read(profileProvider).setNotifications(v),
                  );
                },
              ),
              const SizedBox(height: 16),
              Consumer(
                builder: (_, ref, __) {
                  final twoFA = ref.watch(profileProvider.select((n) => n.twoFA));
                  return _SecurityCard(
                    twoFA: twoFA,
                    onTwoFAChanged: (v) => ref.read(profileProvider).setTwoFA(v),
                  );
                },
              ),
              const SizedBox(height: 16),
              Consumer(
                builder: (_, ref, __) {
                  final personality = ref.watch(profileProvider.select((n) => n.aiPersonality));
                  return _AiPersonalizationCard(
                    personality: personality,
                    onChanged: (v) => ref.read(profileProvider).setAiPersonality(v),
                  );
                },
              ),
            ],
          );

          if (c.maxWidth < 700) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                leftColumn,
                const SizedBox(height: 16),
                rightColumn,
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: leftColumn),
              const SizedBox(width: 16),
              Expanded(child: rightColumn),
            ],
          );
        }),
      ),
    );
  }
}

class _ProfileCard extends ConsumerWidget {
  const _ProfileCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final user = authState.user;
    final name = user?.name ?? 'Guest';
    final email = user?.email ?? '';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'G';

    return GlassCard(
      child: Row(
        children: [
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(
              gradient: AppColors.gradientGreen,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(child: Text(initial, style: const TextStyle(
              fontSize: 20, fontWeight: FontWeight.w800, color: Colors.black,
            ))),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white,
                )),
                if (email.isNotEmpty) Text(email, style: const TextStyle(
                  fontSize: 12, color: AppColors.textMuted,
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SubscriptionCard extends StatelessWidget {
  const _SubscriptionCard();

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderColor: AppColors.brandGreen.withAlpha(30),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: AppColors.brandGreen.withAlpha(15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.workspace_premium_rounded,
                color: AppColors.brandGreen, size: 20),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Subscription', style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white,
                )),
                SizedBox(height: 2),
                Text('Plan details coming soon', style: TextStyle(
                  fontSize: 11, color: AppColors.textMuted,
                )),
              ],
            ),
          ),
          NeonBadge(label: 'Active', color: AppColors.brandGreen),
        ],
      ),
    );
  }
}

class _ExchangeConnections extends StatelessWidget {
  const _ExchangeConnections();

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Connected Exchanges', style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white,
              )),
              const Spacer(),
              GestureDetector(
                onTap: () {},
                child: const Row(
                  children: [
                    Icon(Icons.add_rounded, size: 14, color: AppColors.brandGreen),
                    SizedBox(width: 4),
                    Text('Connect', style: TextStyle(
                      fontSize: 11, color: AppColors.brandGreen,
                      fontWeight: FontWeight.w600,
                    )),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _ExchangeRow('Binance', true, 'Read-only'),
          _ExchangeRow('Bybit', false, 'Not connected'),
          _ExchangeRow('OKX', false, 'Not connected'),
        ],
      ),
    );
  }
}

class _ExchangeRow extends StatelessWidget {
  final String name, status;
  final bool connected;
  const _ExchangeRow(this.name, this.connected, this.status);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: AppColors.bgTertiary,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Center(child: Text(name[0], style: const TextStyle(
              fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white,
            ))),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontSize: 13, color: Colors.white)),
                Text(status, style: TextStyle(
                  fontSize: 10,
                  color: connected ? AppColors.brandGreen : AppColors.textDisabled,
                )),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: (connected ? AppColors.brandGreen : AppColors.textDisabled)
                  .withAlpha(20),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              connected ? 'Connected' : 'Connect',
              style: TextStyle(
                fontSize: 10, fontWeight: FontWeight.w600,
                color: connected ? AppColors.brandGreen : AppColors.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final bool darkMode, notifications;
  final ValueChanged<bool> onDarkChanged, onNotifChanged;

  const _SettingsCard({
    required this.darkMode, required this.notifications,
    required this.onDarkChanged, required this.onNotifChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Preferences', style: TextStyle(
            fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white,
          )),
          const SizedBox(height: 12),
          _ToggleRow('Dark Mode', darkMode, onDarkChanged, Icons.dark_mode_rounded),
          _ToggleRow('Push Notifications', notifications, onNotifChanged,
            Icons.notifications_rounded),
        ],
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  final IconData icon;
  const _ToggleRow(this.label, this.value, this.onChanged, this.icon);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textMuted),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: const TextStyle(
            fontSize: 12, color: AppColors.textMuted,
          ))),
          Switch(
            value: value, onChanged: onChanged,
            activeColor: AppColors.brandGreen,
            inactiveTrackColor: AppColors.borderSubtle,
            trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
          ),
        ],
      ),
    );
  }
}

class _SecurityCard extends StatelessWidget {
  final bool twoFA;
  final ValueChanged<bool> onTwoFAChanged;
  const _SecurityCard({required this.twoFA, required this.onTwoFAChanged});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Security', style: TextStyle(
            fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white,
          )),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.security_rounded, size: 16, color: AppColors.textMuted),
              const SizedBox(width: 10),
              const Expanded(child: Text('Two-Factor Auth', style: TextStyle(
                fontSize: 12, color: AppColors.textMuted,
              ))),
              Switch(
                value: twoFA, onChanged: onTwoFAChanged,
                activeColor: AppColors.brandGreen,
                inactiveTrackColor: AppColors.borderSubtle,
                trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
              ),
            ],
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () {},
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.bgTertiary,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: const Row(
                children: [
                  Icon(Icons.lock_outline_rounded, size: 15, color: AppColors.textMuted),
                  SizedBox(width: 8),
                  Text('Change Password', style: TextStyle(
                    fontSize: 12, color: AppColors.textMuted,
                  )),
                  Spacer(),
                  Icon(Icons.arrow_forward_ios_rounded, size: 12, color: AppColors.textDisabled),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AiPersonalizationCard extends StatelessWidget {
  final String personality;
  final ValueChanged<String> onChanged;
  const _AiPersonalizationCard({required this.personality, required this.onChanged});

  static const _options = ['Direct', 'Analytical', 'Conservative', 'Educational'];

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('AI Personality', style: TextStyle(
            fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white,
          )),
          const SizedBox(height: 4),
          const Text('How should the AI communicate with you?', style: TextStyle(
            fontSize: 11, color: AppColors.textMuted,
          )),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: _options.map((o) => GestureDetector(
              onTap: () => onChanged(o),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: personality == o
                      ? AppColors.brandGreen.withAlpha(20)
                      : AppColors.bgTertiary,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: personality == o
                        ? AppColors.brandGreen.withAlpha(60)
                        : AppColors.borderSubtle,
                  ),
                ),
                child: Text(o, style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w500,
                  color: personality == o ? AppColors.brandGreen : AppColors.textMuted,
                )),
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }
}
