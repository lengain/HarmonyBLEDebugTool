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

import { ble, constant, access } from '@kit.ConnectivityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import Logger from '../util/Logger';

export interface BluetoothDevice {
  deviceId: string;
  deviceName: string;
  rssi: number;
  advertiseData?: ArrayBuffer;
}

export interface BluetoothService {
  serviceUuid: string;
  isPrimary: boolean;
  characteristics?: BluetoothCharacteristic[];
}

export interface BluetoothCharacteristic {
  characteristicUuid: string;
  serviceUuid: string;
  properties: number;
}

export class CharacteristicNotificationRegistry {
  private handlers: Map<string, (char: ble.BLECharacteristic) => void> = new Map();

  public buildKey(deviceId: string, serviceUuid: string, characteristicUuid: string): string {
    return deviceId + '|' + serviceUuid + '|' + characteristicUuid;
  }

  public set(key: string, handler: (char: ble.BLECharacteristic) => void): void {
    this.handlers.set(key, handler);
  }

  public get(key: string): ((char: ble.BLECharacteristic) => void) | undefined {
    return this.handlers.get(key);
  }

  public delete(key: string): void {
    this.handlers.delete(key);
  }

  public clearByDevice(deviceId: string): Array<(char: ble.BLECharacteristic) => void> {
    const handlersForDevice: Array<(char: ble.BLECharacteristic) => void> = [];
    const prefix: string = deviceId + '|';
    const keysToDelete: string[] = [];

    this.handlers.forEach((handler, key) => {
      if (key.startsWith(prefix)) {
        handlersForDevice.push(handler);
        keysToDelete.push(key);
      }
    });

    for (let i = 0; i < keysToDelete.length; i++) {
      this.handlers.delete(keysToDelete[i]);
    }

    return handlersForDevice;
  }

  public size(): number {
    return this.handlers.size;
  }
}

/**
 * 官方规范实现的BLE服务类
 * 遵循 HarmonyOS 官方BLE开发指南
 */
export class BluetoothServiceImpl {
  private static instance: BluetoothServiceImpl;
  private scannedDevices: Map<string, BluetoothDevice> = new Map();
  private onDeviceFoundCallback: (device: BluetoothDevice) => void = () => {};
  private onScanStateChangeCallback: (isScanning: boolean) => void = () => {};
  private onScanErrorCallback: (errorMessage: string) => void = () => {};
  private onConnectionStateChangeCallback: (deviceId: string, state: number) => void = () => {};
  private onServicesDiscoveredCallback: (deviceId: string, services: BluetoothService[]) => void = () => {};
  private onServicesDiscoverErrorCallback: (deviceId: string, message: string) => void = () => {};
  
  private bleScanner: ble.BleScanner | null = null;
  private bleDeviceFindCallback: ((scanReport: ble.ScanReport) => void) | null = null;
  private gattClients: Map<string, ble.GattClientDevice> = new Map();
  private connectionStateHandlers: Map<string, (state: ble.BLEConnectionChangeState) => void> = new Map();
  private characteristicHandlerRegistry: CharacteristicNotificationRegistry = new CharacteristicNotificationRegistry();
  private isScanning: boolean = false;
  private currentDeviceId: string = '';

  private constructor() {
  }

  public static getInstance(): BluetoothServiceImpl {
    if (!BluetoothServiceImpl.instance) {
      BluetoothServiceImpl.instance = new BluetoothServiceImpl();
    }
    return BluetoothServiceImpl.instance;
  }

  /**
   * Register callback for device found during scan
   */
  public onDeviceFound(callback: (device: BluetoothDevice) => void): void {
    this.onDeviceFoundCallback = callback;
  }

  /**
   * Register callback for scan state changes
   */
  public onScanStateChange(callback: (isScanning: boolean) => void): void {
    this.onScanStateChangeCallback = callback;
  }

  /**
   * Register callback for scan errors
   */
  public onScanError(callback: (errorMessage: string) => void): void {
    this.onScanErrorCallback = callback;
  }

  /**
   * Register callback for connection state changes
   */
  public onConnectionStateChange(callback: (deviceId: string, state: number) => void): void {
    this.onConnectionStateChangeCallback = callback;
  }

