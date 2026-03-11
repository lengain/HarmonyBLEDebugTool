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
import { BluetoothCharacteristic } from '../bluetooth/BluetoothService';
import { BluetoothConstants } from '../bluetooth/BluetoothConstants';
import Logger from '../util/Logger';

@Observed
export class Data {
  private static instance: Data;
  lazyDataSource: LazyDataSource<DataSource> = new LazyDataSource();
  private repository: BluetoothRepository = BluetoothRepository.getInstance();

  constructor() {
  }

  public static getInstance(): Data {
    if (!Data.instance) {
      Data.instance = new Data();
    }
    return Data.instance;
  }

  /**
   * Get characteristics from selected service
   */
  getResources(): Promise<void> {
    return new Promise((resolve: Function) => {
      try {
        const characteristics = this.repository.getCharacteristics();
        const modelList: Array<DataSource> = [];
        
        characteristics.forEach((char: BluetoothCharacteristic): void => {
          const propertiesText = this.getPropertiesText(char.properties);
          
          const dataSource = new DataSource(
            $r('app.media.news'),
            char.characteristicUuid,
            propertiesText,
            char.serviceUuid
          );
          dataSource.setCharacteristicUUID(char.characteristicUuid);
          dataSource.setProperties(char.properties);
          modelList.push(dataSource);
        });
        
        this.lazyDataSource.pushArrayData(modelList);
        Logger.info('Characteristics list updated: ' + modelList.length);
        resolve();
      } catch (err) {
        Logger.error('Get characteristics error: ' + JSON.stringify(err));
        resolve();
      }
    });
  }

  /**
   * Get properties display text
   */
  private getPropertiesText(properties: number): string {
    const props: string[] = [];
    if (properties & BluetoothConstants.PROPERTY_READ) {
      props.push('Read');
    }
    if (properties & BluetoothConstants.PROPERTY_WRITE) {
      props.push('Write');
    }
    if (properties & BluetoothConstants.PROPERTY_WRITE_NO_RESPONSE) {
      props.push('WriteNoRsp');
    }
    if (properties & BluetoothConstants.PROPERTY_NOTIFY) {
      props.push('Notify');
    }
    if (properties & BluetoothConstants.PROPERTY_INDICATE) {
      props.push('Indicate');
    }
    return props.length > 0 ? props.join(', ') : 'None';
  }

  /**
   * Get characteristics count
   */
  public getCharacteristicsCount(): number {
    return this.repository.getCharacteristics().length;
  }

  /**
   * Get current connection state
   */
  public getConnectionState(): number {
    return this.repository.getConnectionState();
  }
}

export class DataSource {
  private icon: Resource;
  private title: string;
  private description: string;
  private serviceUuid: string;
  private characteristicUuid: string = '';
  private properties: number = 0;

  constructor(icon: Resource, title: string, description: string, serviceUuid: string) {
    this.icon = icon;
    this.title = title;
    this.description = description;
    this.serviceUuid = serviceUuid;
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

  getServiceUuid(): string {
    return this.serviceUuid;
  }

  getCharacteristicUuid(): string {
    return this.characteristicUuid;
  }

  setCharacteristicUUID(uuid: string): void {
    this.characteristicUuid = uuid;
  }

  getProperties(): number {
    return this.properties;
  }

  setProperties(props: number): void {
    this.properties = props;
  }
}