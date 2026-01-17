import 'package:flutter/material.dart';

/// Enterprise Spacing System
/// Based on 4/8 Grid System
abstract class AppSpacing {
  // ═══════════════════════════════════════════════════════════
  // BASE SPACING VALUES
  // ═══════════════════════════════════════════════════════════

  /// Extra small spacing (6px)
  static const double xs = 6;

  /// Small spacing (10px)
  static const double sm = 10;

  /// Medium spacing (14px)
  static const double md = 14;

  /// Large spacing (18px)
  static const double lg = 18;

  /// Extra large spacing (24px)
  static const double xl = 24;

  /// Extra extra large spacing (32px)
  static const double xxl = 32;

  // ═══════════════════════════════════════════════════════════
  // COMPONENT SPECIFIC SPACING
  // ═══════════════════════════════════════════════════════════

  /// Card internal padding
  static const double cardPadding = 14;

  /// Screen edge padding
  static const double screenPadding = 16;

  /// List item spacing
  static const double listItemSpacing = 10;

  /// Section spacing (between major sections)
  static const double sectionSpacing = 24;

  /// Form field spacing
  static const double fieldSpacing = 14;

  // ═══════════════════════════════════════════════════════════
  // BORDER RADIUS VALUES
  // ═══════════════════════════════════════════════════════════

  /// Card border radius (8px)
  static const double radiusCard = 8;

  /// Button border radius (6px)
  static const double radiusButton = 6;

  /// Input field border radius (6px)
  static const double radiusField = 6;

  /// Chip border radius (4px)
  static const double radiusChip = 4;

  /// Dialog border radius (10px)
  static const double radiusDialog = 10;

  /// Bottom sheet border radius (16px)
  static const double radiusBottomSheet = 16;

  /// Full circle (for avatars, FABs)
  static const double radiusCircle = 999;

  // ═══════════════════════════════════════════════════════════
  // ICON SIZES
  // ═══════════════════════════════════════════════════════════

  /// Small icon (16px)
  static const double iconSm = 16;

  /// Medium icon (20px)
  static const double iconMd = 20;

  /// Large icon (24px)
  static const double iconLg = 24;

  /// Extra large icon (32px)
  static const double iconXl = 32;

  // ═══════════════════════════════════════════════════════════
  // BUTTON HEIGHTS
  // ═══════════════════════════════════════════════════════════

  /// Small button height (32px)
  static const double buttonHeightSm = 32;

  /// Medium button height (40px)
  static const double buttonHeightMd = 40;

  /// Large button height (48px)
  static const double buttonHeightLg = 48;

  // ═══════════════════════════════════════════════════════════
  // EDGE INSETS HELPERS
  // ═══════════════════════════════════════════════════════════

  static const EdgeInsets paddingXs = EdgeInsets.all(xs);
  static const EdgeInsets paddingSm = EdgeInsets.all(sm);
  static const EdgeInsets paddingMd = EdgeInsets.all(md);
  static const EdgeInsets paddingLg = EdgeInsets.all(lg);
  static const EdgeInsets paddingXl = EdgeInsets.all(xl);

  static const EdgeInsets paddingCard = EdgeInsets.all(cardPadding);
  static const EdgeInsets paddingScreen = EdgeInsets.all(screenPadding);

  static const EdgeInsets paddingHorizontalSm =
      EdgeInsets.symmetric(horizontal: sm);
  static const EdgeInsets paddingHorizontalMd =
      EdgeInsets.symmetric(horizontal: md);
  static const EdgeInsets paddingHorizontalLg =
      EdgeInsets.symmetric(horizontal: lg);

  static const EdgeInsets paddingVerticalSm =
      EdgeInsets.symmetric(vertical: sm);
  static const EdgeInsets paddingVerticalMd =
      EdgeInsets.symmetric(vertical: md);
  static const EdgeInsets paddingVerticalLg =
      EdgeInsets.symmetric(vertical: lg);

  // ═══════════════════════════════════════════════════════════
  // SIZED BOX HELPERS
  // ═══════════════════════════════════════════════════════════

  static const SizedBox gapXs = SizedBox(width: xs, height: xs);
  static const SizedBox gapSm = SizedBox(width: sm, height: sm);
  static const SizedBox gapMd = SizedBox(width: md, height: md);
  static const SizedBox gapLg = SizedBox(width: lg, height: lg);
  static const SizedBox gapXl = SizedBox(width: xl, height: xl);

  static const SizedBox gapHorizontalXs = SizedBox(width: xs);
  static const SizedBox gapHorizontalSm = SizedBox(width: sm);
  static const SizedBox gapHorizontalMd = SizedBox(width: md);
  static const SizedBox gapHorizontalLg = SizedBox(width: lg);

  static const SizedBox gapVerticalXs = SizedBox(height: xs);
  static const SizedBox gapVerticalSm = SizedBox(height: sm);
  static const SizedBox gapVerticalMd = SizedBox(height: md);
  static const SizedBox gapVerticalLg = SizedBox(height: lg);
  static const SizedBox gapVerticalXl = SizedBox(height: xl);

  // ═══════════════════════════════════════════════════════════
  // BORDER RADIUS HELPERS
  // ═══════════════════════════════════════════════════════════

  static final BorderRadius borderRadiusCard =
      BorderRadius.circular(radiusCard);
  static final BorderRadius borderRadiusButton =
      BorderRadius.circular(radiusButton);
  static final BorderRadius borderRadiusField =
      BorderRadius.circular(radiusField);
  static final BorderRadius borderRadiusChip =
      BorderRadius.circular(radiusChip);
  static final BorderRadius borderRadiusDialog =
      BorderRadius.circular(radiusDialog);
  static final BorderRadius borderRadiusBottomSheet = BorderRadius.vertical(
    top: Radius.circular(radiusBottomSheet),
  );
}
