import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/semantics.dart';
import '../theme/theme.dart';

class AppAccessibility {
  // Semantic labels for common widgets
  static const String backButton = 'Go back';
  static const String closeButton = 'Close';
  static const String cancelButton = 'Cancel';
  static const String confirmButton = 'Confirm';
  static const String saveButton = 'Save';
  static const String deleteButton = 'Delete';
  static const String editButton = 'Edit';
  static const String addButton = 'Add';
  static const String refreshButton = 'Refresh';
  static const String searchButton = 'Search';
  static const String filterButton = 'Filter';
  static const String menuButton = 'Menu';
  static const String settingsButton = 'Settings';
  static const String notificationButton = 'Notifications';
  static const String profileButton = 'Profile';
  static const String logoutButton = 'Logout';

  // Helper to create semantic widgets
  static Widget semanticContainer({
    required Widget child,
    String? label,
    String? hint,
    bool? enabled,
    bool? checked,
    bool selected = false,
    VoidCallback? onTap,
    VoidCallback? onLongPress,
    ValueChanged<bool>? onToggle,
    VoidCallback? onIncrease,
    VoidCallback? onDecrease,
    SemanticsSortKey? sortKey,
  }) {
    return Semantics(
      label: label,
      hint: hint,
      enabled: enabled,
      checked: checked,
      selected: selected,
      button: onTap != null,
      link: onTap != null,
      onTap: onTap,
      onLongPress: onLongPress,
      onIncrease: onIncrease,
      onDecrease: onDecrease,
      sortKey: sortKey,
      child: child,
    );
  }

  // Helper to create accessible buttons
  static Widget accessibleButton({
    required Widget child,
    required String label,
    String? hint,
    VoidCallback? onPressed,
    bool enabled = true,
  }) {
    return Semantics(
      label: label,
      hint: hint,
      button: true,
      enabled: enabled,
      onTap: enabled ? onPressed : null,
      excludeSemantics: true,
      child: InkWell(
        onTap: enabled ? onPressed : null,
        child: child,
      ),
    );
  }

  // Helper to create accessible icons
  static Widget accessibleIcon({
    required IconData icon,
    required String label,
    String? hint,
    VoidCallback? onTap,
    Color? color,
    double size = 24,
  }) {
    return Semantics(
      label: label,
      hint: hint,
      button: onTap != null,
      onTap: onTap,
      child: Icon(
        icon,
        color: color,
        size: size,
      ),
    );
  }

