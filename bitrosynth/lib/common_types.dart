import 'package:flutter/material.dart';

enum MessageType {
    error,
    warning,
    information
}

enum ProcessStatus {
    inProcess(1),
    successful(0),
    unsuccessful(-1);

    final int value;
    const ProcessStatus(this.value);
}

enum AudioBitDepth {
  Bit8,
  Bit16
}




class AppColors {
  // =========================
  // Dark Cyan Pro Palette
  // =========================

  static const Color red            = Colors.red;
  // Border
  static const Color outline        = Color(0xFF333333);

  // Backgrounds
  static const Color background     = Color(0xFF070707);
  static const Color fullBlack      = Color(0xFF000000);
  static const Color surface        = Color(0xFF1C1C1C);
  static const Color surfaceAlt     = Color(0xFF242424);
  static const Color surfaceDisabled= Color(0xFF151515);
  static const Color surfaceHover   = Color(0xFF2A2A2A);
  static const Color surfacePressed = Color(0xFF121212);

  // Texts
  static const Color darkText       = Color(0xFF1E1E1E);
  static const Color text           = Color(0xFFE6E6E6);
  static const Color mutedText      = Color(0xFF9A9A9A);

  // Accent
  static const Color accent         = Color(0xFF00E5FF);
}