---
inclusion: always
---

# VIEW Social Design System

This design system is inspired by modern chat applications and AI interfaces, specifically drawing from:
- [E-Chat UI Kit](https://www.figma.com/design/aSQ7IWT20JyUiaPaaEpo7h/Chatting-App-UI-Kit-Design-%7C-E-Chat-%7C-Figma--Community-?node-id=21-122&p=f&t=YksPeiXGtjVnXGDf-0)
- [BrainBox AI ChatBot](https://www.figma.com/design/hN6WoxlKSiwqQT9hbW54BX/BrainBox-Ai-ChatBot-Mobile-App-Full-100--Free-UI-Kit--Community-?node-id=0-1&p=f&t=xvsYn2pptdmdPOeU-0)
- Laravel.com typography (Nunito Sans)

## Color Palette

### Primary Brand Colors
- **Deep Purple**: `#6A0DAD` - Primary brand color for buttons, links, and key UI elements
- **Bright Purple**: `#A500E0` - Secondary actions and highlights
- **Light Purple**: `#CF71F4` - Accents and subtle highlights
- **White**: `#FFFFFF` - Text on dark backgrounds and surface colors

### Extended Palette
- **Primary Dark**: `#4A0A7A` - Darker variant for hover states
- **Success**: `#10B981` - Success states and positive actions
- **Warning**: `#F59E0B` - Warning states and caution
- **Error**: `#EF4444` - Error states and destructive actions
- **Info**: `#3B82F6` - Informational states

### Background Colors
- **Light Background**: `#FAFAFC` - Main background for light theme
- **Dark Background**: `#0F0F0F` - Main background for dark theme
- **Light Surface**: `#FFFFFF` - Cards and elevated surfaces (light)
- **Dark Surface**: `#1A1A1A` - Cards and elevated surfaces (dark)

### Text Colors
- **Light Primary Text**: `#1A1A1A` - Primary text in light theme
- **Light Secondary Text**: `#6B7280` - Secondary text in light theme
- **Dark Primary Text**: `#F9FAFB` - Primary text in dark theme
- **Dark Secondary Text**: `#D1D5DB` - Secondary text in dark theme

## Typography

### Font Family
- **Primary**: Nunito Sans (Google Fonts)
- **Fallback**: System fonts (-apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif)

### Font Scale
- **Display Large**: 57px, Regular, -0.25 letter-spacing
- **Display Medium**: 45px, Regular
- **Display Small**: 36px, Regular
- **Headline Large**: 32px, SemiBold
- **Headline Medium**: 28px, SemiBold
- **Headline Small**: 24px, SemiBold
- **Title Large**: 22px, SemiBold
- **Title Medium**: 16px, SemiBold, 0.15 letter-spacing
- **Title Small**: 14px, SemiBold, 0.1 letter-spacing
- **Body Large**: 16px, Regular, 0.5 letter-spacing
- **Body Medium**: 14px, Regular, 0.25 letter-spacing
- **Body Small**: 12px, Regular, 0.4 letter-spacing
- **Label Large**: 14px, SemiBold, 0.1 letter-spacing
- **Label Medium**: 12px, SemiBold, 0.5 letter-spacing
- **Label Small**: 11px, SemiBold, 0.5 letter-spacing

## Spacing System (8pt Grid)

- **2xs**: 2px
- **xs**: 4px
- **sm**: 8px
- **md**: 12px
- **lg**: 16px
- **xl**: 20px
- **2xl**: 24px
- **3xl**: 32px
- **4xl**: 40px
- **5xl**: 48px
- **6xl**: 64px
- **7xl**: 80px
- **8xl**: 96px

## Border Radius Scale

- **xs**: 4px - Small elements
- **sm**: 6px - Chips, tags
- **md**: 8px - Small buttons
- **lg**: 12px - Default buttons, inputs
- **xl**: 16px - Cards, large buttons
- **2xl**: 20px - Large cards
- **3xl**: 24px - Modals, dialogs
- **full**: 9999px - Pills, avatars

## Component Guidelines

### Buttons
- **Primary**: Deep purple background, white text
- **Secondary**: Bright purple background, dark text
- **Outline**: Transparent background, primary border and text
- **Text**: Transparent background, primary text
- **Ghost**: Transparent background, subtle hover effect

#### Button Sizes
- **Small**: 36px height, 12px vertical padding
- **Medium**: 44px height, 16px vertical padding (default)
- **Large**: 52px height, 20px vertical padding
- **Extra Large**: 60px height, 24px vertical padding

### Text Fields
- **Variants**: Outlined (default), Filled, Underlined
- **Sizes**: Small, Medium (default), Large
- **States**: Default, Focused, Error, Disabled
- **Border radius**: 12px for medium, 16px for large

### Cards
- **Background**: White (light) / #242424 (dark)
- **Border**: 0.5px solid border color
- **Border radius**: 16px
- **Elevation**: None (flat design)
- **Padding**: 16px (mobile), 24px (tablet), 32px (desktop)

### Chat Bubbles
- **Sent messages**: Primary color background
- **Received messages**: Light gray background
- **Border radius**: 16px with small radius on message tail side
- **Max width**: 75% of screen width (mobile), 60% (tablet), 400px (desktop)
- **Padding**: 12px horizontal, 8px vertical

### Navigation
- **Mobile/Tablet**: Bottom navigation bar
- **Desktop**: Side navigation rail
- **Active state**: Primary color with background tint
- **Inactive state**: Gray with reduced opacity

## Responsive Breakpoints

- **Mobile**: < 480px
- **Mobile Large**: 480px - 640px
- **Tablet**: 640px - 768px
- **Tablet Large**: 768px - 1024px
- **Desktop**: 1024px - 1280px
- **Desktop Large**: > 1280px

## Animation Guidelines

### Durations
- **Fast**: 150ms - Micro-interactions
- **Normal**: 250ms - Standard transitions
- **Slow**: 350ms - Complex animations
- **Slower**: 500ms - Page transitions

### Easing
- **Ease In**: For elements leaving the screen
- **Ease Out**: For elements entering the screen
- **Ease In Out**: For elements moving within the screen
- **Spring**: For playful interactions

## Accessibility

### Color Contrast
- All text meets WCAG AA standards (4.5:1 ratio)
- Interactive elements have sufficient contrast
- Focus indicators are clearly visible

### Touch Targets
- Minimum 44px touch target size
- Adequate spacing between interactive elements
- Clear visual feedback for interactions

### Typography
- Scalable text that works with system font size preferences
- Sufficient line height for readability (1.4-1.6)
- Appropriate font weights for hierarchy

## Dark Theme Adaptations

- **Primary colors**: Brighter variants for better visibility
- **Backgrounds**: True black (#0F0F0F) for OLED optimization
- **Surfaces**: Dark gray (#1A1A1A) for cards and elevated content
- **Text**: High contrast white/gray for readability
- **Borders**: Subtle gray borders for definition

## Chat-Specific Design Patterns

### Message Layout
- **Avatar**: 32px circular, positioned at message start
- **Timestamp**: 12px text, positioned below message
- **Status indicators**: Read receipts, delivery status
- **Typing indicators**: Animated dots in brand color

### Input Area
- **Height**: 48px minimum
- **Padding**: 12px horizontal
- **Send button**: Primary color, positioned at end
- **Attachment button**: Ghost style, positioned at start

### Conversation List
- **Item height**: 72px
- **Avatar**: 48px circular
- **Last message preview**: Secondary text color
- **Unread indicator**: Primary color dot
- **Timestamp**: Top right, secondary text

## Implementation Notes

### Flutter Specific
- Use `Material 3` design system as base
- Implement `ThemeMode.system` for automatic theme switching
- Use `Google Fonts` package for Nunito Sans
- Implement responsive design with custom `Responsive` class
- Use `DesignTokens` class for consistent spacing and sizing

### Performance Considerations
- Optimize font loading with `google_fonts` caching
- Use `const` constructors where possible
- Implement efficient list rendering for chat messages
- Cache network images with `cached_network_image`

### Testing
- Test on multiple screen sizes and orientations
- Verify color contrast in both light and dark themes
- Test with system font size adjustments
- Validate touch target sizes on physical devices

This design system ensures consistency across the VIEW Social app while maintaining modern aesthetics and excellent user experience across all platforms and screen sizes.