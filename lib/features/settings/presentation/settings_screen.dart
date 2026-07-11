import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/providers/settings_provider.dart';
import '../../../shared/providers/history_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final LocalAuthentication _localAuth = LocalAuthentication();
  bool _biometricsAvailable = false;
  bool _biometricsChecked = false;

  @override
  void initState() {
    super.initState();
    _checkBiometrics();
  }

  Future<void> _checkBiometrics() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      if (mounted) {
        setState(() {
          _biometricsAvailable = canCheck && isDeviceSupported;
          _biometricsChecked = true;
        });
      }
    } on PlatformException {
      if (mounted) {
        setState(() {
          _biometricsAvailable = false;
          _biometricsChecked = true;
        });
      }
    }
  }

  // ── Currency Dialog ────────────────────────────────────────────────────────

  void _showCurrencyDialog(String currentCode) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.border),
        ),
        title: const Text(
          'Select Currency',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: AppConstants.currencies.length,
            itemBuilder: (_, i) {
              final c = AppConstants.currencies[i];
              final isSelected = c['code'] == currentCode;
              return ListTile(
                onTap: () {
                  ref
                      .read(settingsProvider.notifier)
                      .setCurrency(c['code']!, c['symbol']!);
                  Navigator.of(ctx).pop();
                },
                leading: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary.withValues(alpha: 0.15)
                        : AppColors.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary.withValues(alpha: 0.5)
                          : AppColors.border,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      c['symbol']!,
                      style: TextStyle(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.textSecondary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                title: Text(
                  c['name']!,
                  style: TextStyle(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.textPrimary,
                    fontWeight:
                        isSelected ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                subtitle: Text(
                  c['code']!,
                  style: const TextStyle(
                      color: AppColors.textHint, fontSize: 12),
                ),
                trailing: isSelected
                    ? const Icon(Icons.check_circle_rounded,
                        color: AppColors.primary, size: 20)
                    : null,
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textHint),
            ),
          ),
        ],
      ),
    );
  }

  // ── Max History Dialog ─────────────────────────────────────────────────────

  void _showMaxHistoryDialog(int current) {
    const options = [50, 100, 200, 500];

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.border),
        ),
        title: const Text(
          'Max History Size',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: options.map((opt) {
            final isSelected = opt == current;
            return ListTile(
              onTap: () {
                ref
                    .read(settingsProvider.notifier)
                    .setMaxHistory(opt);
                Navigator.of(ctx).pop();
              },
              title: Text(
                '$opt calculations',
                style: TextStyle(
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.textPrimary,
                  fontWeight:
                      isSelected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 14,
                ),
              ),
              trailing: isSelected
                  ? const Icon(Icons.check_circle_rounded,
                      color: AppColors.primary, size: 20)
                  : null,
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textHint),
            ),
          ),
        ],
      ),
    );
  }

  // ── Clear History ──────────────────────────────────────────────────────────

  Future<void> _confirmClearHistory() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.border),
        ),
        title: const Text(
          'Clear History',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        content: const Text(
          'All saved calculation history will be permanently deleted. This cannot be undone.',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textHint),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              'Clear',
              style: TextStyle(
                color: AppColors.error,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await ref.read(historyProvider.notifier).clearAll();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('History cleared successfully'),
            backgroundColor: AppColors.surface,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  void _showComingSoon() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.info_outline_rounded,
                color: AppColors.primary, size: 18),
            SizedBox(width: 10),
            Text(
              'Coming Soon',
              style: TextStyle(color: AppColors.textPrimary),
            ),
          ],
        ),
        backgroundColor: AppColors.card,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        centerTitle: false,
        title: const Text(
          'Settings',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w800,
            fontSize: 22,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.border),
        ),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
        children: [
          // ── APPEARANCE ─────────────────────────────────────────────────────
          const _SectionHeader(title: 'Appearance'),
          const SizedBox(height: 10),
          _SettingCard(
            icon: Icons.dark_mode_rounded,
            iconColor: AppColors.accent,
            title: 'Theme',
            subtitle: 'Always Dark (ShyBlack)',
            trailing: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.25)),
              ),
              child: const Text(
                'Dark',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          _SettingCard(
            icon: Icons.currency_exchange_rounded,
            iconColor: AppColors.savings,
            title: 'Currency',
            subtitle: '${settings.currency} — ${settings.currencySymbol}',
            trailing: const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textHint,
              size: 20,
            ),
            onTap: () => _showCurrencyDialog(settings.currency),
          ),

          // ── SECURITY ───────────────────────────────────────────────────────
          const SizedBox(height: 24),
          const _SectionHeader(title: 'Security'),
          const SizedBox(height: 10),
          _SettingCard(
            icon: Icons.fingerprint_rounded,
            iconColor: AppColors.investment,
            title: 'Biometric Lock',
            subtitle: _biometricsChecked
                ? (_biometricsAvailable
                    ? 'Lock app with fingerprint or face'
                    : 'Not available on this device')
                : 'Checking availability...',
            trailing: _biometricsChecked
                ? Switch(
                    value: _biometricsAvailable && settings.biometricEnabled,
                    onChanged: _biometricsAvailable
                        ? (val) => ref
                            .read(settingsProvider.notifier)
                            .setBiometric(val)
                        : null,
                    activeThumbColor: AppColors.primary,
                    activeTrackColor: AppColors.primary.withValues(alpha: 0.25),
                    inactiveThumbColor: AppColors.textHint,
                    inactiveTrackColor: AppColors.border,
                  )
                : const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.textHint,
                    ),
                  ),
          ),

          // ── CALCULATIONS ───────────────────────────────────────────────────
          const SizedBox(height: 24),
          const _SectionHeader(title: 'Calculations'),
          const SizedBox(height: 10),
          _SettingCard(
            icon: Icons.bar_chart_rounded,
            iconColor: AppColors.tax,
            title: 'Show Charts',
            subtitle: 'Display visual charts with results',
            trailing: Switch(
              value: settings.showCalculationChart,
              onChanged: (val) =>
                  ref.read(settingsProvider.notifier).setShowChart(val),
              activeThumbColor: AppColors.primary,
              activeTrackColor: AppColors.primary.withValues(alpha: 0.25),
              inactiveThumbColor: AppColors.textHint,
              inactiveTrackColor: AppColors.border,
            ),
          ),
          const SizedBox(height: 8),
          _SettingCard(
            icon: Icons.vibration_rounded,
            iconColor: AppColors.business,
            title: 'Haptic Feedback',
            subtitle: 'Vibrate on button press',
            trailing: Switch(
              value: settings.hapticFeedback,
              onChanged: (val) =>
                  ref.read(settingsProvider.notifier).setHaptic(val),
              activeThumbColor: AppColors.primary,
              activeTrackColor: AppColors.primary.withValues(alpha: 0.25),
              inactiveThumbColor: AppColors.textHint,
              inactiveTrackColor: AppColors.border,
            ),
          ),
          const SizedBox(height: 8),
          _SettingCard(
            icon: Icons.history_rounded,
            iconColor: AppColors.utility,
            title: 'Max History',
            subtitle: 'Keep up to ${settings.maxHistory} calculations',
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.utility.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: AppColors.utility.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    '${settings.maxHistory}',
                    style: const TextStyle(
                      color: AppColors.utility,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.chevron_right_rounded,
                    color: AppColors.textHint, size: 20),
              ],
            ),
            onTap: () => _showMaxHistoryDialog(settings.maxHistory),
          ),

          // ── DATA ───────────────────────────────────────────────────────────
          const SizedBox(height: 24),
          const _SectionHeader(title: 'Data'),
          const SizedBox(height: 10),
          _SettingCard(
            icon: Icons.delete_outline_rounded,
            iconColor: AppColors.error,
            title: 'Clear History',
            subtitle: 'Delete all saved calculations',
            trailing: const Icon(Icons.chevron_right_rounded,
                color: AppColors.textHint, size: 20),
            onTap: _confirmClearHistory,
          ),
          const SizedBox(height: 8),
          _SettingCard(
            icon: Icons.upload_file_rounded,
            iconColor: AppColors.info,
            title: 'Export Data',
            subtitle: 'Export your calculation history',
            trailing: const Icon(Icons.chevron_right_rounded,
                color: AppColors.textHint, size: 20),
            onTap: _showComingSoon,
          ),

          // ── ABOUT ──────────────────────────────────────────────────────────
          const SizedBox(height: 24),
          const _SectionHeader(title: 'About'),
          const SizedBox(height: 10),
          _SettingCard(
            icon: Icons.info_outline_rounded,
            iconColor: AppColors.primary,
            title: 'App Version',
            subtitle: AppConstants.appVersion,
            trailing: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.25)),
              ),
              child: const Text(
                'v${AppConstants.appVersion}',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          const _SettingCard(
            icon: Icons.calculate_rounded,
            iconColor: AppColors.primary,
            title: 'App Name',
            subtitle: 'ShyBlack Financial Calculator',
          ),
          const SizedBox(height: 20),
          // Brand footer
          _BrandFooter(),
        ],
      ),
    );
  }
}

// ─── Section Header ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 18,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(2),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.4),
                blurRadius: 6,
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title.toUpperCase(),
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }
}

// ─── Setting Card ─────────────────────────────────────────────────────────────

class _SettingCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        splashColor: AppColors.primary.withValues(alpha: 0.04),
        highlightColor: AppColors.primary.withValues(alpha: 0.04),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              // Icon container
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: iconColor.withValues(alpha: 0.25)),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 14),
              // Title + subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppColors.textHint,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 8),
                trailing!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Brand Footer ─────────────────────────────────────────────────────────────

class _BrandFooter extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/icons/logo.png',
                width: 32,
                height: 32,
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'ShyBlack Financial Calculator',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Designed with passion for financial freedom',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textHint,
              fontSize: 12,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.5),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'v${AppConstants.appVersion}',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
