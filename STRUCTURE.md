# 📁 SmartVision Project Structure

```
smart_vision/
│
├── 📱 lib/                          # Main application code
│   ├── main.dart                    # App entry point, theme, initialization
│   │
│   ├── 📊 models/                   # Data models
│   │   └── product_model.dart       # Product data structure with JSON
│   │
│   ├── 📺 screens/                  # UI screens
│   │   ├── home_screen.dart         # Main navigation screen
│   │   ├── scan_screen.dart         # Camera & capture screen
│   │   ├── result_screen.dart       # Product result display
│   │   ├── recent_scans_screen.dart # History of scans
│   │   └── settings_screen.dart     # App settings
│   │
│   └── 🔧 services/                 # Business logic & utilities
│       ├── camera_service.dart      # Camera operations
│       ├── recognition_service.dart # ML Kit integration
│       ├── tts_service.dart         # Text-to-speech
│       ├── haptic_service.dart      # Vibration feedback
│       └── storage_service.dart     # Local data persistence
│
├── 🤖 android/                      # Android platform code
│   ├── app/
│   │   ├── src/main/
│   │   │   ├── AndroidManifest.xml  # Permissions & config
│   │   │   └── kotlin/              # MainActivity
│   │   └── build.gradle             # App-level Gradle config
│   ├── build.gradle                 # Project-level Gradle config
│   ├── gradle.properties            # Gradle properties
│   └── gradle/wrapper/
│       └── gradle-wrapper.properties
│
├── 🍎 ios/                          # iOS platform code
│   └── Runner/
│       ├── Info.plist               # iOS permissions & config
│       └── AppDelegate.swift        # iOS app delegate
│
├── 🎨 assets/                       # Application assets
│   └── data/
│       └── products.json            # Sample product database
│
├── 📚 Documentation Files
│   ├── README.md                    # Main project documentation
│   ├── QUICKSTART.md               # 3-minute getting started
│   ├── SETUP_GUIDE.md              # Detailed setup & troubleshooting
│   ├── ACCESSIBILITY.md            # Accessibility documentation
│   ├── FEATURES.md                 # Complete feature list
│   └── STRUCTURE.md                # This file
│
└── ⚙️ Configuration Files
    ├── pubspec.yaml                # Dependencies & assets
    ├── analysis_options.yaml       # Linting rules
    └── .gitignore                  # Git ignore patterns
```

---

## 📱 Core Application Files

### main.dart
**Purpose**: Application entry point  
**Key Components**:
- App initialization
- TTS service setup
- Theme configuration
- Dark mode setup
- Navigation setup

**Theme Features**:
```dart
- Black background
- Yellow primary color
- High contrast text
- Large button styles
- Custom text styles
```

---

## 📊 Models Layer

### product_model.dart
**Purpose**: Product data structure  
**Fields**:
- `id`: Unique identifier
- `name`: Product name
- `description`: Product details
- `barcode`: Barcode number (optional)
- `labels`: ML Kit detected labels
- `scannedAt`: Timestamp

**Methods**:
- `toJson()`: Convert to JSON
- `fromJson()`: Parse from JSON
- `toString()`: String representation

---

## 📺 Screens Layer

### 1. home_screen.dart
**Purpose**: Main navigation hub  
**Features**:
- Welcome voice message
- Tap-anywhere help
- 3 main action buttons
- Voice guidance
- Haptic feedback

**Buttons**:
- SCAN PRODUCT (yellow, 100dp)
- RECENT SCANS (white, 80dp)
- SETTINGS (white, 80dp)

### 2. scan_screen.dart
**Purpose**: Camera capture  
**Features**:
- Camera preview
- Capture button
- Status messages
- Loading indicator
- Voice guidance
- Error handling

**Flow**:
1. Initialize camera
2. Show preview
3. Capture on tap
4. Process image
5. Navigate to results

### 3. result_screen.dart
**Purpose**: Display recognized product  
**Features**:
- Product image
- Product name (large, yellow)
- Description
- Barcode display
- Voice announcement
- Action buttons

**Buttons**:
- REPEAT (blue, voice again)
- SCAN AGAIN (yellow)
- BACK TO HOME (white)

### 4. recent_scans_screen.dart
**Purpose**: Show scan history  
**Features**:
- List of 10 recent scans
- Product cards
- Tap to hear details
- Timestamps
- Clear history
- Empty state

**Card Contents**:
- Product icon
- Product name
- Timestamp
- Description preview
- Speaker icon

