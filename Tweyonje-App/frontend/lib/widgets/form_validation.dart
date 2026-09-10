import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/theme/theme.dart';
import 'app_button.dart';

enum ValidationStatus {
  initial,
  valid,
  invalid,
  validating,
}

class ValidationResult {
  final bool isValid;
  final String? errorMessage;
  final ValidationStatus status;

  const ValidationResult({
    required this.isValid,
    this.errorMessage,
    this.status = ValidationStatus.initial,
  });

  static const valid = ValidationResult(isValid: true, status: ValidationStatus.valid);
  static const validating = ValidationResult(isValid: false, status: ValidationStatus.validating);
  
  ValidationResult copyWith({
    bool? isValid,
    String? errorMessage,
    ValidationStatus? status,
  }) {
    return ValidationResult(
      isValid: isValid ?? this.isValid,
      errorMessage: errorMessage ?? this.errorMessage,
      status: status ?? this.status,
    );
  }
}

class FormValidator {
  static ValidationResult validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return const ValidationResult(
        isValid: false,
        errorMessage: 'Email is required',
        status: ValidationStatus.invalid,
      );
    }
    
    final emailRegex = RegExp(r'^[\w\.-]+@[\w\.-]+\.\w+$');
    if (!emailRegex.hasMatch(value.trim())) {
      return const ValidationResult(
        isValid: false,
        errorMessage: 'Please enter a valid email address',
        status: ValidationStatus.invalid,
      );
    }
    
    return ValidationResult.valid;
  }

  static ValidationResult validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return const ValidationResult(
        isValid: false,
        errorMessage: 'Phone number is required',
        status: ValidationStatus.invalid,
      );
    }
    
    final phoneRegex = RegExp(r'^\+?[0-9]{10,15}$');
    if (!phoneRegex.hasMatch(value.replaceAll(' ', '').replaceAll('-', ''))) {
      return const ValidationResult(
        isValid: false,
        errorMessage: 'Please enter a valid phone number',
        status: ValidationStatus.invalid,
      );
    }
    
    return ValidationResult.valid;
  }

  static ValidationResult validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return const ValidationResult(
        isValid: false,
        errorMessage: 'Password is required',
        status: ValidationStatus.invalid,
      );
    }
    
    if (value.length < 8) {
      return const ValidationResult(
        isValid: false,
        errorMessage: 'Password must be at least 8 characters',
        status: ValidationStatus.invalid,
      );
    }
    
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return const ValidationResult(
        isValid: false,
        errorMessage: 'Password must contain at least one uppercase letter',
        status: ValidationStatus.invalid,
      );
    }
    
    if (!value.contains(RegExp(r'[a-z]'))) {
      return const ValidationResult(
        isValid: false,
        errorMessage: 'Password must contain at least one lowercase letter',
        status: ValidationStatus.invalid,
      );
    }
    
    if (!value.contains(RegExp(r'[0-9]'))) {
      return const ValidationResult(
        isValid: false,
        errorMessage: 'Password must contain at least one number',
        status: ValidationStatus.invalid,
      );
    }
    
    return ValidationResult.valid;
  }

  static ValidationResult validateRequired(String? value, {String fieldName = 'This field'}) {
    if (value == null || value.trim().isEmpty) {
      return ValidationResult(
        isValid: false,
        errorMessage: '$fieldName is required',
        status: ValidationStatus.invalid,
      );
    }
    return ValidationResult.valid;
  }

  static ValidationResult validateMinLength(String? value, int minLength) {
    if (value == null || value.trim().isEmpty) {
      return const ValidationResult(
        isValid: false,
        errorMessage: 'This field is required',
        status: ValidationStatus.invalid,
      );
    }
    
    if (value.trim().length < minLength) {
      return ValidationResult(
        isValid: false,
        errorMessage: 'Must be at least $minLength characters',
        status: ValidationStatus.invalid,
      );
    }
    
    return ValidationResult.valid;
  }

  static ValidationResult validateMaxLength(String? value, int maxLength) {
    if (value != null && value.trim().length > maxLength) {
      return ValidationResult(
        isValid: false,
        errorMessage: 'Must be no more than $maxLength characters',
        status: ValidationStatus.invalid,
      );
    }
    return ValidationResult.valid;
  }

  static ValidationResult validateNumeric(String? value) {
    if (value == null || value.trim().isEmpty) {
      return const ValidationResult(
        isValid: false,
        errorMessage: 'This field is required',
        status: ValidationStatus.invalid,
      );
    }
    
    final numericRegex = RegExp(r'^\d+\.?\d*$');
    if (!numericRegex.hasMatch(value.trim())) {
      return const ValidationResult(
        isValid: false,
        errorMessage: 'Please enter a valid number',
        status: ValidationStatus.invalid,
      );
    }
    
    return ValidationResult.valid;
  }

  static ValidationResult validateRange(String? value, double min, double max) {
    final numericResult = validateNumeric(value);
    if (!numericResult.isValid) {
      return numericResult;
    }
    
    final numValue = double.tryParse(value!.trim()) ?? 0;
    if (numValue < min || numValue > max) {
      return ValidationResult(
        isValid: false,
        errorMessage: 'Must be between $min and $max',
        status: ValidationStatus.invalid,
      );
    }
    
    return ValidationResult.valid;
  }

  static ValidationResult validateMatch(String? value, String? compareValue, {String fieldName = 'Password'}) {
    if (value == null || value.trim().isEmpty) {
      return ValidationResult(
        isValid: false,
        errorMessage: 'This field is required',
        status: ValidationStatus.invalid,
      );
    }
    
    if (value != compareValue) {
      return ValidationResult(
        isValid: false,
        errorMessage: '$fieldName does not match',
        status: ValidationStatus.invalid,
      );
    }
    
    return ValidationResult.valid;
  }
}

