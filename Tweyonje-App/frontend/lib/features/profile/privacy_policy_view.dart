import 'package:flutter/material.dart';
import '../../core/theme/theme.dart';
import '../../widgets/widgets.dart';

/// User-facing privacy policy (read-only). The admin flow has its own
/// management screen (`admin/privacy_policy_screen.dart`).
class PrivacyPolicyView extends StatelessWidget {
  const PrivacyPolicyView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Privacy Policy & Terms'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _PolicySection(
            title: '1. Information We Collect',
            children: [
              _PolicyText(
                'Tweyonje collects the information you provide when creating an '
                'account (name, email, phone number) and information generated '
                'through app usage such as waste collection requests, location '
                'data during active collections, payments, and ratings.',
              ),
            ],
          ),
          SizedBox(height: AppSpacing.xl),
          _PolicySection(
            title: '2. How We Use Your Information',
            children: [
              _PolicyText(
                'We use your information to connect you with waste collectors, '
                'process payments via MTN Mobile Money, Airtel Money, and cards, '
                'award eco-points, improve our routing and AI classification, '
                'and send service notifications you have opted into.',
              ),
            ],
          ),
          SizedBox(height: AppSpacing.xl),
          _PolicySection(
            title: '3. Location and GPS Data',
            children: [
              _PolicyText(
                'Real-time location sharing is only active while a collection or '
                'delivery is in progress so residents can track their collector. '
                'You can revoke location permission anytime in your device '
                'settings.',
              ),
            ],
          ),
          SizedBox(height: AppSpacing.xl),
          _PolicySection(
            title: '4. Data Sharing',
            children: [
              _PolicyText(
                'We never sell your personal data. Information is shared only '
                'with the collector assigned to your request, payment providers '
                'to process transactions, and public authorities where required '
                'by law or to investigate reports of illegal dumping.',
              ),
            ],
          ),
          SizedBox(height: AppSpacing.xl),
          _PolicySection(
            title: '5. Security',
            children: [
              _PolicyText(
                'We protect your account with encrypted storage for your session '
                'tokens and optional biometric sign-in. Always keep your password '
                'confidential and report any suspicious activity to our support '
                'desk.',
              ),
            ],
          ),
          SizedBox(height: AppSpacing.xl),
          _PolicySection(
            title: '6. Your Rights',
            children: [
              _PolicyText(
                'You may request to access, correct, export, or delete your '
                'personal data at any time from the app or by contacting '
                'support@tweyonje.ug.',
              ),
            ],
          ),
          SizedBox(height: AppSpacing.xl),
          AppCard(
            child: Text(
              'By using Tweyonje you agree to the collection and use of your '
              'information as described above. This policy was last updated on '
              'September 2026.',
              style: AppTypography.bodySmall,
            ),
          ),
          SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }
}

class _PolicySection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _PolicySection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTypography.h5.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.md),
          ...children,
        ],
      ),
    );
  }
}

class _PolicyText extends StatelessWidget {
  final String text;

  const _PolicyText(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTypography.body.copyWith(
        color: AppColors.textSecondary,
        height: 1.5,
      ),
    );
  }
}