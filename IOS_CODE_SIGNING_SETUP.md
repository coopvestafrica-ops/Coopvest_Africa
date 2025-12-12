# 🔐 iOS Code Signing Setup Guide - Complete Instructions

## 🔍 Current Error Analysis

**Error**: `No Accounts: Add a new account in Accounts settings`

**Root Cause**: 
- No Apple Developer account is configured in Xcode
- No provisioning profiles exist for your bundle ID
- No development team is selected in the project

## 📋 Prerequisites

Before starting, you need:

1. **Apple Developer Account** ($99/year)
   - Enroll at: https://developer.apple.com/programs/
   - Takes 24-48 hours to activate

2. **Mac with Xcode** (for some steps)
   - Xcode 14.0 or later
   - Can be installed from App Store

3. **Your Apple ID**
   - The email you use for Apple Developer Program
   - Password for authentication

4. **Physical iOS Device** (optional, for testing)
   - iPhone or iPad with iOS 15.0+
   - Connected via USB

## 🚀 Step-by-Step Setup

### Step 1: Enroll in Apple Developer Program

1. Go to: https://developer.apple.com/programs/
2. Click "Enroll"
3. Sign in with your Apple ID (or create one)
4. Complete the enrollment process
5. Pay the $99 annual fee
6. Wait 24-48 hours for activation

**Status**: ⏳ Takes 1-2 days

---

### Step 2: Add Apple ID to Xcode

On your Mac with Xcode:

```bash
# Open Xcode
open -a Xcode

# Or open your project directly
open ios/Runner.xcworkspace
```

**In Xcode**:
1. Go to: **Xcode → Preferences** (or **Xcode → Settings** on newer versions)
2. Click **Accounts** tab
3. Click **+** button to add account
4. Select **Apple ID**
5. Enter your Apple ID email
6. Click **Sign In**
7. Enter your password
8. Allow Xcode to access your keychain
9. Close preferences

**Status**: ✅ Takes 2-3 minutes

---

### Step 3: Create App ID in Apple Developer Portal

1. Go to: https://developer.apple.com/account/
2. Sign in with your Apple ID
3. Go to **Certificates, Identifiers & Profiles**
4. Click **Identifiers** → **+** button
5. Select **App IDs**
6. Choose **App**
7. Fill in:
   - **Description**: Coopvest Africa
   - **Bundle ID**: `com.coopvestafrica.coopvest`
   - **Capabilities**: Select needed ones (Push Notifications, etc.)
8. Click **Continue** → **Register** → **Done**

**Status**: ✅ Takes 5 minutes

---

### Step 4: Register Your Device (if testing on physical device)

1. In Apple Developer Portal, go to **Devices**
2. Click **+** button
3. Select **Register a Device**
4. Enter:
   - **Device Name**: Your iPhone name
   - **Device ID (UDID)**: Get from Xcode or iTunes
5. Click **Continue** → **Register** → **Done**

**To get Device UDID**:
```bash
# Connect your iPhone via USB
# In Xcode: Window → Devices and Simulators
# Select your device
# Copy the Identifier (UDID)
```

**Status**: ✅ Takes 5 minutes

---

### Step 5: Create Development Certificate

1. In Apple Developer Portal, go to **Certificates**
2. Click **+** button
3. Select **iOS App Development**
4. Click **Continue**
5. Follow instructions to create Certificate Signing Request (CSR)
   - On Mac: Open **Keychain Access**
   - Go to **Keychain Access → Certificate Assistant → Request a Certificate from a Certificate Authority**
   - Enter your email and name
   - Save to disk
6. Upload the CSR file
7. Click **Continue** → **Download**
8. Double-click the downloaded certificate to install in Keychain

**Status**: ✅ Takes 10 minutes

---

### Step 6: Create Provisioning Profile

1. In Apple Developer Portal, go to **Provisioning Profiles**
2. Click **+** button
3. Select **iOS App Development**
4. Click **Continue**
5. Select your App ID: `com.coopvestafrica.coopvest`
6. Click **Continue**
7. Select your Development Certificate
8. Click **Continue**
9. Select your device (if testing on physical device)
10. Click **Continue**
11. Enter Profile Name: `Coopvest Africa Development`
12. Click **Generate** → **Download**
13. Double-click to install in Xcode

**Status**: ✅ Takes 5 minutes

---

### Step 7: Configure Xcode Project

On your Mac with Xcode:

```bash
open ios/Runner.xcworkspace
```

**In Xcode**:
1. Select **Runner** project in navigator
2. Select **Runner** target
3. Go to **Signing & Capabilities** tab
4. Under **Signing**:
   - Check **Automatically manage signing**
   - Select your **Team** from dropdown
   - Verify **Bundle Identifier**: `com.coopvestafrica.coopvest`
5. Xcode will automatically create/select provisioning profiles
6. Close Xcode

**Status**: ✅ Takes 3 minutes

---

### Step 8: Update Flutter Project Configuration

Update your `ios/Runner.xcodeproj/project.pbxproj`:

Add your Team ID to the build settings:

```
DEVELOPMENT_TEAM = YOUR_TEAM_ID;
CODE_SIGN_STYLE = Automatic;
```

