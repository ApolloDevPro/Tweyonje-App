import 'package:flutter/material.dart';

/// Password strength levels
enum PasswordStrength {
  weak,
  medium,
  strong,
  veryStrong,
}

/// Password strength indicator widget with validation hints
class PasswordStrengthMeter extends StatelessWidget {
  final String password;
  final bool showHints;

  const PasswordStrengthMeter({
    super.key,
    required this.password,
    this.showHints = true,
  });

  @override
  Widget build(BuildContext context) {
    final result = _calculateStrength(password);
    final strength = result['strength'] as PasswordStrength;
    final checks = result['checks'] as Map<String, bool>;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Strength bar
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: _getStrengthValue(strength),
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _getStrengthColor(strength),
                  ),
                  minHeight: 8,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              _getStrengthLabel(strength),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _getStrengthColor(strength),
              ),
            ),
          ],
        ),
        
        if (showHints && password.isNotEmpty) ...[
          const SizedBox(height: 12),
          _buildRequirementsList(checks),
        ],
      ],
    );
  }

  Widget _buildRequirementsList(Map<String, bool> checks) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildRequirementItem(
          'At least 8 characters',
          checks['length']!,
        ),
        _buildRequirementItem(
          'Contains uppercase letter (A-Z)',
          checks['uppercase']!,
        ),
        _buildRequirementItem(
          'Contains lowercase letter (a-z)',
          checks['lowercase']!,
        ),
        _buildRequirementItem(
          'Contains number (0-9)',
          checks['number']!,
        ),
        _buildRequirementItem(
          'Contains special character (!@#\$%^&*)',
          checks['special']!,
        ),
      ],
    );
  }

  Widget _buildRequirementItem(String text, bool isMet) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            isMet ? Icons.check_circle : Icons.cancel,
            size: 16,
            color: isMet ? Colors.green : Colors.grey,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: isMet ? Colors.green[700] : Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _calculateStrength(String password) {
    if (password.isEmpty) {
      return {
        'strength': PasswordStrength.weak,
        'checks': {
          'length': false,
          'uppercase': false,
          'lowercase': false,
          'number': false,
          'special': false,
        }
      };
    }

    final checks = {
      'length': password.length >= 8,
      'uppercase': password.contains(RegExp(r'[A-Z]')),
      'lowercase': password.contains(RegExp(r'[a-z]')),
      'number': password.contains(RegExp(r'[0-9]')),
      'special': password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]')),
    };

    final metCount = checks.values.where((met) => met).length;

    PasswordStrength strength;
    if (metCount <= 2) {
      strength = PasswordStrength.weak;
    } else if (metCount == 3) {
      strength = PasswordStrength.medium;
    } else if (metCount == 4) {
      strength = PasswordStrength.strong;
    } else {
      strength = PasswordStrength.veryStrong;
    }

    return {
      'strength': strength,
      'checks': checks,
    };
  }

  double _getStrengthValue(PasswordStrength strength) {
    switch (strength) {
      case PasswordStrength.weak:
        return 0.25;
      case PasswordStrength.medium:
        return 0.5;
      case PasswordStrength.strong:
        return 0.75;
      case PasswordStrength.veryStrong:
        return 1.0;
    }
  }

  Color _getStrengthColor(PasswordStrength strength) {
    switch (strength) {
      case PasswordStrength.weak:
        return Colors.red;
      case PasswordStrength.medium:
        return Colors.orange;
      case PasswordStrength.strong:
        return Colors.blue;
      case PasswordStrength.veryStrong:
        return Colors.green;
    }
  }

  String _getStrengthLabel(PasswordStrength strength) {
    switch (strength) {
      case PasswordStrength.weak:
        return 'Weak';
      case PasswordStrength.medium:
        return 'Medium';
      case PasswordStrength.strong:
        return 'Strong';
      case PasswordStrength.veryStrong:
        return 'Very Strong';
    }
  }
}

/// Validator function for password text field
String? validatePasswordStrength(String? value) {
  if (value == null || value.isEmpty) {
    return 'Password is required';
  }

  if (value.length < 8) {
    return 'Password must be at least 8 characters';
  }

  if (!value.contains(RegExp(r'[A-Z]'))) {
    return 'Password must contain at least one uppercase letter';
  }

  if (!value.contains(RegExp(r'[a-z]'))) {
    return 'Password must contain at least one lowercase letter';
  }

  if (!value.contains(RegExp(r'[0-9]'))) {
    return 'Password must contain at least one number';
  }

  if (!value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
    return 'Password must contain at least one special character';
  }

  return null; // Password is valid
}

/// Password text field with built-in strength meter
class PasswordFieldWithStrengthMeter extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final FormFieldValidator<String>? validator;
  final bool showStrengthMeter;

  const PasswordFieldWithStrengthMeter({
    super.key,
    required this.controller,
    this.label = 'Password',
    this.hint,
    this.validator,
    this.showStrengthMeter = true,
  });

  @override
  State<PasswordFieldWithStrengthMeter> createState() => 
      _PasswordFieldWithStrengthMeterState();
}

class _PasswordFieldWithStrengthMeterState 
    extends State<PasswordFieldWithStrengthMeter> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: widget.controller,
          obscureText: _obscureText,
          validator: widget.validator ?? validatePasswordStrength,
          decoration: InputDecoration(
            labelText: widget.label,
            hintText: widget.hint ?? 'Enter a strong password',
            border: const OutlineInputBorder(),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureText ? Icons.visibility : Icons.visibility_off,
              ),
              onPressed: () {
                setState(() {
                  _obscureText = !_obscureText;
                });
              },
            ),
          ),
          onChanged: (value) {
            setState(() {}); // Rebuild to update strength meter
          },
        ),
        
        if (widget.showStrengthMeter) ...[
          const SizedBox(height: 12),
          PasswordStrengthMeter(
            password: widget.controller.text,
            showHints: true,
          ),
        ],
      ],
    );
  }
}
