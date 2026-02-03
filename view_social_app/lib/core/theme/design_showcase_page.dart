import 'package:flutter/material.dart';
import 'design_tokens.dart';
import 'app_theme.dart';
import 'responsive.dart';
import '../../shared/widgets/custom_button.dart';
import '../../shared/widgets/custom_text_field.dart';

class DesignShowcasePage extends StatefulWidget {
  const DesignShowcasePage({super.key});

  @override
  State<DesignShowcasePage> createState() => _DesignShowcasePageState();
}

class _DesignShowcasePageState extends State<DesignShowcasePage> {
  final _textController = TextEditingController();

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Design System Showcase',
          style: DesignTokens.getHeadingStyle(
            context,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              theme.brightness == Brightness.light 
                  ? Icons.dark_mode_outlined 
                  : Icons.light_mode_outlined,
            ),
            onPressed: () {
              // This would toggle theme in a real app
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Theme toggle would be implemented with state management',
                    style: DesignTokens.getBodyStyle(context, fontSize: 14, color: AppTheme.white),
                  ),
                  backgroundColor: AppTheme.infoColor,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: DesignTokens.borderRadiusLg,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: Responsive.getHorizontalPadding(context).copyWith(
          top: DesignTokens.spaceLg,
          bottom: DesignTokens.space3xl,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(
              context,
              'Colors',
              _buildColorPalette(context),
            ),
            
            _buildSection(
              context,
              'Typography',
              _buildTypography(context),
            ),
            
            _buildSection(
              context,
              'Buttons',
              _buildButtons(context),
            ),
            
            _buildSection(
              context,
              'Text Fields',
              _buildTextFields(context),
            ),
            
            _buildSection(
              context,
              'Cards & Surfaces',
              _buildCards(context),
            ),
            
            _buildSection(
              context,
              'Spacing & Layout',
              _buildSpacing(context),
            ),
            
            _buildSection(
              context,
              'Chat Components',
              _buildChatComponents(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, Widget content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: DesignTokens.getHeadingStyle(
            context,
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: DesignTokens.spaceLg),
        content,
        SizedBox(height: DesignTokens.space4xl),
      ],
    );
  }

  Widget _buildColorPalette(BuildContext context) {
    return Column(
      children: [
        _buildColorRow(context, 'Primary Colors', [
          _ColorItem('Deep Purple', AppTheme.deepPurple),
          _ColorItem('Bright Purple', AppTheme.brightPurple),
          _ColorItem('Light Purple', AppTheme.lightPurple),
          _ColorItem('White', AppTheme.white),
        ]),
        SizedBox(height: DesignTokens.spaceLg),
        _buildColorRow(context, 'Status Colors', [
          _ColorItem('Success', AppTheme.successColor),
          _ColorItem('Warning', AppTheme.warningColor),
          _ColorItem('Error', AppTheme.errorColor),
          _ColorItem('Info', AppTheme.infoColor),
        ]),
      ],
    );
  }

