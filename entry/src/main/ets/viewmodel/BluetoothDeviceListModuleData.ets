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
import LazyDataSource from '../util/LazyDataSource';
import { BluetoothRepository } from '../bluetooth/BluetoothRepository';
import { BluetoothDevice } from '../bluetooth/BluetoothService';
import Logger from '../util/Logger';

export class BluetoothDeviceSortMode {
  static readonly DISCOVERY: string = 'discovery';
  static readonly NAME_ASC: string = 'name_asc';
  static readonly NAME_DESC: string = 'name_desc';
}

@Observed
export class Data {
  private static instance: Data;
  lazyDataSource: LazyDataSource<DataSource> = new LazyDataSource();
  private repository: BluetoothRepository = BluetoothRepository.getInstance();
  private filterKeyword: string = '';
  private sortMode: string = BluetoothDeviceSortMode.DISCOVERY;

  constructor() {
  }

  public static getInstance(): Data {
    if (!Data.instance) {
      Data.instance = new Data();
    }
    return Data.instance;
  }

  /**
   * Get bluetooth devices from repository
   */
  getResources(): Promise<void> {
    return new Promise((resolve: Function) => {
      try {
        const devices = this.getFilteredAndSortedDevices();
        
        // Clear existing data and rebuild the list
        this.lazyDataSource.clear();
        
        devices.forEach((device: BluetoothDevice): void => {
          const dataSource = new DataSource(
            $r('app.media.realImageGen_common_3'),
            device.deviceName,
            device.rssi + 'dBm',
            '设备ID: ' + device.deviceId,
            ['连接'],
            [Color.Brown]
          );
          dataSource.setDeviceId(device.deviceId);
          this.lazyDataSource.pushData(dataSource);
        });
        
        Logger.info('Device list updated: ' + devices.length);
        resolve();
      } catch (err) {
        Logger.error('Get resources error: ' + JSON.stringify(err));
        resolve();
      }
    });
  }

  /**
   * Start BLE scan
   */
  public startScan(): void {
    Logger.info('Starting scan from ViewModel');
    const repo = BluetoothRepository.getInstance();
    repo.startScan();
  }

  /**
   * Stop BLE scan
   */
  public stopScan(): void {
    Logger.info('Stopping scan from ViewModel');
    const repo = BluetoothRepository.getInstance();
    repo.stopScan();
  }

  /**
   * Get scanning status
   */
  public isScanning(): boolean {
    const repo = BluetoothRepository.getInstance();
    return repo.getIsScanning();
  }

  /**
   * Connect to device
   */
  public connectDevice(deviceId: string): void {
    Logger.info('Connecting to device from ViewModel: ' + deviceId);
    const repo = BluetoothRepository.getInstance();
    repo.connectDevice(deviceId);
  }

  /**
   * Get scanned devices
   */
  public getScannedDevices(): BluetoothDevice[] {
    const repo = BluetoothRepository.getInstance();
    return repo.getScannedDevices();
  }

  public getRawScannedDeviceCount(): number {
    return this.getScannedDevices().length;
  }

  public setFilterKeyword(keyword: string): void {
    this.filterKeyword = keyword.trim();
  }

  public getFilterKeyword(): string {
    return this.filterKeyword;
  }

  public setSortMode(sortMode: string): void {
    this.sortMode = sortMode;
  }

  public getSortMode(): string {
    return this.sortMode;
  }

  public getFilteredAndSortedDevices(): BluetoothDevice[] {
    return this.getProcessedDevices(this.repository.getScannedDevices());
  }

  public getProcessedDevices(devices: BluetoothDevice[]): BluetoothDevice[] {
    const filteredDevices: BluetoothDevice[] = [];
    const normalizedKeyword: string = this.filterKeyword.toLowerCase();

    for (let index = 0; index < devices.length; index++) {
      const device: BluetoothDevice = devices[index];
      const normalizedName: string = this.normalizeDeviceName(device.deviceName).toLowerCase();
      const matchesKeyword: boolean = normalizedKeyword.length === 0 || normalizedName.indexOf(normalizedKeyword) >= 0;
      if (matchesKeyword) {
        filteredDevices.push(device);
      }
    }

    return this.sortDevices(filteredDevices);
  }

  /**
   * Get latest scan error message
   */
  public getScanErrorMessage(): string {
    const repo = BluetoothRepository.getInstance();
    return repo.getScanErrorMessage();
  }

  private sortDevices(devices: BluetoothDevice[]): BluetoothDevice[] {
    const sortedDevices: BluetoothDevice[] = [];
    for (let index = 0; index < devices.length; index++) {
      sortedDevices.push(devices[index]);
    }

    if (this.sortMode === BluetoothDeviceSortMode.DISCOVERY) {
      return sortedDevices;
    }

    sortedDevices.sort((first: BluetoothDevice, second: BluetoothDevice): number => {
      const firstName: string = this.normalizeDeviceName(first.deviceName).toLowerCase();
      const secondName: string = this.normalizeDeviceName(second.deviceName).toLowerCase();

      if (firstName === secondName) {
        return 0;
      }

      if (this.sortMode === BluetoothDeviceSortMode.NAME_DESC) {
        return firstName > secondName ? -1 : 1;
      }

      return firstName > secondName ? 1 : -1;
    });

    return sortedDevices;
  }

  private normalizeDeviceName(deviceName: string): string {
    if (deviceName.length === 0) {
      return '未知设备';
    }
    return deviceName;
  }
}

export class DataSource {
  private image: Resource;
  private mainText: string;
  private subText: string;
  private descriptionText: string;
  private tagTextList: string[];
  private tagTextColorList: Color[];
  private deviceId: string = '';

  constructor(image: Resource, mainText: string, subText: string,
    descriptionText: string, tagTextList: string[], tagTextColorList: Color[]) {
    this.image = image;
    this.mainText = mainText;
    this.subText = subText;
    this.descriptionText = descriptionText;
    this.tagTextList = tagTextList;
    this.tagTextColorList = tagTextColorList;
  }

  getImage(): Resource {
    return this.image;
  }

  getMainText(): string {
    return this.mainText;
  }

  getSubText(): string {
    return this.subText;
  }

  getDescriptionText(): string {
    return this.descriptionText;
  }

  getTagTextList(): string[] {
    return this.tagTextList;
  }

  getTagTextColorList(): Color[] {
    return this.tagTextColorList;
  }

  getDeviceId(): string {
    return this.deviceId;
  }

  setDeviceId(deviceId: string): void {
    this.deviceId = deviceId;
  }
}