import 'package:flutter/material.dart';
import '../../../../core/presentation/widgets/bounceable.dart';

class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? borderColor;
  final double? width;
  final double height;
  final bool isLoading;
  final double? fontSize;
  final EdgeInsetsGeometry? padding;

  const PrimaryButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.backgroundColor = const Color(0xFF2C2C2E), // Default dark grey background
    this.borderColor = const Color(0xFF6C63FF), // Purple border
    this.width,
    this.height = 50.0,
    this.isLoading = false,
    this.fontSize,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Bounceable(
      onTap: onPressed,
      child: SizedBox(
        width: width,
        height: height,
        child: Container(
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(25.0),
            border: Border.all(
              color: borderColor ?? Colors.transparent,
              width: 2.0,
            ),
          ),
          alignment: Alignment.center,
          padding: padding ?? const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(
                  text,
                  style: TextStyle(
                    fontSize: fontSize ?? 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
        ),
      ),
    );
  }
}