class ValidatedTextField extends StatefulWidget {
  final String? label;
  final String? hint;
  final String? initialValue;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final bool obscureText;
  final bool enabled;
  final int? maxLines;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final VoidCallback? onSuffixIconTap;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final void Function(String)? onFieldSubmitted;
  final bool showValidationIcon;
  final bool autovalidate;
  final FocusNode? focusNode;

  const ValidatedTextField({
    super.key,
    this.label,
    this.hint,
    this.initialValue,
    this.controller,
    this.keyboardType,
    this.obscureText = false,
    this.enabled = true,
    this.maxLines = 1,
    this.maxLength,
    this.inputFormatters,
    this.prefixIcon,
    this.suffixIcon,
    this.onSuffixIconTap,
    this.validator,
    this.onChanged,
    this.onFieldSubmitted,
    this.showValidationIcon = true,
    this.autovalidate = false,
    this.focusNode,
  });

  @override
  State<ValidatedTextField> createState() => _ValidatedTextFieldState();
}

class _ValidatedTextFieldState extends State<ValidatedTextField> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  ValidationResult? _validationResult;
  bool _hasInteracted = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController(text: widget.initialValue);
    _focusNode = widget.focusNode ?? FocusNode();
    
    _controller.addListener(_onChanged);
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    _controller.removeListener(_onChanged);
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    _focusNode.removeListener(_onFocusChange);
    super.dispose();
  }

  void _onChanged() {
    if (widget.onChanged != null) {
      widget.onChanged!(_controller.text);
    }
    
    if (_hasInteracted || widget.autovalidate) {
      _validate();
    }
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus && _hasInteracted) {
      _validate();
    }
  }

  void _validate() {
    if (widget.validator == null) return;
    
    setState(() {
      final error = widget.validator!(_controller.text);
      _validationResult = ValidationResult(
        isValid: error == null,
        errorMessage: error,
        status: error == null ? ValidationStatus.valid : ValidationStatus.invalid,
      );
    });
  }

  void _onInteraction() {
    if (!_hasInteracted) {
      setState(() {
        _hasInteracted = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final showError = _validationResult != null && 
                      !_validationResult!.isValid && 
                      (_hasInteracted || widget.autovalidate);
    
    final showSuccess = _validationResult != null && 
                       _validationResult!.isValid && 
                       (_hasInteracted || widget.autovalidate);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: AppTypography.label.copyWith(
              fontWeight: FontWeight.w600,
              color: showError ? AppColors.danger : AppColors.text,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        TextField(
          controller: _controller,
          focusNode: _focusNode,
          keyboardType: widget.keyboardType,
          obscureText: widget.obscureText,
          enabled: widget.enabled,
          maxLines: widget.maxLines,
          maxLength: widget.maxLength,
          inputFormatters: widget.inputFormatters,
          onChanged: (value) {
            _onInteraction();
          },
          onSubmitted: widget.onFieldSubmitted,
          decoration: InputDecoration(
            hintText: widget.hint,
            prefixIcon: widget.prefixIcon != null 
                ? Icon(widget.prefixIcon, color: AppColors.textSecondary)
                : null,
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.showValidationIcon && showSuccess)
                  const Icon(
                    Icons.check_circle,
                    color: AppColors.success,
                    size: 20,
                  ),
                if (widget.showValidationIcon && showError)
                  const Icon(
                    Icons.error,
                    color: AppColors.danger,
                    size: 20,
                  ),
                if (widget.suffixIcon != null) ...[
                  if (widget.showValidationIcon) const SizedBox(width: 8),
                  GestureDetector(
                    onTap: widget.onSuffixIconTap,
                    child: Icon(
                      widget.suffixIcon,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
            errorText: showError ? _validationResult!.errorMessage : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: BorderSide(
                color: showError ? AppColors.danger : AppColors.border,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: BorderSide(
                color: showError ? AppColors.danger : AppColors.border,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: BorderSide(
                color: showError ? AppColors.danger : AppColors.primary,
                width: 2,
              ),
            ),
            filled: !widget.enabled,
            fillColor: AppColors.background,
          ),
        ),
      ],
    );
  }
}

class PasswordStrengthIndicator extends StatelessWidget {
  final String password;
  final bool showLabel;

  const PasswordStrengthIndicator({
    super.key,
    required this.password,
    this.showLabel = true,
  });

  @override
  Widget build(BuildContext context) {
    final strength = _calculateStrength(password);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showLabel) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Password Strength',
                style: AppTypography.caption.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                strength.label,
                style: AppTypography.caption.copyWith(
                  color: strength.color,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          child: LinearProgressIndicator(
            value: strength.value,
            backgroundColor: AppColors.background,
            valueColor: AlwaysStoppedAnimation<Color>(strength.color),
            minHeight: 4,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        _RequirementsList(password: password),
      ],
    );
  }

  _PasswordStrength _calculateStrength(String password) {
    if (password.isEmpty) {
      return _PasswordStrength(0.0, 'None', AppColors.textTertiary);
    }

    int score = 0;
    
    if (password.length >= 8) score++;
    if (password.length >= 12) score++;
    if (password.contains(RegExp(r'[A-Z]'))) score++;
    if (password.contains(RegExp(r'[a-z]'))) score++;
    if (password.contains(RegExp(r'[0-9]'))) score++;
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) score++;

    if (score <= 2) {
      return _PasswordStrength(0.33, 'Weak', AppColors.danger);
    } else if (score <= 4) {
      return _PasswordStrength(0.66, 'Medium', AppColors.warning);
    } else {
      return _PasswordStrength(1.0, 'Strong', AppColors.success);
    }
  }
}

class _RequirementsList extends StatelessWidget {
  final String password;

  const _RequirementsList({required this.password});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _RequirementItem(
          label: 'At least 8 characters',
          met: password.length >= 8,
        ),
        _RequirementItem(
          label: 'Contains uppercase letter',
          met: password.contains(RegExp(r'[A-Z]')),
        ),
        _RequirementItem(
          label: 'Contains lowercase letter',
          met: password.contains(RegExp(r'[a-z]')),
        ),
        _RequirementItem(
          label: 'Contains number',
          met: password.contains(RegExp(r'[0-9]')),
        ),
        _RequirementItem(
          label: 'Contains special character',
          met: password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]')),
        ),
      ],
    );
  }
}

class _RequirementItem extends StatelessWidget {
  final String label;
  final bool met;

  const _RequirementItem({
    required this.label,
    required this.met,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(
            met ? Icons.check_circle : Icons.circle_outlined,
            size: 16,
            color: met ? AppColors.success : AppColors.textTertiary,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: met ? AppColors.text : AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}

class _PasswordStrength {
  final double value;
  final String label;
  final Color color;

  _PasswordStrength(this.value, this.label, this.color);
}

class FormSubmitButton extends StatefulWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isLoading;
  final bool isEnabled;
  final IconData? icon;

  const FormSubmitButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.isEnabled = true,
    this.icon,
  });

  @override
  State<FormSubmitButton> createState() => _FormSubmitButtonState();
}

class _FormSubmitButtonState extends State<FormSubmitButton> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: AppButton(
        text: widget.text,
        icon: widget.icon != null 
            ? (widget.isLoading ? null : Icon(widget.icon, size: 18))
            : null,
        onPressed: widget.isEnabled && !widget.isLoading ? widget.onPressed : null,
        isLoading: widget.isLoading,
      ),
    );
  }
}
