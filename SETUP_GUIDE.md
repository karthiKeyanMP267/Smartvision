# SmartVision Setup Guide

## Quick Start

### 1. Install Flutter
If you haven't already, install Flutter SDK:
- Windows: https://docs.flutter.dev/get-started/install/windows
- macOS: https://docs.flutter.dev/get-started/install/macos
- Linux: https://docs.flutter.dev/get-started/install/linux

Verify installation:
```bash
flutter doctor
```

### 2. Install Dependencies
Navigate to the project directory and run:
```bash
cd smart_vision
flutter pub get
```

### 3. Run the App

#### For Android:
```bash
# Connect Android device or start emulator
flutter devices

# Run the app
flutter run
```

#### For iOS (macOS only):
```bash
# Install CocoaPods dependencies
cd ios
pod install
cd ..

# Run the app
flutter run -d ios
```

## Configuration

### Android Setup

1. **Minimum Requirements:**
   - Android SDK 21 (Lollipop) or higher
   - Android Studio with SDK tools
   - USB Debugging enabled on device

2. **Permissions:**
   All required permissions are already configured in `AndroidManifest.xml`:
   - Camera
   - Storage (Read/Write)
   - Vibration
   - Internet

3. **Build Release APK:**
   ```bash
   flutter build apk --release
   ```
   APK location: `build/app/outputs/flutter-apk/app-release.apk`

### iOS Setup

1. **Minimum Requirements:**
   - iOS 12.0 or higher
   - Xcode 14.0 or higher
   - CocoaPods installed

2. **Permissions:**
   All required permissions are configured in `Info.plist`:
   - Camera Usage Description
   - Photo Library Usage Description
   - Speech Recognition Usage Description

3. **Build for iOS:**
   ```bash
   flutter build ios --release
   ```

## Testing the App

### Test Features:

1. **Home Screen:**
   - Tap anywhere to hear instructions
   - Tap "SCAN PRODUCT" button - should hear voice feedback
   - Check haptic feedback on button taps

2. **Scan Screen:**
   - Camera should open
   - Tap "CAPTURE" to take a photo
   - Should see processing indicator
   - Voice should announce "Hold steady..."

3. **Result Screen:**
   - Product name should display in yellow box
   - Voice should read product details
   - Tap "REPEAT" to hear again
   - Check haptic feedback

4. **Recent Scans:**
   - Should show previously scanned products
   - Tap any product to hear details
   - Test "Clear History" button

5. **Settings:**
   - Adjust speech rate slider
   - Tap "TEST VOICE" to hear sample
   - Change language from dropdown
   - All changes should have voice feedback

## Troubleshooting

### Common Issues:

#### 1. "Camera not initialized"
**Solution:** Ensure camera permissions are granted in device settings.

```bash
# Android: Settings > Apps > SmartVision > Permissions > Camera (ON)
# iOS: Settings > SmartVision > Camera (ON)
```

#### 2. "No suitable JDK found"
**Solution:** Install JDK 11 or higher and set JAVA_HOME environment variable.

#### 3. ML Kit not working
**Solution:** Ensure Google Play Services are up to date (Android) or iOS version is 12+.

#### 4. TTS not speaking
**Solution:** 
- Check device volume
- Verify TTS engine is installed (Android: Google Text-to-Speech)
- iOS: Check Accessibility > Spoken Content settings

#### 5. Build fails with Gradle errors
**Solution:**
```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
flutter run
```

### Debug Mode:

Run in debug mode to see console logs:
```bash
flutter run --verbose
```

Check for errors in console output related to:
- Camera initialization
- ML Kit model loading
- TTS initialization
- Permission denials

## Performance Optimization

### Release Build:
Always test performance in release mode:
```bash
flutter run --release
```

### Reduce APK Size:
```bash
flutter build apk --split-per-abi
```
This creates separate APKs for different CPU architectures.

## Customization

### Change App Colors:
Edit `lib/main.dart` in the theme section:
```dart
colorScheme: const ColorScheme.dark(
  primary: Colors.yellow,  // Change this
  secondary: Colors.yellow,  // And this
),
```

### Change Voice Speed Default:
Edit `lib/services/tts_service.dart`:
```dart
await _flutterTts.setSpeechRate(0.5); // Change 0.5 to your preferred speed
```

### Add More Languages:
Edit `lib/screens/settings_screen.dart` in the `_languages` map:
```dart
final Map<String, String> _languages = {
  'en-US': 'English (US)',
  // Add more languages here
  'ja-JP': 'Japanese',
};
```

## Testing with Real Products

### Test Products:
1. Any product with clear brand name
2. Products with barcodes
3. Products with text labels
4. Products in different lighting conditions

### Best Results:
- Good lighting
- Hold phone steady (6-12 inches from product)
- Ensure product label is facing camera
- Avoid glare and shadows

## Production Deployment

### Android:
1. Generate signing key
2. Configure signing in `android/app/build.gradle`
3. Build release APK
4. Upload to Google Play Store

### iOS:
1. Configure provisioning profiles in Xcode
2. Set up App Store Connect
3. Build archive in Xcode
4. Submit for review

## Support & Resources

- Flutter Documentation: https://flutter.dev/docs
- ML Kit Documentation: https://developers.google.com/ml-kit
- Flutter TTS: https://pub.dev/packages/flutter_tts
- Camera Plugin: https://pub.dev/packages/camera

## Updates & Maintenance

### Update Dependencies:
```bash
flutter pub upgrade
```

### Check for Issues:
```bash
flutter analyze
```

### Run Tests:
```bash
flutter test
```

## License

This project is open-source. Feel free to modify and distribute.

---

**Need help? Contact: support@smartvision.app**
