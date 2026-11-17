import 'package:flutter/material.dart';

import '../../routes/app_routes.dart';
import '../theme/app_theme.dart';

/// Standardized, high-contrast back button widget for OneCamp application.
/// Styled according to the Messages screen master design system.
class OneCampBackButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Color? iconColor;
  final Color? backgroundColor;

  const OneCampBackButton({
    super.key,
    this.onPressed,
    this.iconColor,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, top: 4.0, bottom: 4.0),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: backgroundColor ?? Colors.white,
          shape: BoxShape.circle,
          boxShadow: const [
            BoxShadow(
              color: Color(0x1A7C3AED),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap:
                onPressed ??
                () {
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  } else {
                    Navigator.pushReplacementNamed(
                      context,
                      AppRoutes.mainNavigation,
                    );
                  }
                },
            child: Icon(
              Icons.arrow_back_rounded,
              color: iconColor ?? AppTheme.primaryColor,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}
