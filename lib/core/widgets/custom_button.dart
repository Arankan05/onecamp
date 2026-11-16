import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final bool isOutlined;
  final double height;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.isOutlined = false,
    this.height = 52.0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (isLoading) {
      final spinnerColor = isOutlined
          ? theme.colorScheme.primary
          : theme.colorScheme.onPrimary;

      return SizedBox(
        height: height,
        width: double.infinity,
        child: isOutlined
            ? OutlinedButton(
                onPressed: null,
                child: Center(
                  child: SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(spinnerColor),
                    ),
                  ),
                ),
              )
            : ElevatedButton(
                onPressed: null,
                child: Center(
                  child: SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(spinnerColor),
                    ),
                  ),
                ),
              ),
      );
    }

    if (isOutlined) {
      return SizedBox(
        height: height,
        width: double.infinity,
        child: icon != null
            ? OutlinedButton.icon(
                onPressed: onPressed,
                icon: Icon(icon, size: 20),
                label: Text(text),
              )
            : OutlinedButton(
                onPressed: onPressed,
                child: Text(text),
              ),
      );
    }

    return SizedBox(
      height: height,
      width: double.infinity,
      child: icon != null
          ? ElevatedButton.icon(
              onPressed: onPressed,
              icon: Icon(icon, size: 20),
              label: Text(text),
            )
          : ElevatedButton(
              onPressed: onPressed,
              child: Text(text),
            ),
    );
  }
}