  /**
   * Register callback for services discovered
   */
  public onServicesDiscovered(callback: (deviceId: string, services: BluetoothService[]) => void): void {
    this.onServicesDiscoveredCallback = callback;
  }

  /**
   * Register callback for service discover errors
   */
  public onServicesDiscoverError(callback: (deviceId: string, message: string) => void): void {
    this.onServicesDiscoverErrorCallback = callback;
  }

  private cleanupCharacteristicHandlersForDevice(deviceId: string, gattClient: ble.GattClientDevice): void {
    const handlers: Array<(char: ble.BLECharacteristic) => void> =
      this.characteristicHandlerRegistry.clearByDevice(deviceId);
    for (let i = 0; i < handlers.length; i++) {
      try {
        gattClient.off('BLECharacteristicChange', handlers[i]);
      } catch (err) {
        Logger.warn('Remove characteristic change handler failed during cleanup');
      }
    }
  }

  /**
   * Start BLE scan - 遵循官方规范
   * 参考: https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/ble-development-guide
   */
  public async startBLEScan(): Promise<void> {
    try {
      Logger.info('Starting BLE scan - Official API');

      if (this.isScanning) {
        Logger.info('Scan already running, ignore duplicate start');
        return;
      }

      const btState: access.BluetoothState = access.getState();
      if (btState === access.BluetoothState.STATE_OFF) {
        access.enableBluetooth();
        Logger.info('Bluetooth is OFF, show enable dialog first');
        this.onScanErrorCallback('蓝牙未开启，请先开启蓝牙后重试');
        this.onScanStateChangeCallback(false);
        return;
      }
      
      // 创建BLE扫描实例 (推荐API v15+)
      this.bleScanner = ble.createBleScanner();
      
      // 步骤1: 订阅扫描结果事件 (必须先订阅)
      this.bleDeviceFindCallback = (scanReport: ble.ScanReport) => {
        scanReport.scanResult.forEach((result: ble.ScanResult) => {
          const device: BluetoothDevice = {
            deviceId: result.deviceId,
            deviceName: result.deviceName || '未知设备',
            rssi: result.rssi,
            advertiseData: result.data
          };
          this.scannedDevices.set(result.deviceId, device);
          this.onDeviceFoundCallback(device);
        });

        Logger.info('BLE scan result received: ' + scanReport.scanResult.length + ' device(s)' + '总共: ' + this.scannedDevices.size + ' 个设备');
      };

      this.bleScanner.on('BLEDeviceFind', this.bleDeviceFindCallback);

      const scanOptions: ble.ScanOptions = {
        interval: 0,
        dutyMode: ble.ScanDuty.SCAN_MODE_LOW_POWER,
        matchMode: ble.MatchMode.MATCH_MODE_AGGRESSIVE
      };

      // 当前设备环境对过滤器数组长度有校验，至少传入一个过滤器对象。
      const scanFilters: ble.ScanFilter[] = [{}];

      // 步骤2: 发起扫描
      this.bleScanner?.startScan(scanFilters, scanOptions);
      this.isScanning = true;
      this.scannedDevices.clear();
      this.onScanErrorCallback('');
      this.onScanStateChangeCallback(true);
      
    } catch (err) {
      const error = err as BusinessError;
      Logger.error('Start BLE scan error - Code: ' + error.code + ', Message: ' + error.message);
      this.onScanErrorCallback(this.getScanErrorMessage(error));
      this.isScanning = false;
      this.onScanStateChangeCallback(false);
    }
  }

  /**
   * Stop BLE scan - 遵循官方规范
   */
  public async stopBLEScan(): Promise<void> {
    try {
      Logger.info('Stopping BLE scan');
      if (this.bleScanner) {
        if (this.bleDeviceFindCallback) {
          this.bleScanner.off('BLEDeviceFind', this.bleDeviceFindCallback);
          this.bleDeviceFindCallback = null;
        }
        this.bleScanner.stopScan();
      }
      this.isScanning = false;
      this.onScanStateChangeCallback(false);
    } catch (err) {
      const error = err as BusinessError;
      Logger.error('Stop BLE scan error: ' + error.message);
      this.onScanErrorCallback('停止扫描失败: ' + error.message);
    }
  }

