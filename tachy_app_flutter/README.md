# Tachy App (Flutter)

A cross-platform mobile application for real-time PPG (Photoplethysmography) monitoring via Bluetooth Low Energy. Connects to an **Arduino Nano PPG** device to display voltage waveforms, detect peaks, and estimate heart rate (BPM).

Part of the [e-NABLE](https://www.enablingthefuture.org/) project for assistive devices and physiological monitoring.

---

## Features

- **BLE Connectivity** — Scan and connect to Arduino Nano PPG device by name (`NanoPPG`)
- **Real-time Voltage Graph** — Live plot of PPG voltage over the last 5 seconds
- **Peak Detection** — Counts voltage peaks above 2.8 V with debouncing (0.3 s minimum interval)
- **BPM Calculation** — Heart rate estimate from average interval between last 10 peaks
- **Cross-Platform** — Android, iOS, and Web (BLE behavior varies by platform)

---

## Project Structure

```
tachy_app_flutter/
├── lib/
│   ├── main.dart                 # App entry point, Provider setup
│   ├── providers/
│   │   └── ppg_provider.dart     # State management, signal processing
│   ├── screens/
│   │   └── home_screen.dart      # Main UI
│   ├── services/
│   │   └── bluetooth_service.dart # BLE scanning, connection, data handling
│   └── widgets/
│       └── voltage_graph.dart    # Voltage line chart (fl_chart)
├── android/                      # Android platform config
├── ios/                          # iOS platform config
├── web/                          # Web platform config
├── pubspec.yaml
└── README.md
```

---

## Requirements

- **Flutter** 3.11+ ([Install Flutter](https://docs.flutter.dev/get-started/install))
- **Android Studio** (for Android SDK and emulator)
- **Arduino Nano PPG** device (hardware; for full functionality)

---

## Setup

### 1. Clone the repository

```bash
git clone https://github.com/e-nable-tachycardia/tachy-app-swift.git
cd tachy-app-swift
```

### 2. Install dependencies

```bash
cd tachy_app_flutter
flutter pub get
```

### 3. Run on a device

**Android (emulator or physical device):**

```bash
flutter run -d android
```

Or select the Android device when prompted:

```bash
flutter run
```

**iOS (requires macOS):**

```bash
flutter run -d ios
```

**Web:**

```bash
flutter run -d chrome
```

> **Note:** BLE behavior differs on web. Use Android or iOS for best results with the NanoPPG.

---

## BLE Configuration

The app expects the Arduino Nano PPG to use:

| Parameter | Value |
|-----------|-------|
| **Device name** | `NanoPPG` |
| **Service UUID** | `12345678-1234-5678-1234-56789abcdef0` |
| **Characteristic UUID** | `12345678-1234-5678-1234-56789abcdef1` |
| **Data format** | 4-byte little-endian `float` |

---

## Signal Processing

- **Peak threshold:** 2.8 V  
- **Min peak interval:** 0.3 s (debouncing)  
- **History window:** 5 seconds  
- **Max history points:** 500  
- **Peaks used for BPM:** last 10  

---

## Dependencies

| Package | Purpose |
|---------|---------|
| `flutter_blue_plus` | BLE scanning, connection, characteristic notifications |
| `fl_chart` | Voltage line chart |
| `provider` | State management |
| `permission_handler` | Runtime permissions (Android 12+) |

---

## Permissions

### Android

Declared in `android/app/src/main/AndroidManifest.xml`:

- `BLUETOOTH` / `BLUETOOTH_ADMIN`
- `BLUETOOTH_SCAN` / `BLUETOOTH_CONNECT` (Android 12+)
- `ACCESS_FINE_LOCATION`

### iOS

Declared in `ios/Runner/Info.plist`:

- `NSBluetoothAlwaysUsageDescription`
- `NSBluetoothPeripheralUsageDescription`

---

## Running from Android Studio

1. Open the **`tachy_app_flutter`** folder in Android Studio (not the parent `e-NABLE` folder).
2. Ensure the **Flutter** plugin is installed.
3. Start an Android emulator (AVD Manager).
4. Use **Run** or `Shift+F10` — Flutter will detect the emulator and run the app.

If you see "Not applicable for main.dart", add a Flutter configuration:

- **Run → Edit Configurations**
- **+ → Flutter**
- Set Dart entrypoint to `lib/main.dart`
- Save

---

## Building Release APK

```bash
flutter build apk --release
```

Output: `build/app/outputs/flutter-apk/app-release.apk`

---

## Related

- **Original iOS app:** `tachy-app/` (Swift, Xcode) — reference implementation
- **Arduino firmware:** See e-NABLE documentation for Nano PPG Arduino code

---

## License

See repository license file.
