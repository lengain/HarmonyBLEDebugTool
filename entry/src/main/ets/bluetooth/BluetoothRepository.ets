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

import { BluetoothServiceImpl, BluetoothDevice, BluetoothService, BluetoothCharacteristic } from './BluetoothService';
import Logger from '../util/Logger';

@Observed
export class BluetoothRepository {
  private static instance: BluetoothRepository;
  private onDevicesChangedCallback: (devices: BluetoothDevice[]) => void = () => {};
  private onScanStateChangedCallback: (isScanning: boolean) => void = () => {};
  private onScanErrorChangedCallback: (errorMessage: string) => void = () => {};
  private onServicesDiscoverErrorChangedCallback: (errorMessage: string) => void = () => {};

  scannedDevices: BluetoothDevice[] = [];
  isScanning: boolean = false;
  connectedDeviceId: string = '';
  selectedDeviceId: string = '';
  selectedDeviceName: string = '';
  connectionState: number = 0; // 0: disconnected, 1: connecting, 2: connected, 3: disconnecting
  services: BluetoothService[] = [];
  selectedService: BluetoothService | null = null;
  scanErrorMessage: string = '';
  servicesDiscoverErrorMessage: string = '';

  private bluetoothService: BluetoothServiceImpl;

  private constructor() {
    this.bluetoothService = BluetoothServiceImpl.getInstance();
    this.setupCallbacks();
  }

  public static getInstance(): BluetoothRepository {
    if (!BluetoothRepository.instance) {
      BluetoothRepository.instance = new BluetoothRepository();
    }
    return BluetoothRepository.instance;
  }

  private setupCallbacks(): void {
    // Setup device found callback
    this.bluetoothService.onDeviceFound((device: BluetoothDevice) => {
      const existingIndex = this.scannedDevices.findIndex(d => d.deviceId === device.deviceId);
      if (existingIndex >= 0) {
        // Update existing device (especially RSSI/name)
        this.scannedDevices[existingIndex] = device;
        // Trigger array update by reassigning
        this.scannedDevices = [...this.scannedDevices];
      } else {
        // Add new device
        this.scannedDevices.push(device);
        this.scannedDevices = [...this.scannedDevices];
      }
      this.onDevicesChangedCallback([...this.scannedDevices]);
    });

    // Setup scan state change callback
    this.bluetoothService.onScanStateChange((isScanning: boolean) => {
      this.isScanning = isScanning;
      this.onScanStateChangedCallback(this.isScanning);
      if (!isScanning) {
        Logger.info('Scan stopped. Total devices found: ' + this.scannedDevices.length);
      }
    });

    this.bluetoothService.onScanError((errorMessage: string) => {
      this.scanErrorMessage = errorMessage;
      this.onScanErrorChangedCallback(this.scanErrorMessage);
    });

    // Setup connection state change callback
    this.bluetoothService.onConnectionStateChange((deviceId: string, state: number) => {
      this.connectedDeviceId = deviceId;
      this.connectionState = state;
      
      // Clear services when disconnected
      if (state !== 2) { // Not connected
        this.services = [];
        this.selectedService = null;
        this.servicesDiscoverErrorMessage = '';
        this.onServicesDiscoverErrorChangedCallback(this.servicesDiscoverErrorMessage);
      }
      
      Logger.info('Connection state changed to: ' + state);
    });

    // Setup services discovered callback
    this.bluetoothService.onServicesDiscovered((deviceId: string, services: BluetoothService[]) => {
      this.services = services;
      this.servicesDiscoverErrorMessage = '';
      this.onServicesDiscoverErrorChangedCallback(this.servicesDiscoverErrorMessage);
      Logger.info('Services updated. Count: ' + services.length);
    });

    this.bluetoothService.onServicesDiscoverError((deviceId: string, errorMessage: string) => {
      this.servicesDiscoverErrorMessage = errorMessage;
      this.onServicesDiscoverErrorChangedCallback(this.servicesDiscoverErrorMessage);
    });
  }

  /**
   * Start BLE scan
   */
  public startScan(): void {
    this.bluetoothService.startBLEScan();
  }

  /**
   * Stop BLE scan
   */
  public stopScan(): void {
    this.bluetoothService.stopBLEScan();
  }

  /**
   * Connect to device
   */
  public connectDevice(deviceId: string): void {
    this.selectedDeviceId = deviceId;
    this.servicesDiscoverErrorMessage = '';
    this.onServicesDiscoverErrorChangedCallback(this.servicesDiscoverErrorMessage);
    this.bluetoothService.connectDevice(deviceId);
  }

  /**
   * Reconnect to device (disconnect stale link then connect again)
   */
  public reconnectDevice(deviceId: string): void {
    if (this.connectionState === 2 || this.connectionState === 1 || this.connectionState === 3) {
      this.bluetoothService.disconnectDevice(deviceId);
    }
    this.selectedDeviceId = deviceId;
    this.servicesDiscoverErrorMessage = '';
    this.onServicesDiscoverErrorChangedCallback(this.servicesDiscoverErrorMessage);
    this.bluetoothService.connectDevice(deviceId);
  }

