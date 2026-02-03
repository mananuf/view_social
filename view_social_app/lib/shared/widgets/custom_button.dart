import 'package:flutter/material.dart';
import '../../core/theme/responsive.dart';
import '../../core/theme/design_tokens.dart';
import '../../core/theme/app_theme.dart';

enum ButtonType { primary, secondary, outline, text, ghost }
enum ButtonSize { small, medium, large, extraLarge }

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final ButtonType type;
  final ButtonSize size;
  final bool isLoading;
  final Widget? icon;
  final Widget? suffixIcon;
  final bool fullWidth;
  final bool disabled;
  final Color? customColor;
  final BorderRadius? borderRadius;
  final bool useGradient; // New parameter for gradient support
  
  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.type = ButtonType.primary,
    this.size = ButtonSize.medium,
    this.isLoading = false,
    this.icon,
    this.suffixIcon,
    this.fullWidth = false,
    this.disabled = false,
    this.customColor,
    this.borderRadius,
    this.useGradient = true, // Default to true for primary buttons
  });
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDisabled = disabled || onPressed == null;
    
    // Get responsive dimensions
    final padding = _getPadding(context);
    final fontSize = _getFontSize(context);
    final height = _getHeight(context);
    final radius = borderRadius ?? _getBorderRadius();
    
    Widget buttonChild = isLoading
        ? SizedBox(
            width: _getLoadingSize(),
            height: _getLoadingSize(),
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                _getTextColor(theme),
              ),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                icon!,
                SizedBox(width: DesignTokens.spaceSm),
              ],
              Flexible(
                child: Text(
                  text,
                  style: DesignTokens.getBodyStyle(
                    context,
                    fontSize: fontSize,
                    fontWeight: FontWeight.w600,
                    color: _getTextColor(theme),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (suffixIcon != null) ...[
                SizedBox(width: DesignTokens.spaceSm),
                suffixIcon!,
              ],
            ],
          );
    
    Widget button = _buildButton(context, theme, buttonChild, padding, height, radius, isDisabled);
    
    if (fullWidth) {
      return SizedBox(
        width: double.infinity,
        child: button,
      );
    }
    
    return button;
  }
  
  Widget _buildButton(
    BuildContext context,
    ThemeData theme,
    Widget child,
    EdgeInsets padding,
    double height,
    BorderRadius radius,
    bool isDisabled,
  ) {
    final backgroundColor = _getBackgroundColor(theme);
    final foregroundColor = _getTextColor(theme);
    final borderColor = _getBorderColor(theme);
    
    switch (type) {
      case ButtonType.primary:
        // Use gradient container for primary buttons when useGradient is true
        if (useGradient && customColor == null) {
          return Container(
            height: height,
            decoration: BoxDecoration(
              gradient: isDisabled 
                  ? null 
                  : LinearGradient(
                      colors: [
                        AppTheme.primaryColor,
                        AppTheme.brightPurple,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
              color: isDisabled 
                  ? backgroundColor.withValues(alpha: DesignTokens.opacityDisabled)
                  : null,
              borderRadius: radius,
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: isDisabled || isLoading ? null : onPressed,
                borderRadius: radius,
                child: Container(
                  padding: padding,
                  alignment: Alignment.center,
                  child: child,
                ),
              ),
            ),
          );
        } else {
          return ElevatedButton(
            onPressed: isDisabled || isLoading ? null : onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: customColor ?? backgroundColor,
              foregroundColor: foregroundColor,
              disabledBackgroundColor: backgroundColor.withValues(alpha: DesignTokens.opacityDisabled),
              elevation: DesignTokens.elevationNone,
              shadowColor: Colors.transparent,
              padding: padding,
              minimumSize: Size(0, height),
              shape: RoundedRectangleBorder(borderRadius: radius),
            ),
            child: child,
          );
        }
        
      case ButtonType.secondary:
        return ElevatedButton(
          onPressed: isDisabled || isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.secondary,
            foregroundColor: theme.colorScheme.onSecondary,
            disabledBackgroundColor: theme.colorScheme.secondary.withValues(alpha: DesignTokens.opacityDisabled),
            elevation: DesignTokens.elevationNone,
            shadowColor: Colors.transparent,
            padding: padding,
            minimumSize: Size(0, height),
            shape: RoundedRectangleBorder(borderRadius: radius),
          ),
          child: child,
        );
        
      case ButtonType.outline:
        return OutlinedButton(
          onPressed: isDisabled || isLoading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: customColor ?? foregroundColor,
            disabledForegroundColor: foregroundColor.withValues(alpha: DesignTokens.opacityDisabled),
            side: BorderSide(
              color: customColor ?? borderColor,
              width: 1.5,
            ),
            padding: padding,
            minimumSize: Size(0, height),
            shape: RoundedRectangleBorder(borderRadius: radius),
          ),
          child: child,
        );
        
      case ButtonType.text:
        return TextButton(
          onPressed: isDisabled || isLoading ? null : onPressed,
          style: TextButton.styleFrom(
            foregroundColor: customColor ?? foregroundColor,
            disabledForegroundColor: foregroundColor.withValues(alpha: DesignTokens.opacityDisabled),
            padding: padding,
            minimumSize: Size(0, height),
            shape: RoundedRectangleBorder(borderRadius: radius),
          ),
          child: child,
        );
        
      case ButtonType.ghost:
        return TextButton(
          onPressed: isDisabled || isLoading ? null : onPressed,
          style: TextButton.styleFrom(
            foregroundColor: customColor ?? foregroundColor,
            disabledForegroundColor: foregroundColor.withValues(alpha: DesignTokens.opacityDisabled),
            backgroundColor: Colors.transparent,
            overlayColor: (customColor ?? foregroundColor).withValues(alpha: 0.1),
            padding: padding,
            minimumSize: Size(0, height),
            shape: RoundedRectangleBorder(borderRadius: radius),
          ),
          child: child,
        );
    }
  }
  
  EdgeInsets _getPadding(BuildContext context) {
    return Responsive.responsive<EdgeInsets>(
      context,
      mobile: switch (size) {
        ButtonSize.small => DesignTokens.paddingHorizontalMd.copyWith(
          top: DesignTokens.spaceSm,
          bottom: DesignTokens.spaceSm,
        ),
        ButtonSize.medium => DesignTokens.paddingHorizontalLg.copyWith(
          top: DesignTokens.spaceMd,
          bottom: DesignTokens.spaceMd,
        ),
        ButtonSize.large => DesignTokens.paddingHorizontalXl.copyWith(
          top: DesignTokens.spaceLg,
          bottom: DesignTokens.spaceLg,
        ),
        ButtonSize.extraLarge => DesignTokens.paddingHorizontal2xl.copyWith(
          top: DesignTokens.spaceXl,
          bottom: DesignTokens.spaceXl,
        ),
      },
      tablet: switch (size) {
        ButtonSize.small => DesignTokens.paddingHorizontalLg.copyWith(
          top: DesignTokens.spaceMd,
          bottom: DesignTokens.spaceMd,
        ),
        ButtonSize.medium => DesignTokens.paddingHorizontalXl.copyWith(
          top: DesignTokens.spaceLg,
          bottom: DesignTokens.spaceLg,
        ),
        ButtonSize.large => DesignTokens.paddingHorizontal2xl.copyWith(
          top: DesignTokens.spaceXl,
          bottom: DesignTokens.spaceXl,
        ),
        ButtonSize.extraLarge => const EdgeInsets.symmetric(
          horizontal: DesignTokens.space3xl,
          vertical: DesignTokens.space2xl,
        ),
      },
      desktop: switch (size) {
        ButtonSize.small => DesignTokens.paddingHorizontalXl.copyWith(
          top: DesignTokens.spaceLg,
          bottom: DesignTokens.spaceLg,
        ),
        ButtonSize.medium => DesignTokens.paddingHorizontal2xl.copyWith(
          top: DesignTokens.spaceXl,
          bottom: DesignTokens.spaceXl,
        ),
        ButtonSize.large => const EdgeInsets.symmetric(
          horizontal: DesignTokens.space3xl,
          vertical: DesignTokens.space2xl,
        ),
        ButtonSize.extraLarge => const EdgeInsets.symmetric(
          horizontal: DesignTokens.space4xl,
          vertical: DesignTokens.space3xl,
        ),
      },
    );
  }
  
  double _getFontSize(BuildContext context) {
    final baseFontSize = switch (size) {
      ButtonSize.small => 14.0,
      ButtonSize.medium => 16.0,
      ButtonSize.large => 18.0,
      ButtonSize.extraLarge => 20.0,
    };
    
    return Responsive.getFontSize(context, baseFontSize);
  }
  
  double _getHeight(BuildContext context) {
    return Responsive.responsive<double>(
      context,
      mobile: switch (size) {
        ButtonSize.small => DesignTokens.buttonHeightSm,
        ButtonSize.medium => DesignTokens.buttonHeightMd,
        ButtonSize.large => DesignTokens.buttonHeightLg,
        ButtonSize.extraLarge => DesignTokens.buttonHeightXl,
      },
      tablet: switch (size) {
        ButtonSize.small => DesignTokens.buttonHeightMd,
        ButtonSize.medium => DesignTokens.buttonHeightLg,
        ButtonSize.large => DesignTokens.buttonHeightXl,
        ButtonSize.extraLarge => 68.0,
      },
      desktop: switch (size) {
        ButtonSize.small => DesignTokens.buttonHeightLg,
        ButtonSize.medium => DesignTokens.buttonHeightXl,
        ButtonSize.large => 68.0,
        ButtonSize.extraLarge => 76.0,
      },
    );
  }
  
  BorderRadius _getBorderRadius() {
    return switch (size) {
      ButtonSize.small => DesignTokens.borderRadiusMd,
      ButtonSize.medium => DesignTokens.borderRadiusLg,
      ButtonSize.large => DesignTokens.borderRadiusXl,
      ButtonSize.extraLarge => DesignTokens.borderRadius2xl,
    };
  }
  
  double _getLoadingSize() {
    return switch (size) {
      ButtonSize.small => 16.0,
      ButtonSize.medium => 20.0,
      ButtonSize.large => 24.0,
      ButtonSize.extraLarge => 28.0,
    };
  }
  
  Color _getBackgroundColor(ThemeData theme) {
    switch (type) {
      case ButtonType.primary:
        return customColor ?? AppTheme.primaryColor;
      case ButtonType.secondary:
        return theme.colorScheme.secondary;
      case ButtonType.outline:
      case ButtonType.text:
      case ButtonType.ghost:
        return Colors.transparent;
    }
  }
  
  Color _getTextColor(ThemeData theme) {
    switch (type) {
      case ButtonType.primary:
        return AppTheme.white;
      case ButtonType.secondary:
        return theme.colorScheme.onSecondary;
      case ButtonType.outline:
      case ButtonType.text:
      case ButtonType.ghost:
        return customColor ?? theme.colorScheme.primary;
    }
  }
  
  Color _getBorderColor(ThemeData theme) {
    return customColor ?? theme.colorScheme.primary;
  }
}