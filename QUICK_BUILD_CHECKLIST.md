# Quick APK Build Checklist

**Date:** November 17, 2025
**Status:** Ready for APK Build ✅

---

## 🚀 Pre-Build Checklist (5 minutes)

### Step 1: Verify Setup
- [ ] Flutter is installed and up-to-date
  ```bash
  flutter --version
  ```

- [ ] Android SDK is installed
  ```bash
  flutter doctor
  ```

- [ ] `android/app/google-services.json` exists
  ```bash
  ls android/app/google-services.json
  ```

### Step 2: Clean Environment
```bash
# Run these commands in order
flutter clean
flutter pub get
dart fix --apply
```

### Step 3: Verify No Errors
```bash
flutter analyze
```
✅ Expected: No errors or warnings related to your code

---

## 📦 Build Commands

### Option A: Debug APK (for testing)
```bash
flutter build apk
# Output: build/app/outputs/apk/debug/app-debug.apk
# Use: Testing on physical devices
# Time: ~5-10 minutes
```

### Option B: Release APK (split by ABI - recommended)
```bash
flutter build apk --split-per-abi --release
# Output: 4 APKs in build/app/outputs/apk/release/
# Use: Testing release performance
# Time: ~5-10 minutes
```

### Option C: Android App Bundle (best for Play Store)
```bash
flutter build appbundle --release
# Output: build/app/outputs/bundle/release/app-release.aab
# Use: Google Play Store distribution
# Time: ~5-10 minutes
```

---

## ✅ Expected Results

### After Running Build Command
```
✓ Flutter gradle plugin initialized
✓ Resolving dependencies...
✓ Building APK...
✓ Signing APK...
✓ Build successful!
```

### File Location
```
build/app/outputs/apk/
├── debug/
│   └── app-debug.apk
└── release/
    └── app-release.apk (or split APKs)
```

### Build Artifacts
```
APK Size: 40-60 MB (release) or 100-150 MB (debug)
Build Time: 5-15 minutes (first build) or 2-5 minutes (subsequent)
```

---

## 🧪 Test APK Before Publishing

### Install on Android Device
```bash
# Debug APK
flutter install

# Or manually:
adb install -r build/app/outputs/apk/debug/app-debug.apk
```

### Test Features
- [ ] App starts without crashing
- [ ] Authentication works
- [ ] Dashboard loads
- [ ] Can navigate between screens
- [ ] Firebase connection works
- [ ] Push notifications work (if configured)

---

## 🎯 Current Status

| Component | Status |
|-----------|--------|
| Dependencies | ✅ All 60+ compatible |
| Build Config | ✅ Correct |
| Compilation | ✅ No errors |
| Firebase | ✅ Configured |
| Manifest | ✅ Complete |
| **Overall** | **✅ READY** |

---

## 📝 Pre-Release Checklist (Before Play Store)

- [ ] Update version in pubspec.yaml
  ```yaml
  version: 1.0.0+2  # Increment build number
  ```

- [ ] Update Android version info
  ```gradle-kotlin-dsl
  versionCode = 2     # Match with pubspec.yaml
  versionName = "1.0.0"
  ```

- [ ] Create production keystore
  ```bash
  keytool -genkey -v -keystore ~/keystore.jks \
    -keyalg RSA -keysize 2048 -validity 10000 \
    -alias coopvest
  ```

- [ ] Update signing config in android/app/build.gradle.kts

- [ ] Build release APK
  ```bash
  flutter build appbundle --release
  ```

---

## ⚠️ Common Issues & Fixes

### Issue: "gradle not found"
**Fix:** Check `android/local.properties` has correct SDK path

### Issue: "google-services.json not found"
**Fix:** Download from Firebase Console and place in `android/app/`

### Issue: "Out of memory during build"
**Fix:** Increase heap in `android/gradle.properties`:
```properties
org.gradle.jvmargs=-Xmx16G -XX:MaxMetaspaceSize=4G
```

### Issue: "Signing failed"
**Fix:** Ensure keystore path is correct in build.gradle.kts

---

## 🎉 You're Ready!

**Command to run NOW:**
```bash
flutter build apk --release
```

**This will:**
1. Download any missing dependencies ✅
2. Compile Dart code ✅
3. Build Android APK ✅
4. Sign with debug key (for testing) ✅
5. Output APK file ✅

**Next:**
- Test APK on device
- Create production signing config
- Upload to Play Store (with signed APK)

---

**Status: ✅ READY FOR BUILD**
**Confidence: HIGH**
**Go ahead and build! 🚀**