  Widget _buildColorRow(BuildContext context, String title, List<_ColorItem> colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: DesignTokens.getBodyStyle(
            context,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: DesignTokens.spaceMd),
        Wrap(
          spacing: DesignTokens.spaceMd,
          runSpacing: DesignTokens.spaceMd,
          children: colors.map((color) => _buildColorSwatch(context, color)).toList(),
        ),
      ],
    );
  }

  Widget _buildColorSwatch(BuildContext context, _ColorItem colorItem) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: colorItem.color,
            borderRadius: DesignTokens.borderRadiusLg,
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
        ),
        SizedBox(height: DesignTokens.spaceXs),
        Text(
          colorItem.name,
          style: DesignTokens.getCaptionStyle(
            context,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildTypography(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Display Large',
          style: DesignTokens.getHeadingStyle(
            context,
            fontSize: 32,
            fontWeight: FontWeight.w400,
          ),
        ),
        SizedBox(height: DesignTokens.spaceSm),
        Text(
          'Headline Large',
          style: DesignTokens.getHeadingStyle(
            context,
            fontSize: 24,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: DesignTokens.spaceSm),
        Text(
          'Title Large',
          style: DesignTokens.getHeadingStyle(
            context,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: DesignTokens.spaceSm),
        Text(
          'Body Large - This is the main body text used throughout the application. It provides good readability and follows our typography scale.',
          style: DesignTokens.getBodyStyle(
            context,
            fontSize: 16,
            fontWeight: FontWeight.w400,
          ),
        ),
        SizedBox(height: DesignTokens.spaceSm),
        Text(
          'Body Medium - Secondary body text for descriptions and supporting content.',
          style: DesignTokens.getBodyStyle(
            context,
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
        ),
        SizedBox(height: DesignTokens.spaceSm),
        Text(
          'Caption - Small text for labels, timestamps, and metadata.',
          style: DesignTokens.getCaptionStyle(
            context,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildButtons(BuildContext context) {
    return Column(
      children: [
        // Button Types
        Wrap(
          spacing: DesignTokens.spaceMd,
          runSpacing: DesignTokens.spaceMd,
          children: [
            CustomButton(
              text: 'Primary',
              onPressed: () => _showSnackBar(context, 'Primary button pressed'),
              type: ButtonType.primary,
            ),
            CustomButton(
              text: 'Secondary',
              onPressed: () => _showSnackBar(context, 'Secondary button pressed'),
              type: ButtonType.secondary,
            ),
            CustomButton(
              text: 'Outline',
              onPressed: () => _showSnackBar(context, 'Outline button pressed'),
              type: ButtonType.outline,
            ),
            CustomButton(
              text: 'Text',
              onPressed: () => _showSnackBar(context, 'Text button pressed'),
              type: ButtonType.text,
            ),
            CustomButton(
              text: 'Ghost',
              onPressed: () => _showSnackBar(context, 'Ghost button pressed'),
              type: ButtonType.ghost,
            ),
          ],
        ),
        
        SizedBox(height: DesignTokens.space2xl),
        
        // Button Sizes
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Button Sizes',
              style: DesignTokens.getBodyStyle(
                context,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: DesignTokens.spaceMd),
            CustomButton(
              text: 'Small Button',
              onPressed: () => _showSnackBar(context, 'Small button pressed'),
              size: ButtonSize.small,
            ),
            SizedBox(height: DesignTokens.spaceSm),
            CustomButton(
              text: 'Medium Button',
              onPressed: () => _showSnackBar(context, 'Medium button pressed'),
              size: ButtonSize.medium,
            ),
            SizedBox(height: DesignTokens.spaceSm),
            CustomButton(
              text: 'Large Button',
              onPressed: () => _showSnackBar(context, 'Large button pressed'),
              size: ButtonSize.large,
            ),
            SizedBox(height: DesignTokens.spaceSm),
            CustomButton(
              text: 'Extra Large Button',
              onPressed: () => _showSnackBar(context, 'Extra large button pressed'),
              size: ButtonSize.extraLarge,
            ),
          ],
        ),
        
        SizedBox(height: DesignTokens.space2xl),
        
        // Button States
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Button States',
              style: DesignTokens.getBodyStyle(
                context,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: DesignTokens.spaceMd),
            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    text: 'Loading',
                    onPressed: () {},
                    isLoading: true,
                    fullWidth: true,
                  ),
                ),
                SizedBox(width: DesignTokens.spaceMd),
                Expanded(
                  child: CustomButton(
                    text: 'Disabled',
                    onPressed: null,
                    fullWidth: true,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTextFields(BuildContext context) {
    return Column(
      children: [
        CustomTextField(
          label: 'Default Text Field',
          hint: 'Enter some text',
          controller: _textController,
        ),
        
        SizedBox(height: DesignTokens.spaceLg),
        
        CustomTextField(
          label: 'Email Field',
          hint: 'Enter your email',
          keyboardType: TextInputType.emailAddress,
          prefixIcon: Icon(
            Icons.email_outlined,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        
        SizedBox(height: DesignTokens.spaceLg),
        
        CustomTextField(
          label: 'Password Field',
          hint: 'Enter your password',
          obscureText: true,
          prefixIcon: Icon(
            Icons.lock_outlined,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        
        SizedBox(height: DesignTokens.spaceLg),
        
        CustomTextField(
          label: 'Large Text Field',
          hint: 'This is a large text field',
          size: TextFieldSize.large,
          helperText: 'This is helper text to provide additional context',
        ),
        
        SizedBox(height: DesignTokens.spaceLg),
        
        CustomTextField(
          label: 'Multiline Text Field',
          hint: 'Enter multiple lines of text',
          maxLines: 4,
          minLines: 3,
          showCharacterCount: true,
          maxLength: 200,
        ),
      ],
    );
  }

  Widget _buildCards(BuildContext context) {
    return Column(
      children: [
        Card(
          child: Padding(
            padding: DesignTokens.paddingLg,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Default Card',
                  style: DesignTokens.getHeadingStyle(
                    context,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: DesignTokens.spaceSm),
                Text(
                  'This is a default card with standard padding and styling according to our design system.',
                  style: DesignTokens.getBodyStyle(
                    context,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
        
        SizedBox(height: DesignTokens.spaceLg),
        
        Container(
          width: double.infinity,
          padding: DesignTokens.paddingLg,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.primaryColor.withValues(alpha: 0.1),
                AppTheme.lightPurple.withValues(alpha: 0.1),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: DesignTokens.borderRadiusXl,
            border: Border.all(
              color: AppTheme.primaryColor.withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Gradient Card',
                style: DesignTokens.getHeadingStyle(
                  context,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: DesignTokens.spaceSm),
              Text(
                'This card uses our brand gradient and demonstrates elevated styling.',
                style: DesignTokens.getBodyStyle(
                  context,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSpacing(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Spacing Scale (8pt Grid)',
          style: DesignTokens.getBodyStyle(
            context,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: DesignTokens.spaceLg),
        ..._buildSpacingExamples(context),
      ],
    );
  }

  List<Widget> _buildSpacingExamples(BuildContext context) {
    final spacings = [
      ('xs', DesignTokens.spaceXs),
      ('sm', DesignTokens.spaceSm),
      ('md', DesignTokens.spaceMd),
      ('lg', DesignTokens.spaceLg),
      ('xl', DesignTokens.spaceXl),
      ('2xl', DesignTokens.space2xl),
      ('3xl', DesignTokens.space3xl),
    ];

    return spacings.map((spacing) {
      return Padding(
        padding: EdgeInsets.only(bottom: DesignTokens.spaceSm),
        child: Row(
          children: [
            SizedBox(
              width: 40,
              child: Text(
                spacing.$1,
                style: DesignTokens.getCaptionStyle(
                  context,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Container(
              width: spacing.$2,
              height: 16,
              color: AppTheme.primaryColor,
            ),
            SizedBox(width: DesignTokens.spaceSm),
            Text(
              '${spacing.$2.toInt()}px',
              style: DesignTokens.getCaptionStyle(
                context,
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildChatComponents(BuildContext context) {
    return Column(
      children: [
        _buildChatBubble(context, 'Hello! This is a sent message.', true),
        SizedBox(height: DesignTokens.spaceSm),
        _buildChatBubble(context, 'This is a received message with some longer text to show how it wraps.', false),
        SizedBox(height: DesignTokens.spaceSm),
        _buildChatBubble(context, 'Another sent message! 😊', true),
      ],
    );
  }

  Widget _buildChatBubble(BuildContext context, String message, bool isSent) {
    return Align(
      alignment: isSent ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: Responsive.getChatBubbleMaxWidth(context),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.spaceMd,
          vertical: DesignTokens.spaceSm,
        ),
        decoration: BoxDecoration(
          color: isSent 
              ? AppTheme.primaryColor 
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: isSent 
              ? DesignTokens.chatBubbleRadiusReverse 
              : DesignTokens.chatBubbleRadius,
        ),
        child: Text(
          message,
          style: DesignTokens.getBodyStyle(
            context,
            fontSize: 14,
            color: isSent 
                ? AppTheme.white 
                : Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
    );
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: DesignTokens.getBodyStyle(context, fontSize: 14, color: AppTheme.white),
        ),
        backgroundColor: AppTheme.successColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: DesignTokens.borderRadiusLg,
        ),
      ),
    );
  }
}

class _ColorItem {
  final String name;
  final Color color;

  _ColorItem(this.name, this.color);
}