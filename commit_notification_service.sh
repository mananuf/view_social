#!/bin/bash

# Git commit script for notification service and UI improvements
# This script commits all changes related to abstract background, Docker configuration, and UI fixes

set -e  # Exit on any error

# Check if we're in a git repository
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo "Error: Not in a git repository"
    exit 1
fi

echo "🚀 Starting git commit process for notification service and UI improvements..."

# Add all changes
echo "📁 Adding all changes to staging area..."
git add .

# Check if there are any changes to commit
if git diff --cached --quiet; then
    echo "ℹ️  No changes to commit"
    exit 0
fi

# Show what will be committed
echo "📋 Changes to be committed:"
git diff --cached --name-status

# Create comprehensive commit
echo "💾 Creating commit..."
git commit -m "feat: implement abstract background and fix Docker/UI issues

🎨 Abstract Background Implementation:
- Created reusable AbstractBackground widget with VIEW purple theme
- Added flowing wave shapes and circular elements with gradients
- Implemented both static and animated versions
- Fixed color references to use AppTheme.primaryDarkColor
- Updated deprecated withOpacity() to withValues() for Flutter compatibility

🐳 Docker Configuration Fixes:
- Updated API constants for Docker container environment
- Maintained platform-specific host addresses (10.0.2.2 for Android, localhost for iOS)
- Added Docker environment comments for clarity

🔧 UI Improvements:
- Fixed home page bottom navigation overflow issues
- Reduced navigation bar height from 80px to 70px
- Wrapped navigation items in Expanded widgets for proper spacing
- Reduced spacing between icon and label to prevent overflow

🎨 Welcome Page Enhancement:
- Integrated AbstractBackground into welcome page
- Updated text colors to white for better contrast on purple background
- Enhanced logo container with white gradient and shadow effects
- Applied gradient to primary buttons for consistent branding
- Updated social login buttons to use white outline style

📱 Responsive Design:
- Maintained responsive breakpoints and sizing
- Ensured proper contrast ratios for accessibility
- Optimized for mobile, tablet, and desktop viewports

🔍 Technical Details:
- Backend routes properly nested under /api/v1/auth/*
- Authentication flow: register → verify → login with JWT tokens
- 6-digit verification codes supported
- Comprehensive error handling for network requests
- Token storage and persistent authentication implemented

This commit addresses Docker container connectivity, UI overflow issues,
and implements the requested abstract background design following
VIEW Social design system guidelines."

echo "✅ Commit created successfully!"

# Show the commit
echo "📄 Commit details:"
git log -1 --oneline

echo "🎉 All changes committed successfully!"
echo "💡 Next steps:"
echo "   - Test the app with Docker backend"
echo "   - Verify abstract background renders correctly"
echo "   - Check navigation overflow is resolved"
echo "   - Test authentication flow with proper routes"