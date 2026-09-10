import 'package:flutter/material.dart';
import '../theme/theme.dart';

class AppBranding {
  // App Identity
  static const String appName = 'Tweyonje';
  static const String tagline = 'Together for a Cleaner Uganda';
  static const String version = '1.0.0';
  
  // Contact Information
  static const String supportEmail = 'support@tweyonje.ug';
  static const String supportPhone = '+256 700 000 000';
  static const String website = 'https://tweyonje.ug';
  
  // Social Media
  static const String twitterUrl = 'https://twitter.com/tweyonje';
  static const String facebookUrl = 'https://facebook.com/tweyonje';
  static const String instagramUrl = 'https://instagram.com/tweyonje';
  
  // Legal
  static const String privacyPolicyUrl = 'https://tweyonje.ug/privacy';
  static const String termsOfServiceUrl = 'https://tweyonje.ug/terms';
  
  // Branding Colors
  static const Color primaryBrandColor = Color(0xFF2E7D32);
  static const Color secondaryBrandColor = Color(0xFF4CAF50);
  static const Color accentBrandColor = Color(0xFF81C784);
  
  // Branding Gradients
  static const LinearGradient primaryBrandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      primaryBrandColor,
      secondaryBrandColor,
    ],
  );
  
  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment(-1.0, 0.0),
    end: Alignment(1.0, 0.0),
    colors: [
      Color(0xFF2E7D32),
      Color(0xFF43A047),
      Color(0xFF66BB6A),
    ],
  );
  
  // App Logo Configuration
  static const double logoSize = 120.0;
  static const double smallLogoSize = 48.0;
  static const double mediumLogoSize = 64.0;
  static const double largeLogoSize = 96.0;
}

class AppLogo extends StatelessWidget {
  final double size;
  final Color? color;
  final bool withBackground;

  const AppLogo({
    super.key,
    this.size = AppBranding.logoSize,
    this.color,
    this.withBackground = true,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? Colors.white;
    
    if (withBackground) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          gradient: AppBranding.primaryBrandGradient,
          borderRadius: BorderRadius.circular(size * 0.25),
          boxShadow: [
            BoxShadow(
              color: AppBranding.primaryBrandColor.withAlpha(51),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Icon(
          Icons.recycling,
          size: size * 0.5,
          color: effectiveColor,
        ),
      );
    }
    
    return Icon(
      Icons.recycling,
      size: size * 0.8,
      color: color ?? AppBranding.primaryBrandColor,
    );
  }
}

class AppBrandingHeader extends StatelessWidget {
  final String? title;
  final String? subtitle;
  final bool showLogo;
  final double? logoSize;

  const AppBrandingHeader({
    super.key,
    this.title,
    this.subtitle,
    this.showLogo = true,
    this.logoSize,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (showLogo) ...[
          AppLogo(size: logoSize ?? AppBranding.mediumLogoSize),
          const SizedBox(height: AppSpacing.lg),
        ],
        Text(
          title ?? AppBranding.appName,
          style: AppTypography.h2.copyWith(
            fontWeight: FontWeight.w800,
            color: AppColors.primary,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            subtitle!,
            style: AppTypography.body.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}

class AppFooter extends StatelessWidget {
  final bool showVersion;
  final bool showSocialLinks;

  const AppFooter({
    super.key,
    this.showVersion = true,
    this.showSocialLinks = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        children: [
          if (showSocialLinks) ...[
            _SocialLinks(),
            const SizedBox(height: AppSpacing.lg),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AppLogo(size: AppBranding.smallLogoSize),
              const SizedBox(width: AppSpacing.sm),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppBranding.appName,
                    style: AppTypography.label.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    AppBranding.tagline,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          if (showVersion)
            Text(
              'Version ${AppBranding.version}',
              style: AppTypography.caption.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _FooterLink(
                label: 'Privacy Policy',
                url: AppBranding.privacyPolicyUrl,
              ),
              Text(' • ', style: AppTypography.caption),
              _FooterLink(
                label: 'Terms of Service',
                url: AppBranding.termsOfServiceUrl,
              ),
              Text(' • ', style: AppTypography.caption),
              _FooterLink(
                label: 'Contact',
                url: 'mailto:${AppBranding.supportEmail}',
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            '© ${DateTime.now().year} ${AppBranding.appName}. All rights reserved.',
            style: AppTypography.caption.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}

class _SocialLinks extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _SocialButton(
          icon: Icons.public,
          url: AppBranding.website,
          label: 'Website',
        ),
        const SizedBox(width: AppSpacing.md),
        _SocialButton(
          icon: Icons.chat_bubble,
          url: AppBranding.twitterUrl,
          label: 'Twitter',
        ),
        const SizedBox(width: AppSpacing.md),
        _SocialButton(
          icon: Icons.facebook,
          url: AppBranding.facebookUrl,
          label: 'Facebook',
        ),
      ],
    );
  }
}

class _SocialButton extends StatelessWidget {
  final IconData icon;
  final String url;
  final String label;

  const _SocialButton({
    required this.icon,
    required this.url,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        // Launch URL
      },
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.primary),
            const SizedBox(width: AppSpacing.sm),
            Text(
              label,
              style: AppTypography.label.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FooterLink extends StatelessWidget {
  final String label;
  final String url;

  const _FooterLink({
    required this.label,
    required this.url,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        // Launch URL
      },
      child: Text(
        label,
        style: AppTypography.caption.copyWith(
          color: AppColors.primary,
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }
}

class PoweredBy extends StatelessWidget {
  final bool showLogo;

  const PoweredBy({super.key, this.showLogo = true});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showLogo)
          AppLogo(
            size: 24,
            withBackground: false,
          ),
        if (showLogo) const SizedBox(width: 8),
        Text(
          'Powered by ${AppBranding.appName}',
          style: AppTypography.caption.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class BrandingCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;

  const BrandingCard({
    super.key,
    required this.child,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppBranding.brandGradient,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(
            color: AppBranding.primaryBrandColor.withAlpha(26),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: child,
          ),
        ),
      ),
    );
  }
}
