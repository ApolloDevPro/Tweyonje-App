import 'package:flutter/material.dart';
import '../core/theme/theme.dart';

/// Centers [child] and caps its width so dashboards and forms stay readable on
/// tablets, desktop-web and large screens instead of stretching edge to edge.
class ResponsiveContent extends StatelessWidget {
  final Widget child;
  final double? maxWidth;

  const ResponsiveContent({super.key, required this.child, this.maxWidth});

  @override
  Widget build(BuildContext context) {
    final max = maxWidth ?? context.contentMaxWidth;
    if (!max.isFinite) return child;
    return Center(
      child: ConstrainedBox(constraints: BoxConstraints(maxWidth: max), child: child),
    );
  }
}

/// Lays out a fixed list of children into a responsive grid/wrap: one column on
/// phones, and automatically more columns as the available width grows.
class ResponsiveWrap extends StatelessWidget {
  final List<Widget> children;
  final double spacing;
  final double runSpacing;
  final double minItemWidth;

  const ResponsiveWrap({
    super.key,
    required this.children,
    this.spacing = AppSpacing.md,
    this.runSpacing = AppSpacing.md,
    this.minItemWidth = 260,
  });

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final effective = minItemWidth + spacing;
        var columns = (width + spacing) ~/ effective;
        if (columns < 1) columns = 1;
        if (columns > children.length) columns = children.length;

        final itemWidth = (width - spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: runSpacing,
          children: [
            for (final child in children)
              SizedBox(width: itemWidth, child: child),
          ],
        );
      },
    );
  }
}

/// A navigation destination shown by [ResponsiveScaffold] on larger screens.
class ResponsiveDestination {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const ResponsiveDestination({
    required this.icon,
    required this.label,
    this.onTap,
  });
}

/// Scaffold that adapts its chrome to the window size:
///  - phones (compact):  plain Scaffold, body capped/content as-is.
///  - tablets (medium):  compact destination chips pinned under the app bar.
///  - desktop (expanded): a persistent [NavigationRail] on the leading edge.
class ResponsiveScaffold extends StatelessWidget {
  final PreferredSizeWidget? appBar;
  final Widget body;
  final List<ResponsiveDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int>? onDestinationSelected;
  final Widget? floatingActionButton;
  final Color? backgroundColor;

  const ResponsiveScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.destinations = const [],
    this.selectedIndex = 0,
    this.onDestinationSelected,
    this.floatingActionButton,
    this.backgroundColor,
  });

  void _select(BuildContext context, int index) {
    final handler = onDestinationSelected;
    if (handler != null) {
      handler(index);
      return;
    }
    destinations[index].onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    final content = ResponsiveContent(child: body);
    final hasNav = destinations.isNotEmpty;

    Widget scaffoldBody = content;
    if (hasNav && context.isExpanded) {
      final showExtended = context.screenWidth >= ResponsiveBreakpoints.expanded;
      scaffoldBody = Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          NavigationRail(
            backgroundColor: AppColors.surface,
            selectedIndex: selectedIndex,
            extended: showExtended,
            onDestinationSelected: (i) => _select(context, i),
            destinations: [
              for (final d in destinations)
                NavigationRailDestination(
                  icon: Icon(d.icon),
                  selectedIcon: Icon(d.icon, color: AppColors.primary),
                  label: Text(d.label),
                ),
            ],
          ),
          const VerticalDivider(width: 1, thickness: 1),
          Expanded(child: content),
        ],
      );
    } else if (hasNav && context.isMedium) {
      scaffoldBody = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ChipNav(
            destinations: destinations,
            selectedIndex: selectedIndex,
            onSelected: (i) => _select(context, i),
          ),
          Expanded(child: content),
        ],
      );
    }

    return Scaffold(
      backgroundColor: backgroundColor ?? AppColors.background,
      appBar: appBar,
      body: scaffoldBody,
      floatingActionButton: floatingActionButton,
    );
  }
}

class _ChipNav extends StatelessWidget {
  final List<ResponsiveDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const _ChipNav({
    required this.destinations,
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      elevation: 1,
      child: SizedBox(
        height: 52,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          itemCount: destinations.length,
          separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
          itemBuilder: (context, i) {
            final d = destinations[i];
            final selected = i == selectedIndex;
            return Center(
              child: ChoiceChip(
                avatar: Icon(d.icon, size: 18),
                label: Text(d.label),
                selected: selected,
                selectedColor: AppColors.primarySoft,
                labelStyle: AppTypography.labelSmall.copyWith(
                  color: selected ? AppColors.primaryDark : AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
                showCheckmark: false,
                onSelected: (_) => onSelected(i),
              ),
            );
          },
        ),
      ),
    );
  }
}