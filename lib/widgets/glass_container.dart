import 'dart:ui';

import 'package:flutter/material.dart';

class GlassContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;

  const GlassContainer({
    super.key,
    required this.child,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(25),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 15,
          sigmaY: 15,
        ),
        child: Container(
          padding: padding ?? const EdgeInsets.all(18),
          decoration: BoxDecoration(
  color: Colors.white.withValues(alpha: 0.18),
  borderRadius: BorderRadius.circular(25),
  border: Border.all(
    color: Colors.white.withValues(alpha: 0.25),
    width: 1,
  ),
),
          child: child,
        ),
      ),
    );
  }
}