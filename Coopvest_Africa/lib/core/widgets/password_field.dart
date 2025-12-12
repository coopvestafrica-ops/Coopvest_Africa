import 'package:flutter/material.dart';

class PasswordStrength {
  final double score;
  final String message;
  final Color color;

  const PasswordStrength(this.score, this.message, this.color);

  factory PasswordStrength.calculate(String password) {
    if (password.isEmpty) {
      return PasswordStrength(0.0, 'Too weak', Colors.red);
    }

    double score = 0.0;
    String message = '';
    Color color = Colors.red;

    // Length check
    if (password.length >= 8) score += 0.2;
    if (password.length >= 12) score += 0.2;

    // Character variety checks
    if (RegExp(r'[A-Z]').hasMatch(password)) score += 0.2;
    if (RegExp(r'[a-z]').hasMatch(password)) score += 0.1;
    if (RegExp(r'[0-9]').hasMatch(password)) score += 0.15;
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) score += 0.15;

    // Determine message and color based on score
    if (score < 0.3) {
      message = 'Too weak';
      color = Colors.red;
    } else if (score < 0.6) {
      message = 'Could be stronger';
      color = Colors.orange;
    } else if (score < 0.8) {
      message = 'Strong';
      color = Colors.green;
    } else {
      message = 'Very strong';
      color = Colors.green.shade800;
    }

    return PasswordStrength(score, message, color);
  }
}

class PasswordField extends StatefulWidget {
  final TextEditingController? controller;
  final String labelText;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final bool enableInteractiveSelection;
  final TextInputAction? textInputAction;
  final void Function(String)? onFieldSubmitted;

  const PasswordField({
    super.key,
    this.controller,
    this.labelText = 'Password',
    this.validator,
    this.onChanged,
    this.enableInteractiveSelection = true,
    this.textInputAction,
    this.onFieldSubmitted,
  });

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _obscurePassword = true;
  late PasswordStrength _strength;

  @override
  void initState() {
    super.initState();
    _strength = PasswordStrength.calculate('');
  }

  void _updateStrength(String value) {
    setState(() {
      _strength = PasswordStrength.calculate(value);
    });
    widget.onChanged?.call(value);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: widget.controller,
          decoration: InputDecoration(
            labelText: widget.labelText,
            border: const OutlineInputBorder(),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off : Icons.visibility,
              ),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
            helperText: 'Password must contain: 8+ chars, uppercase, number, special char',
            helperMaxLines: 2,
          ),
          obscureText: _obscurePassword,
          enableInteractiveSelection: widget.enableInteractiveSelection,
          validator: widget.validator ?? defaultValidator,
          onChanged: _updateStrength,
          textInputAction: widget.textInputAction,
          onFieldSubmitted: widget.onFieldSubmitted,
        ),
        if (widget.controller?.text.isNotEmpty ?? false) ...[
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: _strength.score,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(_strength.color),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _strength.message,
            style: TextStyle(
              color: _strength.color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }

  String? defaultValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a password';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Password must include at least one uppercase letter';
    }
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'Password must include at least one number';
    }
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(value)) {
      return 'Password must include at least one special character';
    }
    return null;
  }
}

class ConfirmPasswordField extends StatefulWidget {
  final TextEditingController? controller;
  final String originalPassword;
  final String labelText;
  final void Function(String)? onChanged;
  final bool enableInteractiveSelection;
  final TextInputAction? textInputAction;
  final void Function(String)? onFieldSubmitted;

  const ConfirmPasswordField({
    super.key,
    this.controller,
    required this.originalPassword,
    this.labelText = 'Confirm Password',
    this.onChanged,
    this.enableInteractiveSelection = true,
    this.textInputAction,
    this.onFieldSubmitted,
  });

  @override
  State<ConfirmPasswordField> createState() => _ConfirmPasswordFieldState();
}

class _ConfirmPasswordFieldState extends State<ConfirmPasswordField> {
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      decoration: InputDecoration(
        labelText: widget.labelText,
        border: const OutlineInputBorder(),
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword ? Icons.visibility_off : Icons.visibility,
          ),
          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
        ),
      ),
      obscureText: _obscurePassword,
      enableInteractiveSelection: widget.enableInteractiveSelection,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please confirm your password';
        }
        if (value != widget.originalPassword) {
          return 'Passwords do not match';
        }
        return null;
      },
      onChanged: widget.onChanged,
      textInputAction: widget.textInputAction,
      onFieldSubmitted: widget.onFieldSubmitted,
    );
  }
}