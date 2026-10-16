import 'package:flutter/material.dart';
import '../../core/theme/theme.dart';

/// User-facing Terms of Service (read-only).
class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Terms of Service'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: const [
          _Section(
            title: '1. Acceptance of Terms',
            body:
                'By creating a Tweyonje account or using the Tweyonje mobile '
                'application, you agree to be bound by these Terms of Service '
                'and our Privacy Policy. If you do not agree, please do not use '
                'the service.',
          ),
          _Section(
            title: '2. Your Account',
            body:
                'You must provide accurate information when registering, '
                'including a valid email address and phone number. You are '
                'responsible for keeping your password confidential and for '
                'all activity that occurs under your account. Self-service '
                'registration is available for Resident and Business accounts; '
                'Collector, Recycler, Authority, and Administrator roles '
                'require verification by Tweyonje administrators.',
          ),
          _Section(
            title: '3. Waste Collection Services',
            body:
                'Tweyonje connects residents and businesses with independent '
                'waste collectors and recyclers. Collection times, prices, and '
                'availability may vary by zone. You agree to be present or '
                'provide safe access for scheduled pickups and to describe '
                'your waste accurately when placing a request.',
          ),
          _Section(
            title: '4. Payments and Fees',
            body:
                'Payments are processed through MTN Mobile Money, Airtel '
                'Money, and supported card providers. All prices are quoted in '
                'Ugandan Shillings (UGX). Completed payments are non-'
                'refundable except where a dispute is resolved in your favour '
                'through our dispute process.',
          ),
          _Section(
            title: '5. Eco-Points and Rewards',
            body:
                'Eco-points are earned for qualifying recycling and responsible '
                'waste-disposal activity. Points have no cash value, are '
                'non-transferable, and may expire or be adjusted if obtained '
                'through fraud or abuse of the platform.',
          ),
          _Section(
            title: '6. Prohibited Conduct',
            body:
                'You may not dump waste illegally, submit false reports, '
                'harass collectors or other users, tamper with the app, or use '
                'Tweyonje for any unlawful purpose. Violations may result in '
                'suspension or permanent account termination and referral to '
                'the relevant authorities.',
          ),
          _Section(
            title: '7. Location Data',
            body:
                'Real-time location sharing is only active during an ongoing '
                'collection so residents can track their collector. You can '
                'revoke location permission at any time through your device '
                'settings.',
          ),
          _Section(
            title: '8. Limitation of Liability',
            body:
                'Tweyonje provides the platform on an "as is" basis. To the '
                'maximum extent permitted by law, Tweyonje is not liable for '
                'indirect, incidental, or consequential damages arising from '
                'use of the service, including missed pickups or delays by '
                'independent collectors.',
          ),
          _Section(
            title: '9. Changes to These Terms',
            body:
                'We may update these Terms from time to time. Continued use of '
                'Tweyonje after an update constitutes acceptance of the new '
                'Terms. The version you consented to at registration is stored '
                'with your account.',
          ),
          _Section(
            title: '10. Contact',
            body:
                'Questions about these Terms can be sent to '
                'support@tweyonje.ug.',
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final String body;

  const _Section({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTypography.h4.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            body,
            style: AppTypography.body.copyWith(
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