### 5. settings_screen.dart
**Purpose**: App configuration  
**Features**:
- Speech rate slider
- Test voice button
- Language dropdown
- About section
- Voice feedback

**Settings**:
- Voice speed: 0.1 - 1.0
- Languages: 8 options
- Persistent storage

---

## 🔧 Services Layer

### camera_service.dart
**Type**: Singleton  
**Purpose**: Manage camera operations  
**Methods**:
- `initialize()`: Setup camera
- `takePicture()`: Capture image
- `pickImageFromGallery()`: Select from gallery
- `captureImage()`: Image picker capture
- `dispose()`: Cleanup

**Dependencies**:
- camera package
- image_picker package

### recognition_service.dart
**Type**: Singleton  
**Purpose**: ML Kit integration  
**Methods**:
- `recognizeProduct()`: Main recognition
- `_recognizeLabels()`: Image labeling
- `_recognizeText()`: OCR
- `_scanBarcode()`: Barcode scan
- `_createProduct()`: Build product object
- `dispose()`: Cleanup ML models

**Features**:
- Parallel processing
- Confidence filtering (0.6+)
- Error handling
- Offline capable

### tts_service.dart
**Type**: Singleton  
**Purpose**: Text-to-speech  
**Methods**:
- `initialize()`: Setup TTS
- `speak()`: Say text
- `stop()`: Stop speaking
- `setSpeechRate()`: Adjust speed
- `setLanguage()`: Change language
- `dispose()`: Cleanup

**Configuration**:
- Default rate: 0.5
- Default language: en-US
- Volume: 1.0
- Pitch: 1.0

### haptic_service.dart
**Type**: Singleton  
**Purpose**: Vibration feedback  
**Methods**:
- `lightImpact()`: Light vibration
- `mediumImpact()`: Medium vibration
- `heavyImpact()`: Heavy vibration
- `success()`: Success pattern
- `error()`: Error pattern

**Patterns**:
- Success: 200ms single
- Error: 3x 100ms with gaps

### storage_service.dart
**Type**: Singleton  
**Purpose**: Local data persistence  
**Methods**:
- `initialize()`: Setup storage
- `saveProduct()`: Save scan
- `getRecentScans()`: Load history
- `clearRecentScans()`: Delete all
- `setSpeechRate()`: Save rate
- `getSpeechRate()`: Load rate
- `setLanguage()`: Save language
- `getLanguage()`: Load language

**Storage Keys**:
- `recent_scans`: Product list
- `speech_rate`: Voice speed
- `language`: Selected language

**Limits**:
- Max scans: 10
- Auto-cleanup old scans

---

## 🤖 Android Configuration

### AndroidManifest.xml
**Permissions**:
- CAMERA
- READ_EXTERNAL_STORAGE
- WRITE_EXTERNAL_STORAGE
- VIBRATE
- INTERNET

**Features**:
- Camera hardware
- Camera autofocus
- Portrait orientation

### build.gradle (app)
**Configuration**:
- namespace: com.smartvision.app
- compileSdkVersion: 34
- minSdkVersion: 21
- targetSdkVersion: 34
- Kotlin support
- MultiDex enabled

### MainActivity.kt
**Purpose**: Android app entry  
**Type**: FlutterActivity extension  
**Simple**: No custom code needed

---

## 🍎 iOS Configuration

### Info.plist
**Permissions**:
- NSCameraUsageDescription
- NSPhotoLibraryUsageDescription
- NSMicrophoneUsageDescription
- NSSpeechRecognitionUsageDescription

**Configuration**:
- Bundle name: SmartVision
- Display name: SmartVision
- Supported orientations: Portrait
- Status bar: Hidden

### AppDelegate.swift
**Purpose**: iOS app entry  
**Type**: FlutterAppDelegate extension  
**Simple**: Standard Flutter setup

---

## 🎨 Assets

### products.json
**Purpose**: Sample product database  
**Format**: JSON array of products  
**Usage**: Testing and offline matching  
**Location**: `assets/data/products.json`

**Sample Products**:
- Dettol Handwash
- Colgate Toothpaste
- Coca Cola
- Lays Chips
- Nestle Maggi

---

## ⚙️ Configuration Files

### pubspec.yaml
**Purpose**: Project configuration  
**Sections**:
- App metadata (name, version)
- SDK constraints
- Dependencies (15+)
- Dev dependencies
- Assets declaration

