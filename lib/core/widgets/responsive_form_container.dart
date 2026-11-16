import 'package:flutter/material.dart';

/// A wrapper widget that ensures forms and content are responsively centered
/// with an optimal maximum width for larger screens (Web/Tablet) while taking
/// full screen width on mobile devices.
class ResponsiveFormContainer extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry padding;

  const ResponsiveFormContainer({
    super.key,
    required this.child,
    this.maxWidth = 540.0,
    this.padding = const EdgeInsets.all(24.0),
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: padding,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: child,
        ),
      ),
    );
  }
}
