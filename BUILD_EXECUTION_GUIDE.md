# Coopvest Flutter App - APK Build Execution Guide

**Date:** November 17, 2025
**Status:** ✅ READY TO BUILD
**Confidence:** 95%

---

## 🚀 BUILD EXECUTION - STEP BY STEP

### Prerequisites Check (Run First)

```bash
# Verify Flutter is installed and working
flutter --version

# Verify Android SDK is accessible
flutter doctor

# Verify project structure
ls -la pubspec.yaml
ls -la android/app/build.gradle.kts
```

---

## 📝 Build Execution Plan

### Phase 1: Preparation (2 minutes)

**1. Clean Build Cache**
```bash
cd c:\Users\Teejayfpi\3D Objects\Coopvest
flutter clean
```
**Expected Output:**
```
Cleaning build outputs...
Deleting build...
```

**2. Get Dependencies**
```bash
flutter pub get
```
**Expected Output:**
```
Resolving dependencies...
Running "flutter pub get"...
[DEPENDENCY LIST]
Got dependencies!
```

**3. Apply any fixes**
```bash
dart fix --apply
```
**Expected Output:**
```
Analyzing files...
Applying fixes...
```

---

### Phase 2: Verification (3 minutes)

**1. Analyze Code**
```bash
flutter analyze
```
**Expected Output:**
```
Analyzing /path/to/coopvest...
No issues found!
```

**2. Check Doctor**
```bash
flutter doctor -v
```
**Expected Output:**
```
✓ Flutter (Channel stable, X.X.X)
✓ Android toolchain (Android SDK version 36)
✓ Android Studio (X.X.X)
✓ VS Code (X.X.X)
✓ Connected device
```

---

### Phase 3: BUILD! (5-10 minutes)

#### Option A: Debug APK (for immediate testing)
```bash
flutter build apk
```

**Output:**
```
Building with Flutter...
Compiling application...
Linking application...
Built /path/to/build/app/outputs/apk/debug/app-debug.apk
```

**Result:** `build/app/outputs/apk/debug/app-debug.apk` (~100-150 MB)

---

#### Option B: Release APK - Split by ABI (RECOMMENDED)
```bash
flutter build apk --split-per-abi --release
```

**Output:**
```
Building with Flutter...
Compiling application...
Built /path/to/build/app/outputs/apk/release/
  - app-armeabi-v7a-release.apk
  - app-arm64-v8a-release.apk
  - app-x86-release.apk
  - app-x86_64-release.apk
```

**Result:** 4 optimized APKs (~30-45 MB each)
**Use for:** Testing release performance, app stores

---

#### Option C: Android App Bundle (BEST FOR PLAY STORE)
```bash
flutter build appbundle --release
```

**Output:**
```
Building with Flutter...
Compiling application...
Built /path/to/build/app/outputs/bundle/release/app-release.aab
```

**Result:** `build/app/outputs/bundle/release/app-release.aab` (~50 MB)
**Use for:** Google Play Store (automatic optimization)

---

### Phase 4: Post-Build (5 minutes)

#### Find Your APK/Bundle
```bash
# Debug APK
ls build/app/outputs/apk/debug/

# Release APKs
ls build/app/outputs/apk/release/

# App Bundle
ls build/app/outputs/bundle/release/
```

#### Test on Device (Debug APK)
```bash
# Install on connected Android device
flutter install build/app/outputs/apk/debug/app-debug.apk

# Or use adb directly
adb install -r build/app/outputs/apk/debug/app-debug.apk
```

#### Verify Build Success
```bash
# Check file exists and size
ls -lh build/app/outputs/apk/debug/app-debug.apk

# Get file info
file build/app/outputs/apk/debug/app-debug.apk
```

---

## 🎯 QUICK START: Copy-Paste Commands

### For Testing (Fastest)
```bash
cd "c:\Users\Teejayfpi\3D Objects\Coopvest"
flutter clean
flutter pub get
flutter build apk
```
**Time: ~10 minutes**
**Result: Ready to test on device**

### For Release (Recommended)
```bash
cd "c:\Users\Teejayfpi\3D Objects\Coopvest"
flutter clean
flutter pub get
flutter build apk --split-per-abi --release
```
**Time: ~10 minutes**
**Result: 4 optimized APKs for distribution**

### For Play Store (Best)
```bash
cd "c:\Users\Teejayfpi\3D Objects\Coopvest"
flutter clean
flutter pub get
flutter build appbundle --release
```
**Time: ~10 minutes**
**Result: .aab file ready for Google Play**

---

## ✅ Expected Outputs

### Successful Build Messages
```
✓ Flutter gradle plugin initialized
✓ Resolving dependencies...
✓ Running "gradlew build"...
✓ Compiling Dart...
✓ Linking application...
✓ Build successful!
```

### Build Artifacts Locations
```
Debug APK:
build/app/outputs/apk/debug/app-debug.apk

Release APK (Split):
build/app/outputs/apk/release/app-armeabi-v7a-release.apk
build/app/outputs/apk/release/app-arm64-v8a-release.apk
build/app/outputs/apk/release/app-x86-release.apk
build/app/outputs/apk/release/app-x86_64-release.apk

App Bundle:
build/app/outputs/bundle/release/app-release.aab
```

### File Sizes (Typical)
```
Debug APK: 100-150 MB (includes debug symbols)
Release APK (armv7): 30-40 MB
Release APK (arm64): 35-45 MB
Release APK (x86): 35-45 MB
Release APK (x86_64): 40-50 MB
App Bundle: 50-60 MB (total, Play Store optimizes per device)
```

