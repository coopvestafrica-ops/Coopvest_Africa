import 'package:flutter/material.dart';

class ProfileOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final bool isDestructive;
  final bool isEnabled;
  final Widget? trailing;
  final Color? iconColor;
  final Color? textColor;

  const ProfileOption({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
    this.isDestructive = false,
    this.isEnabled = true,
    this.trailing,
    this.iconColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveIconColor = iconColor ?? 
      (isDestructive ? Theme.of(context).colorScheme.error : Theme.of(context).primaryColor);
    
    final effectiveTextColor = textColor ??
      (isDestructive ? Theme.of(context).colorScheme.error : Theme.of(context).textTheme.bodyLarge?.color);

    return Opacity(
      opacity: isEnabled ? 1.0 : 0.5,
      child: ListTile(
        enabled: isEnabled,
        onTap: isEnabled ? onTap : null,
        leading: Icon(
          icon,
          color: effectiveIconColor,
          size: 24,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: effectiveTextColor,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: TextStyle(
                color: Theme.of(context).textTheme.bodySmall?.color,
                fontSize: 14,
              ),
            )
          : null,
        trailing: trailing ?? 
          Icon(
            Icons.chevron_right,
            color: Theme.of(context).dividerColor,
            size: 20,
          ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
