# OCR Expense Tracker & Receipt Parser

A Flutter expense-tracking app that turns receipt photos into editable transactions. It uses on-device OCR on native platforms, stores transaction data locally in SQLite, and summarizes spending with custom charts.

**Author:** Phan Đình Thắng · **Student ID:** 23IT.B207
**Repository:** [pdthang125/Project3](https://github.com/pdthang125/Project3)

## Overview

The app helps users capture a receipt, review the recognized information, and save the transaction for later reference. Receipt text is processed on the device; transaction records and image thumbnails are stored locally.

### Features

- Capture a receipt with the camera or choose an image from the gallery.
- Run Google ML Kit text recognition on Android and iOS.
- Extract a likely total, date, and merchant name with receipt-specific parsing rules.
- Review and edit recognized fields before saving.
- Store transactions and compressed thumbnails in SQLite and app storage.
- Create, view, edit, filter, and delete transaction records.
- View category totals and weekly spending trends with charts drawn using Flutter `CustomPainter`.
- Manage UI state with Riverpod.

## Platform support

| Platform | Support |
|---|---|
| Android | Native camera and on-device OCR. The Android builds use the native camera and on-device OCR, subject to the installed plugin requirements. |
| iOS | Native camera and on-device OCR, subject to the platform requirements of the installed Flutter plugins. |
| Web | UI/debug fallback only. OCR is unavailable in the browser implementation. |

## Technology stack

- Flutter 3.x and Dart 3
- Riverpod 2.x for state management
- Google ML Kit Text Recognition for native OCR
- SQLite with `sqflite` for local persistence
- `camera`, `image_picker`, and `image_cropper` for receipt images
- `flutter_image_compress` for thumbnail generation
- `CustomPainter` for donut and bar charts

## Architecture

The code is organized by responsibility:

```text
lib/
├── core/
│   ├── constants/       # App constants and category colors
│   ├── theme/           # Material theme and design tokens
│   └── utils/           # Receipt parser and formatters
├── data/
│   ├── datasources/     # SQLite operations
│   ├── models/          # Transaction model
│   └── repositories/    # Transaction data coordination
├── services/
│   ├── database/        # Platform-specific database initialization
│   └── ocr/             # Native OCR and web fallback
└── presentation/
    ├── providers/       # Riverpod providers
    ├── screens/         # Dashboard, camera, review, and history
    └── widgets/         # Receipt image and chart widgets
```

### Receipt processing flow

```text
Camera or gallery image
        ↓
On-device text recognition (Android/iOS)
        ↓
ReceiptParser extracts candidate fields
        ↓
Review screen lets the user correct the result
        ↓
Repository saves the transaction and thumbnail
        ↓
SQLite data refreshes the dashboard and history
```

## Receipt parsing

`ReceiptParser` in `lib/core/utils/receipt_parser.dart` uses heuristics to handle common receipt layouts:

- It prioritizes lines containing total-related terms such as “tổng cộng”, “thanh toán”, “phải trả”, or “total”.
- It excludes lines likely to contain subtotals, tax, discounts, change, phone numbers, or invoice identifiers.
- If no total-labeled line is usable, it looks for the largest plausible amount on a remaining line.
- It recognizes common day/month/year and year/month/day date forms, including `/`, `-`, and `.` separators, plus Vietnamese long-form dates.
- The review screen is the final check; OCR and parsing results can require correction for blurred, tilted, or unusual receipts.

The parser is heuristic-based. It does not provide a machine-learning confidence score, and the amount/date result should be reviewed before saving.

## Data and privacy

Transactions are stored locally in SQLite. The record includes the amount, date, merchant, category, thumbnail path, and raw OCR text. Receipt images are not sent to a backend by this project. Deleting a transaction also removes its stored thumbnail.

## Getting started

### Requirements

- Flutter SDK 3.x and Dart 3
- Android Studio or VS Code with the Flutter extension
- An Android device/emulator, or Xcode and an iOS device/simulator for iOS builds

### Install and run

```bash
git clone https://github.com/pdthang125/Project3.git
cd Project3
flutter pub get
flutter run
```

For a browser UI preview, use `flutter run -d chrome`. The web fallback does not perform OCR.

## Build Android

Build a debug APK:

```bash
flutter build apk --debug
```

Build a release APK:

```bash
flutter build apk --release
```

Build separate APKs for supported CPU architectures:

```bash
flutter build apk --split-per-abi --release
```

The current Android Gradle configuration uses the debug signing key for release builds. Before distributing an APK, configure a release keystore and keep the keystore and signing passwords out of version control.

## Troubleshooting

| Issue | Suggested check |
|---|---|
| Camera preview does not start | Grant camera permission and confirm that the device has a working camera. |
| OCR returns little or no text | Use a sharp, well-lit image with the receipt fully in frame and minimal glare. |
| Android build fails after dependency changes | Run `flutter clean`, then `flutter pub get`, and build again. |
| OCR is unavailable in a browser | This is expected; the web implementation is for UI/debugging and uses a native-only OCR plugin on Android/iOS. |

## Project details

- **Application package:** `expense_tracker` (Dart package name)
- **Application ID:** `com.example.expense_tracker` (Android; update before public release)
- **Version:** `1.0.0+1`
- **Author:** Phan Đình Thắng · 23IT.B207
