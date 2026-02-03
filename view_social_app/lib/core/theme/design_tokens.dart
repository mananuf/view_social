import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Design tokens inspired by modern chat and AI app designs
/// Following the Figma references for consistent spacing, sizing, and styling
class DesignTokens {
  // Spacing Scale (8pt grid system)
  static const double space2xs = 2.0;
  static const double spaceXs = 4.0;
  static const double spaceSm = 8.0;
  static const double spaceMd = 12.0;
  static const double spaceLg = 16.0;
  static const double spaceXl = 20.0;
  static const double space2xl = 24.0;
  static const double space3xl = 32.0;
  static const double space4xl = 40.0;
  static const double space5xl = 48.0;
  static const double space6xl = 64.0;
  static const double space7xl = 80.0;
  static const double space8xl = 96.0;

  // Border Radius Scale
  static const double radiusXs = 4.0;
  static const double radiusSm = 6.0;
  static const double radiusMd = 8.0;
  static const double radiusLg = 12.0;
  static const double radiusXl = 16.0;
  static const double radius2xl = 20.0;
  static const double radius3xl = 24.0;
  static const double radiusFull = 9999.0;

  // Elevation Scale
  static const double elevationNone = 0.0;
  static const double elevationSm = 1.0;
  static const double elevationMd = 2.0;
  static const double elevationLg = 4.0;
  static const double elevationXl = 8.0;
  static const double elevation2xl = 12.0;
  static const double elevation3xl = 16.0;

  // Icon Sizes
  static const double iconXs = 12.0;
  static const double iconSm = 16.0;
  static const double iconMd = 20.0;
  static const double iconLg = 24.0;
  static const double iconXl = 32.0;
  static const double icon2xl = 40.0;
  static const double icon3xl = 48.0;

  // Avatar Sizes
  static const double avatarXs = 24.0;
  static const double avatarSm = 32.0;
  static const double avatarMd = 40.0;
  static const double avatarLg = 48.0;
  static const double avatarXl = 56.0;
  static const double avatar2xl = 64.0;
  static const double avatar3xl = 80.0;
  static const double avatar4xl = 96.0;

  // Button Heights
  static const double buttonHeightSm = 36.0;
  static const double buttonHeightMd = 44.0;
  static const double buttonHeightLg = 52.0;
  static const double buttonHeightXl = 60.0;

  // Input Heights
  static const double inputHeightSm = 36.0;
  static const double inputHeightMd = 44.0;
  static const double inputHeightLg = 52.0;
  static const double inputHeightXl = 60.0;

  // Chat specific dimensions
  static const double chatBubbleMinHeight = 40.0;
  static const double chatBubbleMaxWidth = 280.0;
  static const double chatInputHeight = 48.0;
  static const double chatAvatarSize = 32.0;
  static const double chatTimestampSize = 12.0;

  // Animation Durations
  static const Duration animationFast = Duration(milliseconds: 150);
  static const Duration animationNormal = Duration(milliseconds: 250);
  static const Duration animationSlow = Duration(milliseconds: 350);
  static const Duration animationSlower = Duration(milliseconds: 500);

  // Animation Curves
  static const Curve curveEaseIn = Curves.easeIn;
  static const Curve curveEaseOut = Curves.easeOut;
  static const Curve curveEaseInOut = Curves.easeInOut;
  static const Curve curveSpring = Curves.elasticOut;

  // Opacity Scale
  static const double opacityDisabled = 0.38;
  static const double opacityMedium = 0.6;
  static const double opacityHigh = 0.87;
  static const double opacityFull = 1.0;

  // Line Heights
  static const double lineHeightTight = 1.2;
  static const double lineHeightNormal = 1.4;
  static const double lineHeightRelaxed = 1.6;
  static const double lineHeightLoose = 1.8;

  // Letter Spacing
  static const double letterSpacingTight = -0.025;
  static const double letterSpacingNormal = 0.0;
  static const double letterSpacingWide = 0.025;
  static const double letterSpacingWider = 0.05;

  // Breakpoints (matching responsive.dart)
  static const double breakpointMobile = 480;
  static const double breakpointMobileLarge = 640;
  static const double breakpointTablet = 768;
  static const double breakpointTabletLarge = 1024;
  static const double breakpointDesktop = 1280;
  static const double breakpointDesktopLarge = 1536;

  // Z-Index Scale
  static const int zIndexBase = 0;
  static const int zIndexDropdown = 10;
  static const int zIndexSticky = 20;
  static const int zIndexFixed = 30;
  static const int zIndexModal = 40;
  static const int zIndexPopover = 50;
  static const int zIndexTooltip = 60;
  static const int zIndexToast = 70;

