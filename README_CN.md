# BLE Debug Master

> 🇺🇸 [English](README.md)

基于 **HarmonyOS** 平台、使用 ArkTS 和官方 `@kit.ConnectivityKit` API 构建的 BLE（低功耗蓝牙）调试工具。扫描周边 BLE 设备，查看其 Service、Characteristic 和原始广播报文，界面简洁、响应式自适应。

---

## 功能特性

- **BLE 设备扫描** — 一键启动 / 停止扫描，设备列表实时更新（新发现或 RSSI 刷新）。
- **设备搜索** — 按设备名称关键词过滤，搜索词在应用重启后自动恢复。
- **排序** — 支持按发现顺序、名称 A→Z、名称 Z→A 三种方式排序。
- **设备详情页**
  - GATT 连接 / 断开
  - 连接成功后自动发现 Service 与 Characteristic
  - 显示 Characteristic UUID 及属性标志（Read / Write / Notify）
  - 以格式化十六进制展示原始广播报文
- **响应式布局** — 基于 `BreakpointType` 适配手机 SM / MD / LG 多断点。
- **错误提示** — 蓝牙未开启及扫描失败时展示内联错误信息。

---

## 截图

> *(在此处添加截图)*

---

## 项目结构

```
entry/src/main/ets/
├── pages/
│   ├── Index.ets               # 入口页 — 设备列表
│   └── Detail.ets              # 设备详情页
├── view/
│   ├── BluetoothDeviceListModule.ets   # 设备列表 UI + 工具栏
│   ├── DeviceConnectionControlModule.ets
│   ├── ServiceListModule.ets
│   ├── AdvertisementDataModule.ets
│   └── ...
├── viewmodel/
│   ├── BluetoothDeviceListModuleData.ets  # 过滤与排序逻辑
│   └── ServiceListModuleData.ets
├── bluetooth/
│   ├── BluetoothService.ets    # BLE 扫描与 GATT 实现
│   ├── BluetoothRepository.ets # 状态管理层
│   └── BluetoothConstants.ets
└── util/
    └── Logger.ets
```

---

## 环境要求

| 项目 | 要求 |
|------|------|
| 平台 | HarmonyOS 5.0+ |
| API 版本 | API 12+（推荐 BleScanner API 15+） |
| 设备类型 | 手机 |
| 权限 | `ACCESS_BLUETOOTH`、`LOCATION` |

---

## 快速开始

1. 克隆仓库，使用 **DevEco Studio** 打开。
2. 连接真机（BLE 扫描需要物理设备，模拟器不支持）。
3. 编译并运行 `entry` 模块。
4. 按提示授予蓝牙和位置权限。
5. 点击右上角 **开始扫描** 即可发现周边 BLE 设备。

---

## 权限声明

在 `entry/src/main/module.json5` 中已声明：

```json
"requestPermissions": [
  { "name": "ohos.permission.ACCESS_BLUETOOTH" },
  { "name": "ohos.permission.LOCATION" }
]
```

---

## 技术栈

- **语言**：ArkTS
- **UI 框架**：ArkUI（声明式）
- **BLE API**：`@kit.ConnectivityKit` — `ble.createBleScanner()`（API 15+）
- **构建工具**：hvigor
- **测试框架**：`@ohos/hypium`

---

## 开源许可

```
Copyright (c) 2024 Huawei Device Co., Ltd.
Licensed under the Apache License, Version 2.0
```
