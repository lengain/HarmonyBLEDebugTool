/*
* Copyright (c) 2024 Huawei Device Co., Ltd.
* Licensed under the Apache License, Version 2.0 (the "License");
* you may not use this file except in compliance with the License.
* You may obtain a copy of the License at
*
*     http://www.apache.org/licenses/LICENSE-2.0
*
* Unless required by applicable law or agreed to in writing, software
* distributed under the License is distributed on an "AS IS" BASIS,
* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
* See the License for the specific language governing permissions and
* limitations under the License.
*/

/**
 * 官方HarmonyOS蓝牙常量定义 (符合@kit.ConnectivityKit规范)
 * 参考: https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/ble-development-guide
 *       https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/gatt-development-guide
 */
export class BluetoothConstants {
  // ProfileConnectionState - 连接状态 (官方常量)
  static readonly STATE_DISCONNECTED = 0;
  static readonly STATE_CONNECTING = 1;
  static readonly STATE_CONNECTED = 2;
  static readonly STATE_DISCONNECTING = 3;

  // GattCharacteristic Properties - 特征值属性 (标准蓝牙属性位掩码)
  static readonly PROPERTY_BROADCAST = 0x01;
  static readonly PROPERTY_READ = 0x02;
  static readonly PROPERTY_WRITE = 0x04;
  static readonly PROPERTY_WRITE_NO_RESPONSE = 0x08;
  static readonly PROPERTY_NOTIFY = 0x10;
  static readonly PROPERTY_INDICATE = 0x20;
  static readonly PROPERTY_SIGNED_WRITE = 0x40;
  static readonly PROPERTY_EXTENDED_PROPS = 0x80;

  // GattWriteType - GATT写入类型 (官方定义)
  static readonly WRITE_TYPE_NO_RESPONSE = 1;
  static readonly WRITE_TYPE_DEFAULT = 2;
  static readonly WRITE_TYPE_SIGNED = 3;

  // ScanDuty - 扫描模式 (功耗等级)
  static readonly SCAN_MODE_LOW_POWER = 0;
  static readonly SCAN_MODE_BALANCED = 1;
  static readonly SCAN_MODE_HIGH_POWER = 2;

  // MatchMode - 扫描匹配模式
  static readonly MATCH_MODE_AGGRESSIVE = 1;
  static readonly MATCH_MODE_STICKY = 2;

  // 扫描参数
  static readonly SCAN_DURATION_MS = 10000;      // 扫描持续时间

  // 设备名称默认值
  static readonly DEFAULT_DEVICE_NAME = '未知设备';

  // 错误码示例 (BusinessError code)
  static readonly ERROR_DEVICE_DISCONNECTED = 2900001;
  static readonly ERROR_GATT_NOT_READY = 2900002;
  static readonly ERROR_INVALID_CHARACTERISTIC = 2900003;
  static readonly ERROR_INVALID_DESCRIPTOR = 2900004;

  // 日志标签
  static readonly LOG_TAG = '[BluetoothDebug]';
}