**To find your Team ID**:
1. In Apple Developer Portal, go to **Membership**
2. Look for **Team ID** (10-character code)

**Status**: ✅ Takes 2 minutes

---

### Step 9: Build and Deploy

```bash
cd /workspace/Coopvest_Africa

# Clean build
flutter clean

# Get dependencies
flutter pub get

# Install pods
cd ios && pod install && cd ..

# Build for physical device
flutter build ios --release

# Or run directly on device
flutter run -d ios
```

**Status**: ✅ Takes 5-10 minutes

---

## 🎯 Quick Reference: What You Need

| Item | Where to Get | Cost | Time |
|------|-------------|------|------|
| Apple Developer Account | developer.apple.com | $99/year | 24-48 hours |
| Apple ID | appleid.apple.com | Free | 5 minutes |
| Development Certificate | Apple Developer Portal | Free | 10 minutes |
| Provisioning Profile | Apple Developer Portal | Free | 5 minutes |
| Xcode Configuration | Xcode on Mac | Free | 5 minutes |

**Total Cost**: $99/year
**Total Time**: 1-2 days (mostly waiting for Apple)

---

## 🔑 Key Information to Save

Once you complete setup, save these:

```
Apple ID: your-email@example.com
Team ID: XXXXXXXXXX (10 characters)
Bundle ID: com.coopvestafrica.coopvest
Certificate Name: iOS Development
Profile Name: Coopvest Africa Development
```

---

## ⚠️ Common Issues & Solutions

### Issue 1: "No Accounts in Xcode"
**Solution**: Add your Apple ID in Xcode Preferences → Accounts

### Issue 2: "Certificate not found"
**Solution**: 
1. Download certificate from Apple Developer Portal
2. Double-click to install in Keychain
3. Restart Xcode

### Issue 3: "Provisioning profile not found"
**Solution**:
1. Download profile from Apple Developer Portal
2. Double-click to install
3. In Xcode, go to Preferences → Accounts → Download Manual Profiles

### Issue 4: "Device not registered"
**Solution**: Register device UDID in Apple Developer Portal

### Issue 5: "Bundle ID mismatch"
**Solution**: Ensure bundle ID matches exactly:
- In Xcode: `com.coopvestafrica.coopvest`
- In Apple Developer Portal: `com.coopvestafrica.coopvest`

---

## 🔄 Automated Configuration (Optional)

If you have all credentials, I can help automate the Xcode project configuration:

```bash
# Set your Team ID
export DEVELOPMENT_TEAM="XXXXXXXXXX"

# Update project.pbxproj
sed -i "s/DEVELOPMENT_TEAM = \"\"/DEVELOPMENT_TEAM = \"$DEVELOPMENT_TEAM\"/g" \
  ios/Runner.xcodeproj/project.pbxproj
```

---

## 📱 Testing on Physical Device

Once code signing is set up:

```bash
# Connect your iPhone via USB
# List available devices
flutter devices

# Run on your device
flutter run -d <device-id>

# Or build release version
flutter build ios --release
```

---

## 🚀 For CI/CD (Bitrise)

If using Bitrise for automated builds:

1. Export certificates and profiles
2. Upload to Bitrise Code Signing section
3. Configure build step with your Team ID
4. Bitrise will handle signing automatically

---

## 📞 Support Resources

- [Apple Developer Program](https://developer.apple.com/programs/)
- [Xcode Code Signing Guide](https://developer.apple.com/support/code-signing/)
- [Flutter iOS Deployment](https://flutter.dev/docs/deployment/ios)
- [Apple Developer Account Help](https://support.apple.com/en-us/HT204034)

---

## ✅ Checklist

- [ ] Enrolled in Apple Developer Program
- [ ] Added Apple ID to Xcode
- [ ] Created App ID in Developer Portal
- [ ] Registered device (if testing on physical device)
- [ ] Created Development Certificate
- [ ] Created Provisioning Profile
- [ ] Configured Xcode project
- [ ] Updated project.pbxproj with Team ID
- [ ] Tested build on device

---

## 🎉 Success Indicators

After setup, you should be able to:
- ✅ Build iOS app for physical device
- ✅ Deploy to your iPhone/iPad
- ✅ Run app on physical device
- ✅ See app on home screen
- ✅ Test all features

---

**Status**: 📋 Ready for setup
**Next Action**: Start with Step 1 (Apple Developer Program enrollment)
**Timeline**: 1-2 days total (mostly waiting for Apple)

---

## 🎯 Alternative: Use Simulator (No Setup Needed)

If you want to test immediately without code signing:

```bash
cd /workspace/Coopvest_Africa
flutter run -d ios  # Runs on iOS Simulator
```

**Simulator Testing**:
- ✅ No Apple Developer account needed
- ✅ No code signing required
- ✅ Works immediately
- ✅ Perfect for development
- ❌ Can't test on physical device
- ❌ Can't submit to App Store

---

**Choose your path**:
1. **Physical Device Testing** → Follow this guide (1-2 days setup)
2. **Simulator Testing** → Run `flutter run -d ios` (works now!)