---

## ⚠️ Common Issues During Build

### Issue 1: Gradle Daemon Issues
**Error Message:** `Gradle build failed`

**Solution:**
```bash
flutter clean
rm -rf android/build
flutter pub get
flutter build apk
```

### Issue 2: Out of Memory
**Error Message:** `java.lang.OutOfMemoryError`

**Solution:** Increase gradle heap
```bash
# Edit android/gradle.properties
# Change this line to:
org.gradle.jvmargs=-Xmx16G -XX:MaxMetaspaceSize=4G
```

### Issue 3: Firebase Plugin Missing
**Error Message:** `google-services plugin not found`

**Solution:** Download google-services.json
```bash
# 1. Go to Firebase Console
# 2. Download google-services.json
# 3. Place in: android/app/google-services.json
# 4. Run build again
```

### Issue 4: Build Hangs
**Error Message:** `Waiting for gradle...` (stuck for 5+ minutes)

**Solution:** Kill gradle daemon
```bash
flutter clean
gradle --stop
flutter build apk
```

---

## 🔍 Monitoring Build Progress

### Verbose Build (See All Details)
```bash
flutter build apk --verbose
```
**Use for:** Debugging if build fails

### Build with Timing
```bash
# PowerShell: Measure build time
Measure-Command {flutter build apk --release}
```

### Monitor Memory Usage
```bash
# While build is running, in another terminal:
# Windows Task Manager to watch memory
# Or: Get-Process gradle | Format-Table WorkingSet
```

---

## ✨ After Successful Build

### Option 1: Install on Device (Debug)
```bash
adb devices  # List connected devices
adb install -r build/app/outputs/apk/debug/app-debug.apk
```

### Option 2: Share APK
```bash
# Copy APK to Desktop
cp build/app/outputs/apk/debug/app-debug.apk ~/Desktop/

# Or compress for easier sharing
Compress-Archive -Path build/app/outputs/apk/release/ -DestinationPath ~/coopvest-release-apks.zip
```

### Option 3: Upload to Play Store
```bash
# Open Play Console: https://play.google.com/console
# Upload: build/app/outputs/bundle/release/app-release.aab
# Or: upload individual APKs from build/app/outputs/apk/release/
```

---

## 📊 Build Performance Tips

### Speed Up Future Builds
```bash
# Don't use --clean on subsequent builds
flutter build apk  # Much faster than first time

# Use daemon mode (enabled by default)
# Keeps gradle daemon running for faster builds
```

### Optimize Build Size
```bash
# Use split-per-abi to reduce per-APK size
flutter build apk --split-per-abi --release

# Or use app bundle (best compression)
flutter build appbundle --release
```

### Parallel Gradle Build
```bash
# Add to android/gradle.properties
org.gradle.parallel=true
org.gradle.workers.max=8
```

---

## 🎯 Next Steps After Build

### 1. Test on Device (Required)
- [ ] Install APK on Android device
- [ ] Test app startup
- [ ] Test authentication
- [ ] Test key features
- [ ] Verify no crashes
- [ ] Check Firebase connection

### 2. For Play Store Release
- [ ] Update version in pubspec.yaml
- [ ] Create release notes
- [ ] Take app screenshots
- [ ] Write app description
- [ ] Set privacy policy URL
- [ ] Create signing key (if not done)
- [ ] Sign APK/Bundle
- [ ] Upload to Play Console

### 3. Monitoring
- [ ] Set up Firebase Crashlytics alerts
- [ ] Monitor analytics
- [ ] Check device-specific issues
- [ ] Track user feedback

---

## 📞 Troubleshooting Commands

```bash
# View build log
cat build/app/outputs/logs/gradle_build_*.log

# Check for errors
flutter build apk 2>&1 | grep -i error

# Get detailed gradle info
./gradlew -v

# Check Android version
adb shell getprop ro.build.version.release

# Verify signing key
keytool -list -v -keystore ~/coopvest.jks
```

---

## 🎉 Success Criteria

After build completes, verify:

- [x] No error messages in console
- [x] APK/Bundle file exists
- [x] File size is reasonable (not 0 bytes)
- [x] File timestamp is current (just built)
- [x] APK installs without errors
- [x] App launches without crash
- [x] Basic features work

---

## 📋 Build Checklist

### Before Starting
- [ ] `flutter --version` works
- [ ] `flutter doctor` shows all green
- [ ] Android device connected (for testing)
- [ ] Disk space available (>10 GB recommended)
- [ ] Network connection stable

### During Build
- [ ] Monitor console for errors
- [ ] Watch memory usage
- [ ] Don't interrupt build process
- [ ] Keep device plugged in

### After Build
- [ ] Verify APK/Bundle exists
- [ ] Check file size is reasonable
- [ ] Test on actual device
- [ ] Verify all features work

---

## 🚀 Ready? Let's Build!

### Choose Your Build Command:

**Quick Debug (Testing):**
```bash
flutter build apk
```

**Production Split (Recommended):**
```bash
flutter build apk --split-per-abi --release
```

**Play Store (Best):**
```bash
flutter build appbundle --release
```

---

## 📞 Support

If build fails:
1. Check error message above
2. Try solution from "Common Issues" section
3. Run `flutter clean` and retry
4. Check `flutter doctor` for setup issues

---

**Status:** ✅ READY TO BUILD
**Next Step:** Run one of the build commands above
**Time Estimate:** 5-10 minutes
**Expected Result:** Ready-to-test or release APK

🎉 **LET'S BUILD!** 🎉
