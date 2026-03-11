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
import { BluetoothConstants } from '../bluetooth/BluetoothConstants';
import Logger from '../util/Logger';

@Observed
export class Data {
  private static instance: Data;
  lazyDataSource: LazyDataSource<DataSource> = new LazyDataSource();
  connectionState: number = BluetoothConstants.STATE_DISCONNECTED;
  connectedDeviceId: string = '';
  displayDeviceName: string = '未知设备';

  constructor() {
  }

  public static getInstance(): Data {
    if (!Data.instance) {
      Data.instance = new Data();
    }
    return Data.instance;
  }

  /**
   * Get connection control data
   */
  getResources(): Promise<void> {
    return new Promise((resolve: Function): void => {
      try {
        const repo = BluetoothRepository.getInstance();
        this.connectionState = repo.getConnectionState();
        this.connectedDeviceId = repo.getDisplayDeviceId();
        this.displayDeviceName = repo.getDisplayDeviceName();
        
        const modelList: Array<DataSource> = [];
        const stateText = this.getConnectionStateText();
        const stateColor = this.getConnectionStateColor();
        
        modelList.push(new DataSource(
          $r('app.media.lib_icon_166'),
          this.displayDeviceName,
          stateText,
          stateColor,
          this.connectedDeviceId
        ));
        
        this.lazyDataSource.pushArrayData(modelList);
        Logger.info('Connection state updated: ' + stateText);
        resolve();
      } catch (err) {
        if (err instanceof Error) {
          Logger.error('Get connection resources error: ' + err.message);
        }
        resolve();
      }
    });
  }

  /**
   * Toggle connection
   */
  public toggleConnection(deviceId: string): void {
    const repo = BluetoothRepository.getInstance();
    const targetDeviceId: string = deviceId.length > 0 ? deviceId : repo.getDisplayDeviceId();
    if (targetDeviceId.length === 0) {
      Logger.warn('No target device selected, ignore toggle connection action');
      return;
    }
    if (this.connectionState === BluetoothConstants.STATE_CONNECTED) {
      Logger.info('Disconnecting from device: ' + targetDeviceId);
      repo.disconnectDevice(targetDeviceId);
    } else if (this.connectionState === BluetoothConstants.STATE_DISCONNECTED) {
      Logger.info('Connecting to device: ' + targetDeviceId);
      repo.connectDevice(targetDeviceId);
    }
  }

  /**
   * Get connection state display text
   */
  private getConnectionStateText(): string {
    switch (this.connectionState) {
      case BluetoothConstants.STATE_DISCONNECTED:
        return '未连接';
      case BluetoothConstants.STATE_CONNECTING:
        return '连接中...';
      case BluetoothConstants.STATE_CONNECTED:
        return '已连接';
      case BluetoothConstants.STATE_DISCONNECTING:
        return '断开中...';
      default:
        return '未知状态';
    }
  }

  /**
   * Get connection state color
   */
  private getConnectionStateColor(): Color {
    switch (this.connectionState) {
      case BluetoothConstants.STATE_CONNECTED:
        return Color.Green;
      case BluetoothConstants.STATE_CONNECTING:
        return Color.Orange;
      case BluetoothConstants.STATE_DISCONNECTING:
        return Color.Orange;
      default:
        return Color.Red;
    }
  }

  /**
   * Get connected device ID
   */
  public getConnectedDeviceId(): string {
    return this.connectedDeviceId;
  }

  /**
   * Get connection state
   */
  public getConnectionState(): number {
    return this.connectionState;
  }

  /**
   * Get current display device name
   */
  public getDisplayDeviceName(): string {
    return this.displayDeviceName;
  }
}

export class DataSource {
  private icon: Resource;
  private title: string;
  private description: string;
  private stateColor: Color;
  private deviceId: string;

  constructor(icon: Resource, title: string, description: string, stateColor: Color, deviceId: string) {
    this.icon = icon;
    this.title = title;
    this.description = description;
    this.stateColor = stateColor;
    this.deviceId = deviceId;
  }

  getIcon(): Resource {
    return this.icon;
  }

  getTitle(): string {
    return this.title;
  }

  getDescription(): string {
    return this.description;
  }

  getStateColor(): Color {
    return this.stateColor;
  }

  getDeviceId(): string {
    return this.deviceId;
  }
}