  private getScanErrorMessage(error: BusinessError): string {
    if (error.code === 201) {
      return '缺少蓝牙权限，请允许应用访问蓝牙';
    }
    if (error.code === 401) {
      return '扫描参数无效，请重试';
    }
    if (error.code === 801) {
      return '当前设备不支持蓝牙扫描';
    }
    if (error.code === 2900001) {
      return '蓝牙服务未就绪，请稍后重试';
    }
    return '扫描失败: ' + error.message;
  }

  /**
   * Get all scanned devices
   */
  public getScannedDevices(): BluetoothDevice[] {
    return Array.from(this.scannedDevices.values());
  }

  /**
   * Connect to device - 遵循官方规范
   * 参考: https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/gatt-development-guide
   */
  public async connectDevice(deviceId: string): Promise<void> {
    try {
      Logger.info('Connecting to device: ' + deviceId);
      this.currentDeviceId = deviceId;

      const existedClient = this.gattClients.get(deviceId);
      if (existedClient) {
        const existedConnHandler = this.connectionStateHandlers.get(deviceId);
        if (existedConnHandler) {
          existedClient.off('BLEConnectionStateChange', existedConnHandler);
          this.connectionStateHandlers.delete(deviceId);
        }
        this.cleanupCharacteristicHandlersForDevice(deviceId, existedClient);
        try {
          existedClient.disconnect();
        } catch (err) {
          Logger.warn('Disconnect stale gatt client failed before reconnect');
        }
        existedClient.close();
        this.gattClients.delete(deviceId);
      }
      
      // 步骤1: 创建GATT客户端实例
      const gattClient = ble.createGattClientDevice(deviceId);
      this.gattClients.set(deviceId, gattClient);
      
      // 步骤2: 定义连接状态变化回调
      const clientConnectStateChanged = (state: ble.BLEConnectionChangeState) => {
        const connectState = state.state;
        Logger.info('Connection state changed: ' + connectState);
        this.onConnectionStateChangeCallback(deviceId, connectState);
        
        // 状态2: 已连接 - 自动发现服务
        if (connectState === constant.ProfileConnectionState.STATE_CONNECTED) {
          this.discoverServices(deviceId, gattClient);
        }
      };
      
      // 步骤3: 订阅连接状态事件
      this.connectionStateHandlers.set(deviceId, clientConnectStateChanged);
      gattClient.on('BLEConnectionStateChange', clientConnectStateChanged);
      
      // 步骤4: 发起连接
      gattClient.connect();
      
    } catch (err) {
      const error = err as BusinessError;
      Logger.error('Connect device error - Code: ' + error.code + ', Message: ' + error.message);
      this.onConnectionStateChangeCallback(deviceId, constant.ProfileConnectionState.STATE_DISCONNECTED);
    }
  }

  /**
   * Disconnect from device - 遵循官方规范
   */
  public async disconnectDevice(deviceId: string): Promise<void> {
    try {
      Logger.info('Disconnecting from device: ' + deviceId);
      const gattClient = this.gattClients.get(deviceId);
      
      if (gattClient) {
        const connectionHandler = this.connectionStateHandlers.get(deviceId);
        if (connectionHandler) {
          gattClient.off('BLEConnectionStateChange', connectionHandler);
          this.connectionStateHandlers.delete(deviceId);
        }
        this.cleanupCharacteristicHandlersForDevice(deviceId, gattClient);
        gattClient.disconnect();
        gattClient.close();
        this.gattClients.delete(deviceId);
      }
      
      this.onConnectionStateChangeCallback(deviceId, constant.ProfileConnectionState.STATE_DISCONNECTED);
      this.currentDeviceId = '';
      
    } catch (err) {
      const error = err as BusinessError;
      Logger.error('Disconnect device error: ' + error.message);
    }
  }

