# BLE Debug Master

> 🇨🇳 [中文文档](README_CN.md)

A BLE (Bluetooth Low Energy) debugging tool built for **HarmonyOS** using ArkTS and the official `@kit.ConnectivityKit` APIs. Scan nearby BLE devices, inspect their services, characteristics, and raw advertisement payloads — all from a clean, responsive UI.

---

## Features

- **BLE Device Scanning** — Start / stop BLE scans with a single tap. Real-time device list updates as devices are discovered or updated.
- **Device Filtering** — Search devices by name with persistent keyword memory across app restarts.
- **Sorting** — Sort the device list by discovery order, name A→Z, or name Z→A.
- **Device Detail Page**
  - Connect / disconnect via GATT
  - Auto-discover GATT services and characteristics after connection
  - Display characteristic UUIDs and `properties` flags (Read / Write / Notify)
  - View raw advertisement data as formatted hex bytes
- **Responsive Layout** — Adapts to phone breakpoints (SM / MD / LG) using `BreakpointType`.
- **Error Feedback** — Inline error messages for Bluetooth-off state and scan failures.

---

## Screenshots

> *(Add screenshots here)*

---

## Project Structure

```
entry/src/main/ets/
├── pages/
│   ├── Index.ets               # Entry page — device list
│   └── Detail.ets              # Device detail page
├── view/
│   ├── BluetoothDeviceListModule.ets   # Device list UI + toolbar
│   ├── DeviceConnectionControlModule.ets
│   ├── ServiceListModule.ets
│   ├── AdvertisementDataModule.ets
│   └── ...
├── viewmodel/
│   ├── BluetoothDeviceListModuleData.ets  # Filter & sort logic
│   └── ServiceListModuleData.ets
├── bluetooth/
│   ├── BluetoothService.ets    # BLE scan & GATT implementation
│   ├── BluetoothRepository.ets # State management layer
│   └── BluetoothConstants.ets
└── util/
    └── Logger.ets
```

---

## Requirements

| Item | Requirement |
|------|-------------|
| Platform | HarmonyOS 5.0+ |
| API Level | API 12+ (BleScanner API 15+ recommended) |
| Device | Phone |
| Permissions | `ACCESS_BLUETOOTH`, `LOCATION` |

---

## Getting Started

1. Clone the repository and open it in **DevEco Studio**.
2. Connect a real HarmonyOS device (BLE scanning requires physical hardware).
3. Build and run the `entry` module.
4. Grant Bluetooth and Location permissions when prompted.
5. Tap **Start Scan** to discover nearby BLE devices.

---

## Permissions

Declared in `entry/src/main/module.json5`:

```json
"requestPermissions": [
  { "name": "ohos.permission.ACCESS_BLUETOOTH" },
  { "name": "ohos.permission.LOCATION" }
]
```

---

## Tech Stack

- **Language**: ArkTS
- **UI Framework**: ArkUI (declarative)
- **BLE API**: `@kit.ConnectivityKit` — `ble.createBleScanner()` (API 15+)
- **Build Tool**: hvigor
- **Test Framework**: `@ohos/hypium`

---

## License

```
Copyright (c) 2024 Huawei Device Co., Ltd.
Licensed under the Apache License, Version 2.0
```