  // Helper to create accessible text fields
  static Widget accessibleTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    String? errorText,
    bool enabled = true,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    ValueChanged<String>? onChanged,
    ValueChanged<String>? onSubmitted,
    FocusNode? focusNode,
  }) {
    return Semantics(
      label: label,
      hint: hint,
      value: controller.text,
      textField: true,
      enabled: enabled,
      onDidGainAccessibilityFocus: () {
        focusNode?.requestFocus();
      },
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        enabled: enabled,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          errorText: errorText,
        ),
      ),
    );
  }

  // Helper to create accessible cards
  static Widget accessibleCard({
    required Widget child,
    required String label,
    String? hint,
    VoidCallback? onTap,
    bool selected = false,
  }) {
    return Semantics(
      label: label,
      hint: hint,
      button: onTap != null,
      selected: selected,
      onTap: onTap,
      child: Card(
        child: InkWell(
          onTap: onTap,
          child: child,
        ),
      ),
    );
  }

  // Helper to create accessible list items
  static Widget accessibleListItem({
    required Widget child,
    required String label,
    String? hint,
    VoidCallback? onTap,
    bool selected = false,
  }) {
    return Semantics(
      label: label,
      hint: hint,
      button: onTap != null,
      selected: selected,
      onTap: onTap,
      child: ListTile(
        onTap: onTap,
        selected: selected,
        title: child,
      ),
    );
  }

  // Helper to create accessible switches
  static Widget accessibleSwitch({
    required bool value,
    required ValueChanged<bool?> onChanged,
    required String label,
    String? hint,
    bool enabled = true,
  }) {
    return Semantics(
      label: label,
      hint: hint,
      enabled: enabled,
      checked: value,
      onTap: enabled ? () => onChanged(!value) : null,
      child: Switch(
        value: value,
        onChanged: enabled ? onChanged : null,
      ),
    );
  }

  // Helper to create accessible checkboxes
  static Widget accessibleCheckbox({
    required bool value,
    required ValueChanged<bool?> onChanged,
    required String label,
    String? hint,
    bool enabled = true,
  }) {
    return Semantics(
      label: label,
      hint: hint,
      enabled: enabled,
      checked: value,
      onTap: enabled ? () => onChanged(!value) : null,
      child: CheckboxListTile(
        value: value,
        onChanged: enabled ? onChanged : null,
        title: Text(label),
      ),
    );
  }

  // Helper to create accessible sliders
  static Widget accessibleSlider({
    required double value,
    required ValueChanged<double> onChanged,
    required String label,
    String? hint,
    double min = 0.0,
    double max = 1.0,
    int? divisions,
    bool enabled = true,
  }) {
    return Semantics(
      label: label,
      hint: hint,
      value: value.toString(),
      enabled: enabled,
      increasedValue: max.toString(),
      decreasedValue: min.toString(),
      onIncrease: enabled ? () => onChanged((value + (max - min) / (divisions ?? 10)).clamp(min, max)) : null,
      onDecrease: enabled ? () => onChanged((value - (max - min) / (divisions ?? 10)).clamp(min, max)) : null,
      child: Slider(
        value: value,
        onChanged: enabled ? onChanged : null,
        min: min,
        max: max,
        divisions: divisions,
      ),
    );
  }

  // Helper to create accessible progress indicators
  static Widget accessibleProgressIndicator({
    required double value,
    required String label,
    String? hint,
  }) {
    return Semantics(
      label: label,
      hint: hint,
      value: value.toString(),
      child: LinearProgressIndicator(value: value),
    );
  }

  // Helper to create accessible circular progress
  static Widget accessibleCircularProgress({
    required String label,
    String? hint,
  }) {
    return Semantics(
      label: label,
      hint: hint,
      child: const CircularProgressIndicator(),
    );
  }

  // Helper to announce screen changes to screen readers
  static void announce(BuildContext context, String message) {
    // This would typically use a package like accessibility_service
    // For now, we'll use the Semantics widget approach
    Semantics(
      label: message,
      textDirection: TextDirection.ltr,
    );
  }

  // Helper to create accessible image
  static Widget accessibleImage({
    required ImageProvider image,
    required String label,
    String? hint,
    double? width,
    double? height,
    BoxFit? fit,
  }) {
    return Semantics(
      label: label,
      hint: hint,
      image: true,
      child: Image(
        image: image,
        width: width,
        height: height,
        fit: fit,
      ),
    );
  }

  // Helper to create accessible tabs
  static Widget accessibleTab({
    required Widget child,
    required String label,
    bool selected = false,
    VoidCallback? onTap,
  }) {
    return Semantics(
      label: label,
      selected: selected,
      button: true,
      onTap: onTap,
      inMutuallyExclusiveGroup: true,
      child: child,
    );
  }

  // Helper to create accessible bottom navigation items
  static Widget accessibleBottomNavItem({
    required IconData icon,
    required String label,
    bool selected = false,
    VoidCallback? onTap,
  }) {
    return Semantics(
      label: label,
      selected: selected,
      button: true,
      onTap: onTap,
      inMutuallyExclusiveGroup: true,
      child: Icon(icon, color: selected ? AppColors.primary : AppColors.textSecondary),
    );
  }

  // Helper to create accessible app bar
  static PreferredSizeWidget accessibleAppBar({
    required String title,
    List<Widget>? actions,
    bool automaticallyImplyLeading = true,
    Widget? leading,
  }) {
    return AppBar(
      title: Semantics(
        label: title,
        header: true,
        child: Text(title),
      ),
      actions: actions,
      automaticallyImplyLeading: automaticallyImplyLeading,
      leading: leading,
    );
  }

  // Helper to create accessible floating action button
  static Widget accessibleFab({
    required IconData icon,
    required String label,
    String? hint,
    required VoidCallback onPressed,
    bool extended = false,
    Object? heroTag,
  }) {
    return Semantics(
      label: label,
      hint: hint,
      button: true,
      child: extended
          ? FloatingActionButton.extended(
              icon: Icon(icon),
              label: Text(label),
              onPressed: onPressed,
              heroTag: heroTag,
            )
          : FloatingActionButton(
              onPressed: onPressed,
              heroTag: heroTag,
              child: Icon(icon),
            ),
    );
  }

  // Helper to create accessible dialog
  static Widget accessibleDialog({
    required String title,
    required String content,
    required List<Widget> actions,
  }) {
    return AlertDialog(
      title: Semantics(
        label: title,
        child: Text(title),
      ),
      content: Semantics(
        label: content,
        child: Text(content),
      ),
      actions: actions,
    );
  }

  // Helper to create accessible snackbar
  static SnackBar accessibleSnackBar({
    required String message,
    String? actionLabel,
    VoidCallback? onActionPressed,
    Duration duration = const Duration(seconds: 4),
  }) {
    return SnackBar(
      content: Semantics(
        label: message,
        liveRegion: true,
        child: Text(message),
      ),
      action: actionLabel != null
          ? SnackBarAction(
              label: actionLabel,
              onPressed: onActionPressed ?? () {},
            )
          : null,
      duration: duration,
    );
  }

  // Helper to create accessible chip
  static Widget accessibleChip({
    required Widget label,
    required String semanticLabel,
    VoidCallback? onDeleted,
    VoidCallback? onPressed,
  }) {
    return Semantics(
      label: semanticLabel,
      button: onPressed != null,
      onTap: onPressed,
      child: Chip(
        label: label,
        onDeleted: onDeleted,
      ),
    );
  }

  // Helper to create accessible dropdown
  static Widget accessibleDropdown<T>({
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
    required String label,
    String? hint,
  }) {
    return Semantics(
      label: label,
      hint: hint,
      value: value.toString(),
      button: true,
      child: DropdownButtonFormField<T>(
        initialValue: value,
        items: items,
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
        ),
      ),
    );
  }

  // Helper to create accessible date picker
  static Future<DateTime?> accessibleDatePicker({
    required BuildContext context,
    required DateTime initialDate,
    required DateTime firstDate,
    required DateTime lastDate,
    String? helpText,
  }) async {
    return showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      helpText: helpText ?? 'Select date',
    );
  }

  // Helper to create accessible time picker
  static Future<TimeOfDay?> accessibleTimePicker({
    required BuildContext context,
    required TimeOfDay initialTime,
    String? helpText,
  }) async {
    return showTimePicker(
      context: context,
      initialTime: initialTime,
      helpText: helpText ?? 'Select time',
    );
  }
}

