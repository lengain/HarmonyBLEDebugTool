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
import { BluetoothService, BluetoothCharacteristic } from '../bluetooth/BluetoothService';
import { BluetoothConstants } from '../bluetooth/BluetoothConstants';
import Logger from '../util/Logger';

@Observed
export class Data {
  private static instance: Data;
  lazyDataSource: LazyDataSource<DataSource> = new LazyDataSource();

  constructor() {
  }

  public static getInstance(): Data {
    if (!Data.instance) {
      Data.instance = new Data();
    }
    return Data.instance;
  }

  /**
   * Get services from repository
   */
  getResources(): Promise<void> {
    return new Promise((resolve: Function) => {
      try {
        const repo = BluetoothRepository.getInstance();
        const services = repo.getServices();
        const modelList: Array<DataSource> = [];
        
        services.forEach((service: BluetoothService): void => {
          const isPrimaryText = service.isPrimary ? '主Service' : '从Service';
          const charCount = service.characteristics?.length ?? 0;
          const descriptionText = '包含 ' + charCount + ' 个特性';
          
          const dataSource = new DataSource(
            $r('app.media.realImageGen_common_1'),
            service.serviceUuid,
            isPrimaryText,
            descriptionText
          );
          dataSource.setServiceUUID(service.serviceUuid);
          dataSource.setCharacteristics(service.characteristics ?? []);
          modelList.push(dataSource);
        });
        
        this.lazyDataSource.pushArrayData(modelList);
        Logger.info('Services list updated: ' + modelList.length);
        resolve();
      } catch (err) {
        Logger.error('Get services error: ' + JSON.stringify(err));
        resolve();
      }
    });
  }

  /**
   * Get services count
   */
  public getServicesCount(): number {
    const repo = BluetoothRepository.getInstance();
    return repo.getServices().length;
  }

  /**
   * Get current connection state
   */
  public getConnectionState(): number {
    const repo = BluetoothRepository.getInstance();
    const state: number = repo.getConnectionState();
    if (state === undefined || state === null) {
      return BluetoothConstants.STATE_DISCONNECTED;
    }
    return state;
  }

  /**
   * Select service to view characteristics
   */
  public selectService(service: BluetoothService): void {
    const repo = BluetoothRepository.getInstance();
    repo.selectService(service);
  }
}

export class DataSource {
  private image: Resource;
  private mainText: string;
  private subText: string;
  private descriptionText: string;
  private serviceUuid: string = '';
  private characteristics: BluetoothCharacteristic[] = [];

  constructor(image: Resource, mainText: string, subText: string, descriptionText: string) {
    this.image = image;
    this.mainText = mainText;
    this.subText = subText;
    this.descriptionText = descriptionText;
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

  getServiceUuid(): string {
    return this.serviceUuid;
  }

  setServiceUUID(uuid: string): void {
    this.serviceUuid = uuid;
  }

  getCharacteristics(): BluetoothCharacteristic[] {
    return this.characteristics;
  }

  setCharacteristics(chars: BluetoothCharacteristic[]): void {
    this.characteristics = chars;
  }
}