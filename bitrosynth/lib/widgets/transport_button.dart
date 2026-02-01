import 'package:flutter/material.dart';
import "../common_types.dart";

class IconToolButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;
  final bool enabled;
  final double width;
  final double height;


  const IconToolButton({
    super.key,
    required this.icon,
    required this.color,
    required this.width,
    required this.height,
    required this.onPressed,
    this.enabled = true,
  });


  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: IconButton(
        
        style: IconButton.styleFrom(
          backgroundColor: AppColors.surfaceAlt,
          hoverColor: AppColors.surfaceHover,
          disabledBackgroundColor: AppColors.surfaceDisabled,
          disabledForegroundColor: AppColors.mutedText,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.zero,
          ),
        ),
        icon: Icon(
          icon,
          color: color,
          size: 30),
        onPressed: enabled ? onPressed : null,
        padding: EdgeInsets.zero,
      ),
    );
  }
}