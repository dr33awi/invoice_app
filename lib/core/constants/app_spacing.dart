import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Enterprise Spacing System
/// Based on 4/8 Grid System with ScreenUtil support
abstract class AppSpacing {
  // ═══════════════════════════════════════════════════════════
  // BASE SPACING VALUES (responsive)
  // ═══════════════════════════════════════════════════════════

  /// Extra small spacing (6px)
  static double get xs => 6.w;

  /// Small spacing (10px)
  static double get sm => 10.w;

  /// Medium spacing (14px)
  static double get md => 14.w;

  /// Large spacing (18px)
  static double get lg => 18.w;

  /// Extra large spacing (24px)
  static double get xl => 24.w;

  /// Extra extra large spacing (32px)
  static double get xxl => 32.w;

  // ═══════════════════════════════════════════════════════════
  // COMPONENT SPECIFIC SPACING
  // ═══════════════════════════════════════════════════════════

  /// Card internal padding
  static double get cardPadding => 14.w;

  /// Screen edge padding
  static double get screenPadding => 16.w;

  /// List item spacing
  static double get listItemSpacing => 10.h;

  /// Section spacing (between major sections)
  static double get sectionSpacing => 24.h;

  /// Form field spacing
  static double get fieldSpacing => 14.h;

  // ═══════════════════════════════════════════════════════════
  // BORDER RADIUS VALUES
  // ═══════════════════════════════════════════════════════════

  /// Card border radius (8px)
  static double get radiusCard => 8.r;

  /// Button border radius (6px)
  static double get radiusButton => 6.r;

  /// Input field border radius (6px)
  static double get radiusField => 6.r;

  /// Chip border radius (4px)
  static double get radiusChip => 4.r;

  /// Dialog border radius (10px)
  static double get radiusDialog => 10.r;

  /// Bottom sheet border radius (16px)
  static double get radiusBottomSheet => 16.r;

  /// Full circle (for avatars, FABs)
  static double get radiusCircle => 999.r;

  // ═══════════════════════════════════════════════════════════
  // ICON SIZES
  // ═══════════════════════════════════════════════════════════

  /// Small icon (16px)
  static double get iconSm => 16.sp;

  /// Medium icon (20px)
  static double get iconMd => 20.sp;

  /// Large icon (24px)
  static double get iconLg => 24.sp;

  /// Extra large icon (32px)
  static double get iconXl => 32.sp;

  // ═══════════════════════════════════════════════════════════
  // BUTTON HEIGHTS
  // ═══════════════════════════════════════════════════════════

  /// Small button height (32px)
  static double get buttonHeightSm => 32.h;

  /// Medium button height (40px)
  static double get buttonHeightMd => 40.h;

  /// Large button height (48px)
  static double get buttonHeightLg => 48.h;

  // ═══════════════════════════════════════════════════════════
  // EDGE INSETS HELPERS
  // ═══════════════════════════════════════════════════════════

  static EdgeInsets get paddingXs => EdgeInsets.all(6.w);
  static EdgeInsets get paddingSm => EdgeInsets.all(10.w);
  static EdgeInsets get paddingMd => EdgeInsets.all(14.w);
  static EdgeInsets get paddingLg => EdgeInsets.all(18.w);
  static EdgeInsets get paddingXl => EdgeInsets.all(24.w);

  static EdgeInsets get paddingCard => EdgeInsets.all(14.w);
  static EdgeInsets get paddingScreen => EdgeInsets.all(16.w);

  static EdgeInsets get paddingHorizontalSm =>
      EdgeInsets.symmetric(horizontal: 10.w);
  static EdgeInsets get paddingHorizontalMd =>
      EdgeInsets.symmetric(horizontal: 14.w);
  static EdgeInsets get paddingHorizontalLg =>
      EdgeInsets.symmetric(horizontal: 18.w);

  static EdgeInsets get paddingVerticalSm =>
      EdgeInsets.symmetric(vertical: 10.h);
  static EdgeInsets get paddingVerticalMd =>
      EdgeInsets.symmetric(vertical: 14.h);
  static EdgeInsets get paddingVerticalLg =>
      EdgeInsets.symmetric(vertical: 18.h);

  // ═══════════════════════════════════════════════════════════
  // SIZED BOX HELPERS
  // ═══════════════════════════════════════════════════════════

  static SizedBox get gapXs => SizedBox(width: 6.w, height: 6.h);
  static SizedBox get gapSm => SizedBox(width: 10.w, height: 10.h);
  static SizedBox get gapMd => SizedBox(width: 14.w, height: 14.h);
  static SizedBox get gapLg => SizedBox(width: 18.w, height: 18.h);
  static SizedBox get gapXl => SizedBox(width: 24.w, height: 24.h);

  static SizedBox get gapHorizontalXs => SizedBox(width: 6.w);
  static SizedBox get gapHorizontalSm => SizedBox(width: 10.w);
  static SizedBox get gapHorizontalMd => SizedBox(width: 14.w);
  static SizedBox get gapHorizontalLg => SizedBox(width: 18.w);

  static SizedBox get gapVerticalXs => SizedBox(height: 6.h);
  static SizedBox get gapVerticalSm => SizedBox(height: 10.h);
  static SizedBox get gapVerticalMd => SizedBox(height: 14.h);
  static SizedBox get gapVerticalLg => SizedBox(height: 18.h);
  static SizedBox get gapVerticalXl => SizedBox(height: 24.h);

  // ═══════════════════════════════════════════════════════════
  // BORDER RADIUS HELPERS
  // ═══════════════════════════════════════════════════════════

  static BorderRadius get borderRadiusCard => BorderRadius.circular(8.r);
  static BorderRadius get borderRadiusButton => BorderRadius.circular(6.r);
  static BorderRadius get borderRadiusField => BorderRadius.circular(6.r);
  static BorderRadius get borderRadiusChip => BorderRadius.circular(4.r);
  static BorderRadius get borderRadiusDialog => BorderRadius.circular(10.r);
  static BorderRadius get borderRadiusBottomSheet => BorderRadius.vertical(
        top: Radius.circular(16.r),
      );
}
