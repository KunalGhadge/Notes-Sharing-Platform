import 'package:flutter/material.dart';

class PrimaryColor {
  static Color shade100 = const Color(0xFFE3F2FD);
  static Color shade200 = const Color(0xFFBBDEFB);
  static Color shade300 = const Color(0xFF90CAF9);
  static Color shade400 = const Color(0xFF64B5F6);
  static Color shade500 = const Color(0xFF0D47A1); // Premium Deep Blue
  static Color shade600 = const Color(0xFF1976D2);
  static Color shade700 = const Color(0xFF1565C0);
  static Color shade900 = const Color(0xFF0D47A1);
}

class DangerColors {
  static Color shade100 = const Color(0xFFffe5d3);
  static Color shade200 = const Color(0xFFffc4a9);
  static Color shade300 = const Color(0xFFff9c7e);
  static Color shade400 = const Color(0xFFff765d);
  static Color shade500 = const Color(0xFFff3728);
  static Color shade600 = const Color(0xFFdb1d1f);
  static Color shade700 = const Color(0xFFb71423);
  static Color shade800 = const Color(0xFF930c24);
  static Color shade900 = const Color(0xFF7a0725);
}

class GrayscaleWhiteColors {
  static Color white = const Color(0xFFffffff);
  static Color almostWhite = const Color(0xFFeeeeee);
  static Color shadedWhite = const Color(0xFFdddddd);
  static Color darkWhite = const Color(0xFFcccccc);
}

class GrayscaleGrayColors {
  static Color silver = const Color(0xFFBBBBBB);
  static Color paleGray = const Color(0xFFaaaaaa);
  static Color lightGray = const Color(0xFF999999);
  static Color tintedGray = const Color(0xFF888888);
  static Color mediumGray = const Color(0xFF777777);
  static Color shadedGray = const Color(0xFF666666);
  static Color darkGray = const Color(0xFF555555);
}

class GrayscaleBlackColors {
  static Color paleBlack = const Color(0xFF444444);
  static Color lightBlack = const Color(0xFF333333);
  static Color tintedBlack = const Color(0xFF222222);
  static Color almostBlack = const Color(0xFF111111);
  static Color black = const Color(0xFF000000);
}

class OtherColors {
  static Color malibu = const Color(0xFF4ABCFC);
  static Color gossip = const Color(0xFFC7F9BB);
  static Color broom = const Color(0xFFFFE816);
  static Color tigerLily = const Color(0xFFe66432);
  static Color appleRed = const Color(0xFFf67373);
  static Color royalBlue = const Color(0xFF0D47A1);
  static Color premiumGold = const Color(0xFFFFD700);
  static Color amethystPurple = const Color(0xFF0D47A1);
}

class AppGradients {
  static LinearGradient premiumGradient = const LinearGradient(
    colors: [Color(0xFF0D47A1), Color(0xFF1976D2)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient glassGradient = LinearGradient(
    colors: [
      Colors.white.withOpacity(0.1),
      Colors.white.withOpacity(0.05),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
