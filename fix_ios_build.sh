#!/bin/bash

# iOS Build Fix Script for Coopvest Africa
# This script fixes the bundle identifier and configures the project for development

set -e

echo "🔧 Starting iOS Build Fix..."
echo ""

# Navigate to project directory
cd "$(dirname "$0")"

# Backup the original file
echo "📦 Creating backup of project.pbxproj..."
cp ios/Runner.xcodeproj/project.pbxproj ios/Runner.xcodeproj/project.pbxproj.backup
echo "✅ Backup created: ios/Runner.xcodeproj/project.pbxproj.backup"
echo ""

# Replace the bundle identifier
echo "🔄 Updating Bundle Identifier..."
echo "   From: com.example.coopvest"
echo "   To:   com.coopvestafrica.coopvest"
sed -i 's/com\.example\.coopvest/com.coopvestafrica.coopvest/g' ios/Runner.xcodeproj/project.pbxproj

# Update Info.plist if it exists
if [ -f "ios/Runner/Info.plist" ]; then
    echo "🔄 Updating Info.plist..."
    sed -i 's/com\.example\.coopvest/com.coopvestafrica.coopvest/g' ios/Runner/Info.plist
fi

echo "✅ Bundle identifier updated successfully!"
echo ""

# Update Podfile for better compatibility
echo "🔄 Updating Podfile for development builds..."
cat > ios/Podfile << 'EOF'
# Uncomment this line to define a global platform for your project
platform :ios, '12.0'

# CocoaPods analytics sends network stats synchronously affecting flutter build latency.
ENV['COCOAPODS_DISABLE_STATS'] = 'true'

project 'Runner', {
  'Debug' => :debug,
  'Profile' => :release,
  'Release' => :release,
}

def flutter_root
  generated_xcode_build_settings_path = File.expand_path(File.join('..', 'Flutter', 'Generated.xcconfig'), __FILE__)
  unless File.exist?(generated_xcode_build_settings_path)
    raise "#{generated_xcode_build_settings_path} must exist. If you're running pod install manually, make sure flutter pub get is executed first"
  end

  File.foreach(generated_xcode_build_settings_path) do |line|
    matches = line.match(/FLUTTER_ROOT\=(.*)/)
    return matches[1].strip if matches
  end
  raise "FLUTTER_ROOT not found in #{generated_xcode_build_settings_path}. Try deleting Generated.xcconfig, then run flutter pub get"
end

require File.expand_path(File.join('packages', 'flutter_tools', 'bin', 'podhelper'), flutter_root)

flutter_ios_podfile_setup

target 'Runner' do
  use_frameworks!
  use_modular_headers!

  flutter_install_all_ios_pods File.dirname(File.realpath(__FILE__))
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)
    
    target.build_configurations.each do |config|
      # Disable code signing for pods in debug mode
      if config.name == 'Debug'
        config.build_settings['CODE_SIGNING_ALLOWED'] = 'NO'
        config.build_settings['CODE_SIGNING_REQUIRED'] = 'NO'
      end
      
      # Set minimum deployment target
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '12.0'
    end
  end
end
EOF

echo "✅ Podfile updated!"
echo ""

echo "🎉 iOS Build Fix Complete!"
echo ""
echo "📋 Summary of Changes:"
echo "   ✅ Bundle ID changed to: com.coopvestafrica.coopvest"
echo "   ✅ Podfile updated for development builds"
echo "   ✅ Backup created: project.pbxproj.backup"
echo ""
echo "🚀 Next Steps:"
echo "   1. Run: flutter clean"
echo "   2. Run: flutter pub get"
echo "   3. Run: cd ios && pod install && cd .."
echo "   4. Run: flutter build ios --simulator"
echo ""
echo "💡 Note: This configuration is for simulator/development builds."
echo "   For App Store deployment, you'll need to configure code signing."
echo ""