  /**
   * Discover services of connected device - 遵循官方规范
   * 注意: 必须在连接成功后调用
   */
  private async discoverServices(deviceId: string, gattClient: ble.GattClientDevice): Promise<void> {
    try {
      Logger.info('Discovering services for device: ' + deviceId);
      
      // 步骤: 调用getServices() - 返回Promise
      const services = await gattClient.getServices();
      
      // 将官方API格式转换为内部格式
      const convertedServices: BluetoothService[] = [];
      for (let i = 0; i < services.length; i++) {
        const service = services[i];
        const convertedChars: BluetoothCharacteristic[] = [];

        if (service.characteristics) {
          for (let j = 0; j < service.characteristics.length; j++) {
            const char = service.characteristics[j];
            const convertedChar: BluetoothCharacteristic = {
              characteristicUuid: char.characteristicUuid,
              serviceUuid: char.serviceUuid,
              properties: Number(char.properties)
            };
            convertedChars.push(convertedChar);
          }
        }

        const convertedService: BluetoothService = {
          serviceUuid: service.serviceUuid,
          isPrimary: service.isPrimary,
          characteristics: convertedChars
        };
        convertedServices.push(convertedService);
      }
      
      Logger.info('Services discovered: ' + convertedServices.length);
      this.onServicesDiscoverErrorCallback(deviceId, '');
      this.onServicesDiscoveredCallback(deviceId, convertedServices);
      
    } catch (err) {
      const error = err as BusinessError;
      Logger.error('Discover services error - Code: ' + error.code + ', Message: ' + error.message);
      this.onServicesDiscoverErrorCallback(deviceId, '服务发现失败: ' + error.message);
    }
  }

  /**
   * Read characteristic value - 遵循官方规范
   */
  public async readCharacteristicValue(
    deviceId: string,
    serviceUuid: string,
    characteristicUuid: string
  ): Promise<ArrayBuffer> {
    try {
      const gattClient = this.gattClients.get(deviceId);
      if (!gattClient) {
        throw new Error('No connected device: ' + deviceId);
      }
      
      Logger.info('Reading characteristic: ' + characteristicUuid);
      
      // 构造特征值对象
      const characteristic: ble.BLECharacteristic = {
        serviceUuid: serviceUuid,
        characteristicUuid: characteristicUuid,
        characteristicValue: new ArrayBuffer(0),
        descriptors: []
      };
      
      // 调用官方API读取 (返回Promise)
      const result = await gattClient.readCharacteristicValue(characteristic);
      Logger.info('Characteristic value read successfully');
      return result.characteristicValue;
      
    } catch (err) {
      const error = err as BusinessError;
      Logger.error('Read characteristic error - Code: ' + error.code + ', Message: ' + error.message);
      throw new Error('Failed to read characteristic: ' + error.message);
    }
  }

  /**
   * Write characteristic value - 遵循官方规范
   */
  public async writeCharacteristicValue(
    deviceId: string,
    serviceUuid: string,
    characteristicUuid: string,
    value: ArrayBuffer
  ): Promise<void> {
    try {
      const gattClient = this.gattClients.get(deviceId);
      if (!gattClient) {
        throw new Error('No connected device: ' + deviceId);
      }
      
      Logger.info('Writing characteristic: ' + characteristicUuid);
      
      // 构造特征值对象
      const characteristic: ble.BLECharacteristic = {
        serviceUuid: serviceUuid,
        characteristicUuid: characteristicUuid,
        characteristicValue: value,
        descriptors: []
      };
      
      // 调用官方API写入 (使用回调)
      return new Promise((resolve, reject) => {
        gattClient.writeCharacteristicValue(characteristic, ble.GattWriteType.WRITE, (err: BusinessError | null) => {
          if (err) {
            Logger.error('Write characteristic error: ' + err.message);
            reject(err);
          } else {
            Logger.info('Characteristic value written successfully');
            resolve();
          }
        });
      });
      
    } catch (err) {
      const error = err as BusinessError;
      Logger.error('Write characteristic error - Code: ' + error.code + ', Message: ' + error.message);
      throw new Error('Failed to write characteristic: ' + error.message);
    }
  }

