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
import { BluetoothService, BluetoothCharacteristic } from '../bluetooth/BluetoothService';
import { BluetoothConstants } from '../bluetooth/BluetoothConstants';

function getPropertiesText(properties: number): string {
  const props: string[] = [];
  if (properties & BluetoothConstants.PROPERTY_READ) { props.push('Read'); }
  if (properties & BluetoothConstants.PROPERTY_WRITE) { props.push('Write'); }
  if (properties & BluetoothConstants.PROPERTY_WRITE_NO_RESPONSE) { props.push('WriteNoRsp'); }
  if (properties & BluetoothConstants.PROPERTY_NOTIFY) { props.push('Notify'); }
  if (properties & BluetoothConstants.PROPERTY_INDICATE) { props.push('Indicate'); }
  return props.length > 0 ? props.join(' | ') : '无';
}

/**
 * 服务列表：直接从 BluetoothRepository 轮询，整体赋值给 @State services[]，
 * ArkUI 检测到数组引用变更后自动重渲染，ForEach 据此刷新列表项。
 */
@Component
export struct ServiceListModule {
  @Consume('bleConnState') connectionState: number;
  @Consume('bleServices') services: BluetoothService[];
  @State expandedServiceUuid: string = '';

  private getEmptyHint(): string {
    if (this.connectionState !== BluetoothConstants.STATE_CONNECTED) {
      return '设备未连接，连接成功后自动加载服务列表';
    }
    return '已连接，正在读取服务...';
  }

  private getCharacteristics(service: BluetoothService): BluetoothCharacteristic[] {
    return service.characteristics ?? [];
  }

  build() {
    Column() {
      // 标题 — 卡片外
      Text('蓝牙服务')
        .fontSize('15fp')
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.font_primary'))
        .width('100%')
        .margin({ bottom: '8vp' })

      // 内容卡片
      Column() {
        if (this.services.length === 0) {
          Text(this.getEmptyHint())
            .fontSize('13fp')
            .fontColor($r('app.color.content_sub_title_font_color'))
            .textAlign(TextAlign.Center)
            .width('100%')
            .padding({ top: 18, bottom: 18 })
        } else {
          ForEach(this.services, (service: BluetoothService, index: number) => {
            Column() {
              // Service 头部行，点击展开/收起
              Row() {
                Column() {
                  Text(service.serviceUuid)
                    .fontSize('13fp')
                    .fontWeight(FontWeight.Medium)
                    .fontColor($r('app.color.content_font_color'))
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                    .width('100%')
                  Text((service.isPrimary ? '主' : '从') + ' Service  ·  ' +
                    (service.characteristics?.length ?? 0) + ' 个特性')
                    .fontSize('12fp')
                    .fontColor($r('app.color.content_sub_title_font_color'))
                    .margin({ top: '3vp' })
                }
                .layoutWeight(1)
                .alignItems(HorizontalAlign.Start)

                Text(this.expandedServiceUuid === service.serviceUuid ? '▲' : '▼')
                  .fontSize('11fp')
                  .fontColor($r('app.color.content_sub_title_font_color'))
                  .margin({ left: '10vp' })
              }
              .width('100%')
              .padding({ top: '12vp', bottom: '12vp', left: '14vp', right: '14vp' })
              .onClick(() => {
                this.expandedServiceUuid =
                  this.expandedServiceUuid === service.serviceUuid ? '' : service.serviceUuid;
              })

              // 展开的 Characteristic 列表
              if (this.expandedServiceUuid === service.serviceUuid) {
                Column() {
                  Divider()
                    .color(0x1A000000)
                    .strokeWidth(0.5)
                    .margin({ left: '14vp', right: '14vp' })

                  if (this.getCharacteristics(service).length === 0) {
                    Text('该 Service 暂无 Characteristic')
                      .fontSize('12fp')
                      .fontColor($r('app.color.content_sub_title_font_color'))
                      .textAlign(TextAlign.Center)
                      .width('100%')
                      .padding({ top: 12, bottom: 12 })
                  } else {
                    ForEach(this.getCharacteristics(service),
                      (char: BluetoothCharacteristic, charIndex: number) => {
                        Column() {
                          Text(char.characteristicUuid)
                            .fontSize('12fp')
                            .fontWeight(FontWeight.Medium)
                            .fontColor($r('app.color.content_font_color'))
                            .maxLines(2)
                            .textOverflow({ overflow: TextOverflow.Ellipsis })
                            .width('100%')
                            .margin({ bottom: '4vp' })
                          Text(getPropertiesText(char.properties))
                            .fontSize('11fp')
                            .fontColor(0x3B82F6)
                            .maxLines(1)
                            .width('100%')
                        }
                        .width('100%')
                        .padding({ top: '10vp', bottom: '10vp', left: '20vp', right: '14vp' })
                        .border({ width: { bottom: 0.5 }, color: 0x0F000000 })
                      },
                      (char: BluetoothCharacteristic, charIndex: number) =>
                        char.characteristicUuid || String(charIndex))
                  }
                }
                .width('100%')
              }
            }
            .width('100%')
            .backgroundColor($r('app.color.comp_background_primary'))
            .borderRadius($r('sys.float.corner_radius_level8'))
          }, (service: BluetoothService, index: number) => service.serviceUuid || String(index))
        }
      }
      .width('100%')
      .padding({ left: '12vp', right: '12vp', top: '8vp', bottom: '12vp' })
      .backgroundColor($r('app.color.comp_background_primary_trans'))
      .borderRadius('12vp')
      .shadow({ radius: 4, color: 0x0D000000, offsetX: 0, offsetY: 2 })
    }
    .width('92%')
    .margin({ top: '10vp' })
  }
}