import 'package:flutter/material.dart';

class Responsive {
  // Breakpoints inspired by modern design systems
  static const double mobileBreakpoint = 480;
  static const double mobileLargeBreakpoint = 640;
  static const double tabletBreakpoint = 768;
  static const double tabletLargeBreakpoint = 1024;
  static const double desktopBreakpoint = 1280;
  static const double desktopLargeBreakpoint = 1536;
  
  // Device type detection
  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < mobileBreakpoint;
  
  static bool isMobileLarge(BuildContext context) =>
      MediaQuery.of(context).size.width >= mobileBreakpoint &&
      MediaQuery.of(context).size.width < mobileLargeBreakpoint;
  
  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= mobileLargeBreakpoint &&
      MediaQuery.of(context).size.width < tabletBreakpoint;
  
  static bool isTabletLarge(BuildContext context) =>
      MediaQuery.of(context).size.width >= tabletBreakpoint &&
      MediaQuery.of(context).size.width < tabletLargeBreakpoint;
  
  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= tabletLargeBreakpoint &&
      MediaQuery.of(context).size.width < desktopBreakpoint;
  
  static bool isDesktopLarge(BuildContext context) =>
      MediaQuery.of(context).size.width >= desktopBreakpoint;
  
  // Simplified device categories
  static bool isMobileDevice(BuildContext context) =>
      MediaQuery.of(context).size.width < mobileLargeBreakpoint;
  
  static bool isTabletDevice(BuildContext context) =>
      MediaQuery.of(context).size.width >= mobileLargeBreakpoint &&
      MediaQuery.of(context).size.width < tabletLargeBreakpoint;
  
  static bool isDesktopDevice(BuildContext context) =>
      MediaQuery.of(context).size.width >= tabletLargeBreakpoint;
  
  // Screen dimensions
  static double getWidth(BuildContext context) =>
      MediaQuery.of(context).size.width;
  
  static double getHeight(BuildContext context) =>
      MediaQuery.of(context).size.height;
  
  static Size getSize(BuildContext context) =>
      MediaQuery.of(context).size;
  
  // Responsive padding
  static EdgeInsets getPadding(BuildContext context) {
    if (isMobileDevice(context)) {
      return const EdgeInsets.all(16);
    } else if (isTabletDevice(context)) {
      return const EdgeInsets.all(24);
    } else {
      return const EdgeInsets.all(32);
    }
  }
  
  static EdgeInsets getHorizontalPadding(BuildContext context) {
    if (isMobileDevice(context)) {
      return const EdgeInsets.symmetric(horizontal: 16);
    } else if (isTabletDevice(context)) {
      return const EdgeInsets.symmetric(horizontal: 32);
    } else {
      return const EdgeInsets.symmetric(horizontal: 48);
    }
  }
  
  static EdgeInsets getVerticalPadding(BuildContext context) {
    if (isMobileDevice(context)) {
      return const EdgeInsets.symmetric(vertical: 16);
    } else if (isTabletDevice(context)) {
      return const EdgeInsets.symmetric(vertical: 24);
    } else {
      return const EdgeInsets.symmetric(vertical: 32);
    }
  }
  
  // Responsive spacing
  static double getSpacing(BuildContext context, {double base = 16}) {
    if (isMobileDevice(context)) {
      return base;
    } else if (isTabletDevice(context)) {
      return base * 1.25;
    } else {
      return base * 1.5;
    }
  }
  
  // Responsive font sizes
  static double getFontSize(BuildContext context, double baseFontSize) {
    if (isMobileDevice(context)) {
      return baseFontSize;
    } else if (isTabletDevice(context)) {
      return baseFontSize * 1.1;
    } else {
      return baseFontSize * 1.2;
    }
  }
  
  // Grid system
  static int getCrossAxisCount(BuildContext context, {int? mobile, int? tablet, int? desktop}) {
    if (isMobileDevice(context)) {
      return mobile ?? 1;
    } else if (isTabletDevice(context)) {
      return tablet ?? 2;
    } else {
      return desktop ?? 3;
    }
  }
  
  // Card widths for different layouts
  static double getCardWidth(BuildContext context) {
    final width = getWidth(context);
    if (isMobileDevice(context)) {
      return width - 32; // Full width minus padding
    } else if (isTabletDevice(context)) {
      return (width - 64) / 2; // Two columns
    } else {
      return (width - 96) / 3; // Three columns
    }
  }
  
  // Maximum content width for readability
  static double getMaxContentWidth(BuildContext context) {
    final width = getWidth(context);
    if (isMobileDevice(context)) {
      return width;
    } else if (isTabletDevice(context)) {
      return 768;
    } else {
      return 1200;
    }
  }
  
  // Responsive values based on screen size
  static T responsive<T>(
    BuildContext context, {
    required T mobile,
    T? mobileLarge,
    T? tablet,
    T? tabletLarge,
    T? desktop,
    T? desktopLarge,
  }) {
    if (isDesktopLarge(context) && desktopLarge != null) {
      return desktopLarge;
    } else if (isDesktop(context) && desktop != null) {
      return desktop;
    } else if (isTabletLarge(context) && tabletLarge != null) {
      return tabletLarge;
    } else if (isTablet(context) && tablet != null) {
      return tablet;
    } else if (isMobileLarge(context) && mobileLarge != null) {
      return mobileLarge;
    } else {
      return mobile;
    }
  }
  
  // Chat-specific responsive values
  static double getChatBubbleMaxWidth(BuildContext context) {
    final width = getWidth(context);
    if (isMobileDevice(context)) {
      return width * 0.75; // 75% of screen width
    } else if (isTabletDevice(context)) {
      return width * 0.6; // 60% of screen width
    } else {
      return 400; // Fixed max width for desktop
    }
  }
  
  static int getChatMessagesPerPage(BuildContext context) {
    if (isMobileDevice(context)) {
      return 20;
    } else if (isTabletDevice(context)) {
      return 30;
    } else {
      return 50;
    }
  }
  
  // Navigation specific
  static bool shouldUseBottomNavigation(BuildContext context) {
    return isMobileDevice(context) || isTabletDevice(context);
  }
  
  static bool shouldUseSideNavigation(BuildContext context) {
    return isDesktopDevice(context);
  }
  
  // Modal and dialog sizing
  static double getDialogWidth(BuildContext context) {
    final width = getWidth(context);
    if (isMobileDevice(context)) {
      return width * 0.9;
    } else if (isTabletDevice(context)) {
      return width * 0.7;
    } else {
      return 500;
    }
  }
  
  // Image sizing
  static double getAvatarSize(BuildContext context, {double base = 40}) {
    return responsive<double>(
      context,
      mobile: base,
      tablet: base * 1.2,
      desktop: base * 1.4,
    );
  }
  
  // Button sizing
  static double getButtonHeight(BuildContext context) {
    return responsive<double>(
      context,
      mobile: 48,
      tablet: 52,
      desktop: 56,
    );
  }
  
  static EdgeInsets getButtonPadding(BuildContext context) {
    return responsive<EdgeInsets>(
      context,
      mobile: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      tablet: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      desktop: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
    );
  }
}