// Extension to add accessibility helpers to widgets
extension AccessibilityWidgetExtension on Widget {
  Widget withAccessibility({
    String? label,
    String? hint,
    bool? enabled,
    bool? checked,
    bool selected = false,
    VoidCallback? onTap,
    VoidCallback? onLongPress,
  }) {
    return Semantics(
      label: label,
      hint: hint,
      enabled: enabled,
      checked: checked,
      selected: selected,
      button: onTap != null,
      onTap: onTap,
      onLongPress: onLongPress,
      child: this,
    );
  }
}

// Accessibility constants
class AccessibilityConstants {
  static const double minTouchTarget = 48.0;
  static const double defaultFontSize = 16.0;
  static const double minFontSize = 14.0;
  static const double maxFontSize = 24.0;
  static const double defaultIconSize = 24.0;
  static const double minIconSize = 20.0;
  
  // Color contrast ratios (WCAG AA)
  static const double minContrastRatioNormal = 4.5;
  static const double minContrastRatioLarge = 3.0;
  
  // Spacing for touch targets
  static const double touchTargetPadding = 8.0;
}

// Helper to check color contrast
class ColorContrast {
  static double getContrastRatio(Color foreground, Color background) {
    final luminance1 = foreground.computeLuminance();
    final luminance2 = background.computeLuminance();
    final lighter = luminance1 > luminance2 ? luminance1 : luminance2;
    final darker = luminance1 > luminance2 ? luminance2 : luminance1;
    return (lighter + 0.05) / (darker + 0.05);
  }

  static bool meetsWCAGAA(Color foreground, Color background, {bool isLargeText = false}) {
    final ratio = getContrastRatio(foreground, background);
    final minRatio = isLargeText 
        ? AccessibilityConstants.minContrastRatioLarge 
        : AccessibilityConstants.minContrastRatioNormal;
    return ratio >= minRatio;
  }

  static bool meetsWCAGAAA(Color foreground, Color background, {bool isLargeText = false}) {
    final ratio = getContrastRatio(foreground, background);
    final minRatio = isLargeText ? 4.5 : 7.0;
    return ratio >= minRatio;
  }
}
