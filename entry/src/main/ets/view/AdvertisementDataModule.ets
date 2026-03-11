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

import { BluetoothRepository } from '../bluetooth/BluetoothRepository';

/**
 * 将 ArrayBuffer 转成以空格分隔的两字符十六进制字符串
 * 例如: "02 01 06 11 07 ..."
 */
function arrayBufferToHexGroups(buffer: ArrayBuffer): string {
  const view = new Uint8Array(buffer);
  const parts: string[] = [];
  for (let i = 0; i < view.length; i++) {
    parts.push(view[i].toString(16).padStart(2, '0').toUpperCase());
  }
  return parts.join(' ');
}

/**
 * 广播报文展示模块：展示 BLE 设备扫描阶段捕获的原始广播包（16进制）
 */
@Component
export struct AdvertisementDataModule {
  // 广播数据在扫描阶段一次性捕获，连接后不再变化，aboutToAppear 读取一次即可
  @State hexData: string = '';
  @State byteCount: number = 0;

  aboutToAppear(): void {
    const buf = BluetoothRepository.getInstance().getAdvertiseData();
    if (buf && buf.byteLength > 0) {
      this.hexData = arrayBufferToHexGroups(buf);
      this.byteCount = buf.byteLength;
    }
  }

  build() {
    Column() {
      // 标题 — 卡片外
      Row() {
        Text('广播报文')
          .fontSize('15fp')
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.font_primary'))
        if (this.byteCount > 0) {
          Text(this.byteCount.toString() + ' 字节')
            .fontSize('12fp')
            .fontColor($r('app.color.content_sub_title_font_color'))
            .margin({ left: '8vp' })
        }
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)
      .margin({ bottom: '8vp' })

      // 内容卡片
      Column() {
        if (this.hexData.length === 0) {
          Text('暂无广播数据（扫描时捕获）')
            .fontSize('13fp')
            .fontColor($r('app.color.content_sub_title_font_color'))
            .textAlign(TextAlign.Center)
            .width('100%')
            .padding({ top: 18, bottom: 18, left: 12, right: 12 })
        } else {
          Text(this.hexData)
            .fontSize('13fp')
            .fontColor($r('app.color.font_primary'))
            .fontFamily('monospace')
            .lineHeight('22vp')
            .copyOption(CopyOptions.LocalDevice)
            .width('100%')
            .padding({ top: 12, bottom: 12, left: 12, right: 12 })
            .wordBreak(WordBreak.BREAK_ALL)
        }
      }
      .width('100%')
      .backgroundColor($r('app.color.comp_background_primary_trans'))
      .borderRadius('12vp')
      .shadow({ radius: 4, color: 0x0D000000, offsetX: 0, offsetY: 2 })
    }
    .width('92%')
    .margin({ top: '10vp' })
  }
}