  /**
   * Subscribe to characteristic notifications - 遵循官方规范
   */
  public async subscribeCharacteristicChange(
    deviceId: string,
    serviceUuid: string,
    characteristicUuid: string,
    onChange: (value: ArrayBuffer) => void
  ): Promise<void> {
    try {
      const gattClient = this.gattClients.get(deviceId);
      if (!gattClient) {
        throw new Error('No connected device: ' + deviceId);
      }
      
      Logger.info('Subscribing to characteristic changes: ' + characteristicUuid);

      const handlerKey: string =
        this.characteristicHandlerRegistry.buildKey(deviceId, serviceUuid, characteristicUuid);
      const existedHandler = this.characteristicHandlerRegistry.get(handlerKey);
      if (existedHandler) {
        gattClient.off('BLECharacteristicChange', existedHandler);
        this.characteristicHandlerRegistry.delete(handlerKey);
      }
      
      // 步骤1: 先订阅特征值变化事件
      const onCharacteristicChange = (char: ble.BLECharacteristic) => {
        if (char.serviceUuid === serviceUuid && char.characteristicUuid === characteristicUuid) {
          Logger.info('Characteristic changed: ' + characteristicUuid);
          onChange(char.characteristicValue);
        }
      };
      
      this.characteristicHandlerRegistry.set(handlerKey, onCharacteristicChange);
      gattClient.on('BLECharacteristicChange', onCharacteristicChange);
      
      // 步骤2: 构造特征值对象
      const characteristic: ble.BLECharacteristic = {
        serviceUuid: serviceUuid,
        characteristicUuid: characteristicUuid,
        characteristicValue: new ArrayBuffer(0),
        descriptors: []
      };
      
      // 步骤3: 使能通知能力 (返回Promise或回调)
      return new Promise((resolve, reject) => {
        gattClient.setCharacteristicChangeNotification(characteristic, true, (err: BusinessError | null) => {
          if (err) {
            Logger.error('Set characteristic change notification error: ' + err.message);
            reject(err);
          } else {
            Logger.info('Successfully subscribed to characteristic changes');
            resolve();
          }
        });
      });
      
    } catch (err) {
      const error = err as BusinessError;
      Logger.error('Subscribe characteristic error - Code: ' + error.code + ', Message: ' + error.message);
      throw new Error('Failed to subscribe to characteristic: ' + error.message);
    }
  }

  /**
   * Unsubscribe from characteristic notifications - 遵循官方规范
   */
  public async unsubscribeCharacteristicChange(
    deviceId: string,
    serviceUuid: string,
    characteristicUuid: string
  ): Promise<void> {
    try {
      const gattClient = this.gattClients.get(deviceId);
      if (!gattClient) {
        throw new Error('No connected device: ' + deviceId);
      }
      
      Logger.info('Unsubscribing from characteristic changes: ' + characteristicUuid);

      const handlerKey: string =
        this.characteristicHandlerRegistry.buildKey(deviceId, serviceUuid, characteristicUuid);
      const existedHandler = this.characteristicHandlerRegistry.get(handlerKey);
      
      // 构造特征值对象
      const characteristic: ble.BLECharacteristic = {
        serviceUuid: serviceUuid,
        characteristicUuid: characteristicUuid,
        characteristicValue: new ArrayBuffer(0),
        descriptors: []
      };
      
      // 禁用通知能力
      return new Promise((resolve, reject) => {
        gattClient.setCharacteristicChangeNotification(characteristic, false, (err: BusinessError | null) => {
          if (err) {
            Logger.error('Unsubscribe characteristic error: ' + err.message);
            reject(err);
          } else {
            if (existedHandler) {
              gattClient.off('BLECharacteristicChange', existedHandler);
              this.characteristicHandlerRegistry.delete(handlerKey);
            }
            Logger.info('Successfully unsubscribed from characteristic changes');
            resolve();
          }
        });
      });
      
    } catch (err) {
      const error = err as BusinessError;
      Logger.error('Unsubscribe characteristic error - Code: ' + error.code + ', Message: ' + error.message);
      throw new Error('Failed to unsubscribe from characteristic: ' + error.message);
    }
  }

  /**
   * Check if bluetooth is enabled
   */
  public isBluetoothEnabled(): boolean {
    try {
      const state: access.BluetoothState = access.getState();
      return state === access.BluetoothState.STATE_ON || state === access.BluetoothState.STATE_BLE_ON;
    } catch (err) {
      const error = err as BusinessError;
      Logger.error('Get bluetooth state failed, code: ' + error.code + ', message: ' + error.message);
      return false;
    }
  }

  /**
   * Get connection state
   */
  public isConnected(): boolean {
    return this.currentDeviceId !== '' && this.gattClients.has(this.currentDeviceId);
  }

  /**
   * Get current connected device ID
   */
  public getCurrentDeviceId(): string {
    return this.currentDeviceId;
  }
}

export default BluetoothServiceImpl.getInstance();
