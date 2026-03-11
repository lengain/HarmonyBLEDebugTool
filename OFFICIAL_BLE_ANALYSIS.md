# 鸿蒙官方 BLE 规范分析报告（与当前工程对齐）

**更新时间**: 2026年3月11日  
**参考文档**:
1. https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/ble-development-guide
2. https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/gatt-development-guide

---

## 一、结论摘要

当前工程已经完成从“模拟 BLE”到“官方 API 实现”的迁移，扫描、连接、服务发现、特征值读写与通知订阅都已落地。

当前状态可概括为：
- 规范主流程：已实现。
- 错误映射与状态回传：已实现。
- 事件解绑完整性与订阅生命周期管理：仍有优化空间。

---

## 二、当前代码实现（按流程）

### 1. BLE 扫描流程

工程实现要点（`BluetoothService.ets`）：
- 使用 `ble.createBleScanner()` 创建扫描器。
- 启动扫描前先 `on('BLEDeviceFind', callback)` 订阅事件。
- 使用 `ScanOptions` 发起扫描：`interval: 0`、`SCAN_MODE_LOW_POWER`、`MATCH_MODE_AGGRESSIVE`。
- 扫描过滤器使用 `scanFilters: [{}]`（兼容当前设备环境对过滤器长度的校验）。
- 蓝牙关闭时通过 `access.getState()` 判断并调用 `access.enableBluetooth()`，同时向 UI 回传提示。
- 扫描错误按 `BusinessError.code` 转换为可读文案（201/401/801/2900001）。
- 停止扫描时会执行 `off('BLEDeviceFind', callback)` 后再 `stopScan()`。

结论：扫描链路与官方推荐顺序一致。

### 2. GATT 连接与服务发现

工程实现要点（`BluetoothService.ets`）：
- 使用 `ble.createGattClientDevice(deviceId)` 创建客户端。
- 连接前会处理旧客户端（`disconnect + close + delete`），避免脏连接。
- 订阅 `BLEConnectionStateChange` 后调用 `connect()`。
- 收到 `STATE_CONNECTED` 后触发 `discoverServices()`。
- `discoverServices()` 内使用 `await gattClient.getServices()` 获取真实服务，并转换为工程内的 `BluetoothService/BluetoothCharacteristic` 结构。

结论：连接与服务发现流程与官方规范一致。

### 3. 特征值读写与通知

工程实现要点（`BluetoothService.ets`）：
- 读：`readCharacteristicValue()`，使用 Promise 返回 `ArrayBuffer`。
- 写：`writeCharacteristicValue(..., ble.GattWriteType.WRITE, callback)`，封装为 Promise。
- 订阅通知：先 `on('BLECharacteristicChange', handler)`，再 `setCharacteristicChangeNotification(..., true, callback)`。
- 取消订阅：调用 `setCharacteristicChangeNotification(..., false, callback)`。
- 构造 `ble.BLECharacteristic` 时补齐 `descriptors: []`，符合 ArkTS 严格类型要求。

结论：读写与通知主路径已具备实用能力。

### 4. Repository 与 UI 状态衔接

工程实现要点（`BluetoothRepository.ets`）：
- 维护扫描设备、连接状态、服务列表、错误信息等状态。
- 扫描结果按 `deviceId` 去重更新，保证 RSSI/名称刷新。
- 连接状态非 `2`（已连接）时清空 `services` 与 `selectedService`，避免展示旧数据。
- 暴露 `read/write/subscribe/unsubscribe` 给上层模块调用。

结论：状态管理层结构清晰，能支撑当前 UI。

---

## 三、与官方规范对齐度评估

### ✅ 已对齐

- [x] 使用官方 ConnectivityKit BLE/GATT API（非模拟实现）
- [x] 扫描事件订阅顺序正确（先订阅后扫描）
- [x] 连接成功后触发服务发现
- [x] 读写特征值能力已打通
- [x] 特征值通知订阅/取消订阅能力已打通
- [x] `BusinessError` 有明确日志与部分错误码映射


## 四、API 兼容性说明（保留）

| 特性 | API v11 | API v14 | API v15 | 推荐 |
|------|---------|---------|---------|------|
| BleScanner 多路扫描 | ❌ | ❌ | ✅ | v15+ |
| ble.startBLEScan() 单路 | ❌ | ✅ | ✅ | 向后兼容 |
| GATT 连接 | ✅ | ✅ | ✅ | 全版本 |
| 特征值通知 | ✅ | ✅ | ✅ | 全版本 |