  /**
   * Set selected target device before entering detail page
   */
  public setTargetDevice(deviceId: string, deviceName: string): void {
    this.selectedDeviceId = deviceId;
    this.selectedDeviceName = deviceName;
  }

  /**
   * Disconnect from device
   */
  public disconnectDevice(deviceId: string): void {
    this.bluetoothService.disconnectDevice(deviceId);
  }

  /**
   * Get scanned devices
   */
  public getScannedDevices(): BluetoothDevice[] {
    return this.scannedDevices;
  }

  /**
   * Get connection state
   */
  public getConnectionState(): number {
    return this.connectionState;
  }

  /**
   * Get connected device ID
   */
  public getConnectedDeviceId(): string {
    return this.connectedDeviceId;
  }

  /**
   * Get device id used for detail display
   */
  public getDisplayDeviceId(): string {
    if (this.connectedDeviceId.length > 0) {
      return this.connectedDeviceId;
    }
    return this.selectedDeviceId;
  }

  /**
   * Get device name used for detail display
   */
  public getDisplayDeviceName(): string {
    if (this.selectedDeviceName.length > 0) {
      return this.selectedDeviceName;
    }
    const displayId: string = this.getDisplayDeviceId();
    const matchedDevice = this.scannedDevices.find((d: BluetoothDevice) => d.deviceId === displayId);
    if (matchedDevice) {
      return matchedDevice.deviceName;
    }
    return '未知设备';
  }

  /**
   * Get services of connected device
   */
  public getServices(): BluetoothService[] {
    return this.services;
  }

  /**
   * Get characteristics of selected service
   */
  public getCharacteristics(): BluetoothCharacteristic[] {
    return this.selectedService?.characteristics ?? [];
  }

  /**
   * Select service to show characteristics
   */
  public selectService(service: BluetoothService): void {
    this.selectedService = service;
  }

  /**
   * Read characteristic value
   */
  public async readCharacteristic(serviceUUID: string, characteristicUUID: string): Promise<ArrayBuffer> {
    return this.bluetoothService.readCharacteristicValue(this.connectedDeviceId, serviceUUID, characteristicUUID);
  }

  /**
   * Write characteristic value
   */
  public async writeCharacteristic(
    serviceUUID: string,
    characteristicUUID: string,
    value: ArrayBuffer
  ): Promise<void> {
    return this.bluetoothService.writeCharacteristicValue(this.connectedDeviceId, serviceUUID, characteristicUUID, value);
  }

  /**
   * Subscribe to characteristic notifications
   */
  public async subscribeCharacteristic(
    serviceUUID: string,
    characteristicUUID: string,
    onChange: (value: ArrayBuffer) => void
  ): Promise<void> {
    return this.bluetoothService.subscribeCharacteristicChange(this.connectedDeviceId, serviceUUID, characteristicUUID, onChange);
  }

  /**
   * Unsubscribe from characteristic notifications
   */
  public async unsubscribeCharacteristic(
    serviceUUID: string,
    characteristicUUID: string
  ): Promise<void> {
    return this.bluetoothService.unsubscribeCharacteristicChange(this.connectedDeviceId, serviceUUID, characteristicUUID);
  }

  /**
   * Get advertisement data (raw bytes) for the currently selected/connected device
   */
  public getAdvertiseData(): ArrayBuffer | undefined {
    const displayId = this.getDisplayDeviceId();
    const device = this.scannedDevices.find((d: BluetoothDevice) => d.deviceId === displayId);
    return device?.advertiseData;
  }

  /**
   * Check if scanning
   */
  public getIsScanning(): boolean {
    return this.isScanning;
  }

  /**
   * Check if connected
   */
  public getIsConnected(): boolean {
    return this.connectionState === 2;
  }

  /**
   * Listen for scanned device list updates
   */
  public onDevicesChanged(callback: (devices: BluetoothDevice[]) => void): void {
    this.onDevicesChangedCallback = callback;
  }

  /**
   * Listen for scan state updates
   */
  public onScanStateChanged(callback: (isScanning: boolean) => void): void {
    this.onScanStateChangedCallback = callback;
  }

  /**
   * Listen for scan error updates
   */
  public onScanErrorChanged(callback: (errorMessage: string) => void): void {
    this.onScanErrorChangedCallback = callback;
  }

  /**
   * Get latest scan error message
   */
  public getScanErrorMessage(): string {
    return this.scanErrorMessage;
  }

  /**
   * Listen for service discover error updates
   */
  public onServicesDiscoverErrorChanged(callback: (errorMessage: string) => void): void {
    this.onServicesDiscoverErrorChangedCallback = callback;
  }

  /**
   * Get latest service discover error message
   */
  public getServicesDiscoverErrorMessage(): string {
    return this.servicesDiscoverErrorMessage;
  }
}

export default BluetoothRepository.getInstance();
