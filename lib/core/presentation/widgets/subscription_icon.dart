import 'dart:io';
import 'package:flutter/material.dart';

class SubscriptionIcon extends StatelessWidget {
  final String name;
  final int? iconCodePoint;
  final int? colorValue;
  final String? imagePath;
  final double size;

  const SubscriptionIcon({
    super.key,
    required this.name,
    this.iconCodePoint,
    this.colorValue,
    this.imagePath,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    if (imagePath != null) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          image: DecorationImage(
            image: FileImage(File(imagePath!)),
            fit: BoxFit.cover,
          ),
        ),
      );
    }

    if (iconCodePoint != null) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: colorValue != null ? Color(colorValue!) : Colors.grey.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Icon(
          IconData(iconCodePoint!, fontFamily: 'MaterialIcons'),
          color: Colors.white,
          size: size * 0.5,
        ),
      );
    }

    // Default Gradient Icon
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [
            Color(0xFFFF9966), // Orange-ish
            Color(0xFFFF5E62), // Red-ish
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF5E62).withOpacity(0.4),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: size * 0.5,
        ),
      ),
    );
  }
}