**Key Dependencies**:
- camera, image_picker
- ML Kit (3 packages)
- flutter_tts
- vibration
- shared_preferences
- Firebase (optional)

### analysis_options.yaml
**Purpose**: Code linting  
**Rules**:
- Flutter lints package
- Custom rules
- Const preferences
- Container optimization

### .gitignore
**Purpose**: Version control  
**Ignores**:
- Build artifacts
- IDE files
- Generated files
- Platform-specific builds
- Dependencies

---

## 📚 Documentation Files

### README.md (Main)
**Sections**:
- Project overview
- Features list
- Installation guide
- Configuration
- Project structure
- Usage instructions
- Testing guide
- Contributing
- License

### QUICKSTART.md
**Purpose**: Immediate use  
**Sections**:
- 3-step setup
- First use guide
- Best practices
- Quick troubleshooting
- Pro tips

### SETUP_GUIDE.md
**Purpose**: Detailed setup  
**Sections**:
- Flutter installation
- Dependency installation
- Android setup
- iOS setup
- Testing guide
- Troubleshooting
- Performance tips
- Customization

### ACCESSIBILITY.md
**Purpose**: Accessibility docs  
**Sections**:
- Design principles
- Voice feedback system
- Haptic patterns
- Color system
- Typography
- Interaction patterns
- Testing checklist
- Best practices

### FEATURES.md
**Purpose**: Complete feature list  
**Sections**:
- All implemented features
- Technical details
- Dependencies
- Project statistics
- Testing checklist
- Success criteria

### STRUCTURE.md (This file)
**Purpose**: Project organization  
**Sections**:
- Directory tree
- File descriptions
- Layer explanations
- Configuration details
- Quick reference

---

## 🎯 File Count by Category

```
📱 Dart Files: 13
  - Main: 1
  - Models: 1
  - Screens: 5
  - Services: 5
  - Widgets: 0 (integrated in screens)

🤖 Android Files: 6
  - Manifest: 1
  - Gradle: 3
  - Kotlin: 1
  - Properties: 1

🍎 iOS Files: 2
  - Info.plist: 1
  - Swift: 1

📚 Documentation: 6
  - README: 1
  - Guides: 5

⚙️ Config Files: 3
  - pubspec.yaml: 1
  - analysis_options: 1
  - .gitignore: 1

🎨 Assets: 1
  - JSON: 1

Total: 31+ files
```

---

## 🔄 Data Flow

### Scan Process:
```
User Tap → Camera Service → Image Capture
                          ↓
                    Recognition Service
                    (Image + OCR + Barcode)
                          ↓
                    Product Model Created
                          ↓
            Storage Service (Save) + TTS (Announce)
                          ↓
                    Result Screen Display
```

### Voice Feedback:
```
User Action → Haptic Service + TTS Service
                          ↓
                Voice Announcement + Vibration
```

### Settings:
```
User Change → Storage Service (Save)
                          ↓
                TTS Service (Update) + Announce
```

---

## 🎨 Code Organization

### Naming Conventions:
- **Files**: snake_case (e.g., `home_screen.dart`)
- **Classes**: PascalCase (e.g., `HomeScreen`)
- **Variables**: camelCase (e.g., `isProcessing`)
- **Constants**: UPPER_CASE (e.g., `_MAX_SCANS`)
- **Private**: _underscore (e.g., `_ttsService`)

### Design Patterns:
- **Singleton**: All services
- **StatefulWidget**: Interactive screens
- **StatelessWidget**: Static components
- **Async/Await**: All async operations
- **Future**: Asynchronous methods

### Best Practices:
- ✅ Single Responsibility Principle
- ✅ DRY (Don't Repeat Yourself)
- ✅ Proper error handling
- ✅ Memory management (dispose)
- ✅ Null safety
- ✅ Type safety
- ✅ Clear comments

---

## 🚀 Quick Reference

### To Add a New Screen:
1. Create file in `lib/screens/`
2. Import services needed
3. Add voice announcement in `initState`
4. Add haptic feedback to buttons
5. Add navigation from home

### To Add a New Service:
1. Create file in `lib/services/`
2. Implement singleton pattern
3. Add initialization method
4. Add dispose method
5. Import in screens

### To Add a New Feature:
1. Update model if needed
2. Add service method
3. Update UI screen
4. Add voice feedback
5. Add haptic feedback
6. Update documentation

---

**🎊 Well-organized, maintainable, and scalable!**
