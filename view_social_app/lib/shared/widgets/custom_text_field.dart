import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/responsive.dart';
import '../../core/theme/design_tokens.dart';
import '../../core/theme/app_theme.dart';

enum TextFieldSize { small, medium, large }

enum TextFieldVariant { outlined, filled, underlined }

class CustomTextField extends StatefulWidget {
  final String? label;
  final String? hint;
  final String? helperText;
  final String? initialValue;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final void Function()? onTap;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final bool obscureText;
  final bool enabled;
  final bool readOnly;
  final int? maxLines;
  final int? minLines;
  final int? maxLength;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final String? prefixText;
  final String? suffixText;
  final List<TextInputFormatter>? inputFormatters;
  final FocusNode? focusNode;
  final bool autofocus;
  final TextFieldSize size;
  final TextFieldVariant variant;
  final Color? fillColor;
  final BorderRadius? borderRadius;
  final bool showCharacterCount;
  final TextCapitalization textCapitalization;

  const CustomTextField({
    super.key,
    this.label,
    this.hint,
    this.helperText,
    this.initialValue,
    this.controller,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.obscureText = false,
    this.enabled = true,
    this.readOnly = false,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.prefixIcon,
    this.suffixIcon,
    this.prefixText,
    this.suffixText,
    this.inputFormatters,
    this.focusNode,
    this.autofocus = false,
    this.size = TextFieldSize.medium,
    this.variant = TextFieldVariant.outlined,
    this.fillColor,
    this.borderRadius,
    this.showCharacterCount = false,
    this.textCapitalization = TextCapitalization.none,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  late bool _obscureText;
  late FocusNode _focusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.obscureText;
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.dispose();
    } else {
      _focusNode.removeListener(_onFocusChange);
    }
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget? suffixIcon = widget.suffixIcon;

    // Add password visibility toggle for password fields ONLY if no suffixIcon is provided
    if (widget.obscureText && suffixIcon == null) {
      suffixIcon = IconButton(
        icon: Icon(
          _obscureText
              ? Icons.visibility_outlined
              : Icons.visibility_off_outlined,
          color: _isFocused
              ? theme.colorScheme.primary
              : theme.colorScheme.onSurface.withValues(
                  alpha: DesignTokens.opacityMedium,
                ),
          size: _getIconSize(),
        ),
        onPressed: () {
          setState(() {
            _obscureText = !_obscureText;
          });
        },
        splashRadius: 20,
      );
    }

    // Use widget.obscureText when suffixIcon is provided (external control)
    final bool shouldObscure = widget.suffixIcon != null
        ? widget.obscureText
        : _obscureText;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: DesignTokens.getCaptionStyle(
              context,
              fontSize: _getLabelFontSize(context),
              fontWeight: FontWeight.w600,
              color: _isFocused
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface.withValues(
                      alpha: DesignTokens.opacityHigh,
                    ),
            ),
          ),
          SizedBox(height: DesignTokens.spaceSm),
        ],
        TextFormField(
          controller: widget.controller,
          initialValue: widget.initialValue,
          validator: widget.validator,
          onChanged: widget.onChanged,
          onFieldSubmitted: widget.onSubmitted,
          onTap: widget.onTap,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          obscureText: shouldObscure,
          enabled: widget.enabled,
          readOnly: widget.readOnly,
          maxLines: widget.maxLines,
          minLines: widget.minLines,
          maxLength: widget.maxLength,
          inputFormatters: widget.inputFormatters,
          focusNode: _focusNode,
          autofocus: widget.autofocus,
          textCapitalization: widget.textCapitalization,
          style: DesignTokens.getBodyStyle(
            context,
            fontSize: _getTextFontSize(context),
            color: widget.enabled
                ? theme.colorScheme.onSurface
                : theme.colorScheme.onSurface.withValues(
                    alpha: DesignTokens.opacityDisabled,
                  ),
          ),
          decoration: _buildInputDecoration(context, theme, suffixIcon),
        ),
        if (widget.helperText != null ||
            (widget.showCharacterCount && widget.maxLength != null)) ...[
          SizedBox(height: DesignTokens.spaceXs),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (widget.helperText != null)
                Expanded(
                  child: Text(
                    widget.helperText!,
                    style: DesignTokens.getCaptionStyle(
                      context,
                      fontSize: 12,
                      color: theme.colorScheme.onSurface.withValues(
                        alpha: DesignTokens.opacityMedium,
                      ),
                    ),
                  ),
                ),
              if (widget.showCharacterCount && widget.maxLength != null)
                Text(
                  '${widget.controller?.text.length ?? 0}/${widget.maxLength}',
                  style: DesignTokens.getCaptionStyle(
                    context,
                    fontSize: 12,
                    color: theme.colorScheme.onSurface.withValues(
                      alpha: DesignTokens.opacityMedium,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }

  InputDecoration _buildInputDecoration(
    BuildContext context,
    ThemeData theme,
    Widget? suffixIcon,
  ) {
    final borderRadius = widget.borderRadius ?? _getBorderRadius();
    final fillColor = widget.fillColor ?? _getFillColor(theme);

    switch (widget.variant) {
      case TextFieldVariant.outlined:
        return InputDecoration(
          hintText: widget.hint,
          hintStyle: DesignTokens.getBodyStyle(
            context,
            fontSize: _getTextFontSize(context),
            color: theme.colorScheme.onSurface.withValues(
              alpha: DesignTokens.opacityMedium,
            ),
          ),
          prefixIcon: widget.prefixIcon != null
              ? _buildIconContainer(widget.prefixIcon!)
              : null,
          suffixIcon: suffixIcon != null
              ? _buildIconContainer(suffixIcon)
              : null,
          prefixText: widget.prefixText,
          suffixText: widget.suffixText,
          filled: true,
          fillColor: fillColor,
          border: OutlineInputBorder(
            borderRadius: borderRadius,
            borderSide: BorderSide(
              color: theme.colorScheme.outline.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: borderRadius,
            borderSide: BorderSide(
              color: theme.colorScheme.outline.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: borderRadius,
            borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: borderRadius,
            borderSide: BorderSide(color: theme.colorScheme.error, width: 1),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: borderRadius,
            borderSide: BorderSide(color: theme.colorScheme.error, width: 2),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: borderRadius,
            borderSide: BorderSide(
              color: theme.colorScheme.outline.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          contentPadding: _getContentPadding(context),
          counterText: widget.showCharacterCount ? null : '',
        );

      case TextFieldVariant.filled:
        return InputDecoration(
          hintText: widget.hint,
          hintStyle: DesignTokens.getBodyStyle(
            context,
            fontSize: _getTextFontSize(context),
            color: theme.colorScheme.onSurface.withValues(
              alpha: DesignTokens.opacityMedium,
            ),
          ),
          prefixIcon: widget.prefixIcon != null
              ? _buildIconContainer(widget.prefixIcon!)
              : null,
          suffixIcon: suffixIcon != null
              ? _buildIconContainer(suffixIcon)
              : null,
          prefixText: widget.prefixText,
          suffixText: widget.suffixText,
          filled: true,
          fillColor: fillColor,
          border: OutlineInputBorder(
            borderRadius: borderRadius,
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: borderRadius,
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: borderRadius,
            borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: borderRadius,
            borderSide: BorderSide(color: theme.colorScheme.error, width: 1),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: borderRadius,
            borderSide: BorderSide(color: theme.colorScheme.error, width: 2),
          ),
          contentPadding: _getContentPadding(context),
          counterText: widget.showCharacterCount ? null : '',
        );

      case TextFieldVariant.underlined:
        return InputDecoration(
          hintText: widget.hint,
          hintStyle: DesignTokens.getBodyStyle(
            context,
            fontSize: _getTextFontSize(context),
            color: theme.colorScheme.onSurface.withValues(
              alpha: DesignTokens.opacityMedium,
            ),
          ),
          prefixIcon: widget.prefixIcon,
          suffixIcon: suffixIcon,
          prefixText: widget.prefixText,
          suffixText: widget.suffixText,
          filled: false,
          border: UnderlineInputBorder(
            borderSide: BorderSide(
              color: theme.colorScheme.outline.withValues(alpha: 0.3),
            ),
          ),
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(
              color: theme.colorScheme.outline.withValues(alpha: 0.3),
            ),
          ),
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
          ),
          errorBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: theme.colorScheme.error),
          ),
          focusedErrorBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: theme.colorScheme.error, width: 2),
          ),
          contentPadding: _getContentPadding(context),
          counterText: widget.showCharacterCount ? null : '',
        );
    }
  }

  Widget _buildIconContainer(Widget icon) {
    return Container(
      padding: EdgeInsets.all(DesignTokens.spaceSm),
      child: icon,
    );
  }

  BorderRadius _getBorderRadius() {
    return switch (widget.size) {
      TextFieldSize.small => DesignTokens.borderRadiusMd,
      TextFieldSize.medium => DesignTokens.borderRadiusLg,
      TextFieldSize.large => DesignTokens.borderRadiusXl,
    };
  }

  Color _getFillColor(ThemeData theme) {
    if (widget.variant == TextFieldVariant.underlined) {
      return Colors.transparent;
    }

    return theme.brightness == Brightness.light
        ? AppTheme.lightSurfaceColor
        : AppTheme.darkCardColor;
  }

  EdgeInsets _getContentPadding(BuildContext context) {
    return Responsive.responsive<EdgeInsets>(
      context,
      mobile: switch (widget.size) {
        TextFieldSize.small => const EdgeInsets.symmetric(
          horizontal: DesignTokens.spaceMd,
          vertical: DesignTokens.spaceSm,
        ),
        TextFieldSize.medium => const EdgeInsets.symmetric(
          horizontal: DesignTokens.spaceLg,
          vertical: DesignTokens.spaceMd,
        ),
        TextFieldSize.large => const EdgeInsets.symmetric(
          horizontal: DesignTokens.spaceXl,
          vertical: DesignTokens.spaceLg,
        ),
      },
      tablet: switch (widget.size) {
        TextFieldSize.small => const EdgeInsets.symmetric(
          horizontal: DesignTokens.spaceLg,
          vertical: DesignTokens.spaceMd,
        ),
        TextFieldSize.medium => const EdgeInsets.symmetric(
          horizontal: DesignTokens.spaceXl,
          vertical: DesignTokens.spaceLg,
        ),
        TextFieldSize.large => const EdgeInsets.symmetric(
          horizontal: DesignTokens.space2xl,
          vertical: DesignTokens.spaceXl,
        ),
      },
      desktop: switch (widget.size) {
        TextFieldSize.small => const EdgeInsets.symmetric(
          horizontal: DesignTokens.spaceXl,
          vertical: DesignTokens.spaceLg,
        ),
        TextFieldSize.medium => const EdgeInsets.symmetric(
          horizontal: DesignTokens.space2xl,
          vertical: DesignTokens.spaceXl,
        ),
        TextFieldSize.large => const EdgeInsets.symmetric(
          horizontal: DesignTokens.space3xl,
          vertical: DesignTokens.space2xl,
        ),
      },
    );
  }

  double _getTextFontSize(BuildContext context) {
    final baseFontSize = switch (widget.size) {
      TextFieldSize.small => 14.0,
      TextFieldSize.medium => 16.0,
      TextFieldSize.large => 18.0,
    };

    return Responsive.getFontSize(context, baseFontSize);
  }

  double _getLabelFontSize(BuildContext context) {
    final baseFontSize = switch (widget.size) {
      TextFieldSize.small => 12.0,
      TextFieldSize.medium => 14.0,
      TextFieldSize.large => 16.0,
    };

    return Responsive.getFontSize(context, baseFontSize);
  }

  double _getIconSize() {
    return switch (widget.size) {
      TextFieldSize.small => DesignTokens.iconSm,
      TextFieldSize.medium => DesignTokens.iconMd,
      TextFieldSize.large => DesignTokens.iconLg,
    };
  }
}
