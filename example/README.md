# SecuGen Unity 20 BLE Flutter Plugin

## Description

This Flutter plugin enables communication with the **SecuGen Unity 20 BLE** device for fingerprint reading, verification, and saving fingerprint templates to an NFC card. Currently, the plugin supports only the Android platform.

## Features

- **Fingerprint Reading**: Capture fingerprints using the SecuGen Unity 20 BLE device.
- **Fingerprint Verification**: Compare a scanned fingerprint against a previously saved template.
- **Save Template to NFC**: Store the fingerprint template on a compatible NFC card.

## Requirements

- **Flutter**: Minimum version 2.0.0
- **Device**: SecuGen Unity 20 BLE
- **Platform**: Android (minimum API level 21)
- **NFC Reader**: Android device with NFC support

## Installation

Add the plugin to your Flutter project's `pubspec.yaml` file:

```yaml
dependencies:
  secugen_unity20_ble: ^1.0.0
