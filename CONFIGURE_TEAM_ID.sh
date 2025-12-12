#!/bin/bash

# iOS Code Signing Configuration Script
# This script configures your Xcode project with your Apple Developer Team ID

set -e

echo "🔐 iOS Code Signing Configuration"
echo "=================================="
echo ""

# Check if Team ID is provided
if [ -z "$1" ]; then
    echo "❌ Error: Team ID not provided"
    echo ""
    echo "Usage: ./CONFIGURE_TEAM_ID.sh YOUR_TEAM_ID"
    echo ""
    echo "Example: ./CONFIGURE_TEAM_ID.sh XXXXXXXXXX"
    echo ""
    echo "To find your Team ID:"
    echo "1. Go to https://developer.apple.com/account/"
    echo "2. Click 'Membership'"
    echo "3. Look for 'Team ID' (10-character code)"
    echo ""
    exit 1
fi

TEAM_ID="$1"

# Validate Team ID format (should be 10 characters)
if [ ${#TEAM_ID} -ne 10 ]; then
    echo "⚠️  Warning: Team ID should be 10 characters"
    echo "   Provided: $TEAM_ID (${#TEAM_ID} characters)"
    echo ""
    read -p "Continue anyway? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

echo "📝 Configuring with Team ID: $TEAM_ID"
echo ""

# Navigate to project directory
cd "$(dirname "$0")"

# Backup the original file
echo "📦 Creating backup..."
cp ios/Runner.xcodeproj/project.pbxproj ios/Runner.xcodeproj/project.pbxproj.backup.team
echo "✅ Backup created: ios/Runner.xcodeproj/project.pbxproj.backup.team"
echo ""

# Update project.pbxproj with Team ID
echo "🔄 Updating project.pbxproj with Team ID..."

# Add DEVELOPMENT_TEAM to all build configurations
sed -i '' "s/DEVELOPMENT_TEAM = \"\";/DEVELOPMENT_TEAM = \"$TEAM_ID\";/g" ios/Runner.xcodeproj/project.pbxproj

# Also add if it doesn't exist in some configurations
sed -i '' "s/CODE_SIGN_STYLE = Automatic;/CODE_SIGN_STYLE = Automatic;\n\t\t\t\tDEVELOPMENT_TEAM = \"$TEAM_ID\";/g" ios/Runner.xcodeproj/project.pbxproj

echo "✅ Team ID added to project configuration"
echo ""

# Verify the changes
echo "🔍 Verifying changes..."
TEAM_COUNT=$(grep -c "DEVELOPMENT_TEAM = \"$TEAM_ID\"" ios/Runner.xcodeproj/project.pbxproj || echo "0")
echo "✅ Found $TEAM_COUNT instances of Team ID in project.pbxproj"
echo ""

echo "🎉 Configuration Complete!"
echo ""
echo "📋 Summary:"
echo "   Team ID: $TEAM_ID"
echo "   Bundle ID: com.coopvestafrica.coopvest"
echo "   Project: ios/Runner.xcodeproj"
echo ""
echo "🚀 Next Steps:"
echo "   1. Open Xcode: open ios/Runner.xcworkspace"
echo "   2. Select Runner project → Runner target"
echo "   3. Go to Signing & Capabilities tab"
echo "   4. Verify Team is selected: $TEAM_ID"
echo "   5. Build: flutter build ios --release"
echo ""
echo "💡 Tips:"
echo "   - Make sure your device is registered in Apple Developer Portal"
echo "   - Ensure provisioning profile is installed"
echo "   - Connect your device via USB before building"
echo ""