  // Common Border Radius Presets
  static BorderRadius get borderRadiusNone => BorderRadius.zero;
  static BorderRadius get borderRadiusXs => BorderRadius.circular(radiusXs);
  static BorderRadius get borderRadiusSm => BorderRadius.circular(radiusSm);
  static BorderRadius get borderRadiusMd => BorderRadius.circular(radiusMd);
  static BorderRadius get borderRadiusLg => BorderRadius.circular(radiusLg);
  static BorderRadius get borderRadiusXl => BorderRadius.circular(radiusXl);
  static BorderRadius get borderRadius2xl => BorderRadius.circular(radius2xl);
  static BorderRadius get borderRadius3xl => BorderRadius.circular(radius3xl);
  static BorderRadius get borderRadiusFull => BorderRadius.circular(radiusFull);

  // Chat bubble specific radius
  static BorderRadius get chatBubbleRadius => const BorderRadius.only(
    topLeft: Radius.circular(radiusXl),
    topRight: Radius.circular(radiusXl),
    bottomLeft: Radius.circular(radiusXl),
    bottomRight: Radius.circular(radiusSm),
  );

  static BorderRadius get chatBubbleRadiusReverse => const BorderRadius.only(
    topLeft: Radius.circular(radiusXl),
    topRight: Radius.circular(radiusXl),
    bottomLeft: Radius.circular(radiusSm),
    bottomRight: Radius.circular(radiusXl),
  );

  // Common Shadows
  static List<BoxShadow> get shadowSm => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.05),
      blurRadius: 2,
      offset: const Offset(0, 1),
    ),
  ];

  static List<BoxShadow> get shadowMd => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.1),
      blurRadius: 4,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> get shadowLg => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.1),
      blurRadius: 8,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get shadowXl => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.15),
      blurRadius: 16,
      offset: const Offset(0, 8),
    ),
  ];

  // Typography Helpers
  static TextStyle getHeadingStyle(BuildContext context, {
    required double fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? letterSpacing,
    double? height,
  }) {
    return GoogleFonts.nunitoSans(
      fontSize: fontSize,
      fontWeight: fontWeight ?? FontWeight.w600,
      color: color ?? Theme.of(context).colorScheme.onSurface,
      letterSpacing: letterSpacing ?? letterSpacingNormal,
      height: height ?? lineHeightTight,
    );
  }

  static TextStyle getBodyStyle(BuildContext context, {
    required double fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? letterSpacing,
    double? height,
  }) {
    return GoogleFonts.nunitoSans(
      fontSize: fontSize,
      fontWeight: fontWeight ?? FontWeight.w400,
      color: color ?? Theme.of(context).colorScheme.onSurface,
      letterSpacing: letterSpacing ?? letterSpacingNormal,
      height: height ?? lineHeightNormal,
    );
  }

  static TextStyle getCaptionStyle(BuildContext context, {
    required double fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? letterSpacing,
    double? height,
  }) {
    return GoogleFonts.nunitoSans(
      fontSize: fontSize,
      fontWeight: fontWeight ?? FontWeight.w500,
      color: color ?? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
      letterSpacing: letterSpacing ?? letterSpacingWide,
      height: height ?? lineHeightNormal,
    );
  }

  // Common Padding Presets
  static EdgeInsets get paddingNone => EdgeInsets.zero;
  static EdgeInsets get paddingXs => const EdgeInsets.all(spaceXs);
  static EdgeInsets get paddingSm => const EdgeInsets.all(spaceSm);
  static EdgeInsets get paddingMd => const EdgeInsets.all(spaceMd);
  static EdgeInsets get paddingLg => const EdgeInsets.all(spaceLg);
  static EdgeInsets get paddingXl => const EdgeInsets.all(spaceXl);
  static EdgeInsets get padding2xl => const EdgeInsets.all(space2xl);
  static EdgeInsets get padding3xl => const EdgeInsets.all(space3xl);

  // Horizontal Padding
  static EdgeInsets get paddingHorizontalXs => const EdgeInsets.symmetric(horizontal: spaceXs);
  static EdgeInsets get paddingHorizontalSm => const EdgeInsets.symmetric(horizontal: spaceSm);
  static EdgeInsets get paddingHorizontalMd => const EdgeInsets.symmetric(horizontal: spaceMd);
  static EdgeInsets get paddingHorizontalLg => const EdgeInsets.symmetric(horizontal: spaceLg);
  static EdgeInsets get paddingHorizontalXl => const EdgeInsets.symmetric(horizontal: spaceXl);
  static EdgeInsets get paddingHorizontal2xl => const EdgeInsets.symmetric(horizontal: space2xl);

  // Vertical Padding
  static EdgeInsets get paddingVerticalXs => const EdgeInsets.symmetric(vertical: spaceXs);
  static EdgeInsets get paddingVerticalSm => const EdgeInsets.symmetric(vertical: spaceSm);
  static EdgeInsets get paddingVerticalMd => const EdgeInsets.symmetric(vertical: spaceMd);
  static EdgeInsets get paddingVerticalLg => const EdgeInsets.symmetric(vertical: spaceLg);
  static EdgeInsets get paddingVerticalXl => const EdgeInsets.symmetric(vertical: spaceXl);
  static EdgeInsets get paddingVertical2xl => const EdgeInsets.symmetric(vertical: space2xl);
}