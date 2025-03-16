import 'dart:ui';
import 'package:flutter/material.dart';
import '../utils/theme.dart';

class GlassMorphicCard extends StatelessWidget {
  final Widget child;
  final double height;
  final double? width;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final Color? backgroundColor;
  final bool hasBorder;

  const GlassMorphicCard({
    Key? key,
    required this.child,
    this.height = 150.0,
    this.width,
    this.borderRadius = AppTheme.radiusMedium,
    this.padding = const EdgeInsets.all(AppTheme.spacingMedium),
    this.backgroundColor,
    this.hasBorder = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          height: height,
          width: width,
          padding: padding,
          decoration: BoxDecoration(
            color: backgroundColor ?? Colors.white.withOpacity(0.8),
            borderRadius: BorderRadius.circular(borderRadius),
            border: hasBorder
                ? Border.all(
                    color: Colors.white.withOpacity(0.5),
                    width: 1.5,
                  )
                : null,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                spreadRadius: 0,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}
