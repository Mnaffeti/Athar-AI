import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Circle with the user's initials in the brand colours.
class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    super.key,
    required this.initials,
    this.size = 44,
    this.onTap,
  });

  final String initials;
  final double size;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: onTap != null,
      label: 'Profile',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.brandNavy,
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.brandLight.withValues(alpha: 0.35),
              width: 1.5,
            ),
          ),
          child: Text(
            initials,
            style: TextStyle(
              fontFamily: AppFonts.display,
              fontSize: size * 0.4,
              fontWeight: FontWeight.w700,
              color: AppColors.brandLight,
            ),
          ),
        ),
      ),
    );
  }
}
