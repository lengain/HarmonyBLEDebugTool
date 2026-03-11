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
import { BluetoothConstants } from '../bluetooth/BluetoothConstants';

/**
 * 设备连接控制卡片。
 * 通过 @Consume 持有 @Observed 的 BluetoothRepository，
 * Repository 任意属性变更时 ArkUI 自动触发重渲染，无需轮询。
 */
@Component
export struct DeviceConnectionControlModule {
  // 通过 @Consume 接收 Detail 层 @Provide 的简单值，ArkUI @State→@Provide→@Consume
  // 链路对简单类型完全可靠，UI 随 Detail 的 timer 刷新同步更新。
  @Consume('bleConnState') connectionState: number;
  @Consume('bleDeviceName') deviceName: string;
  @Consume('bleDeviceId') deviceId: string;

  private getStateText(): string {
    switch (this.connectionState) {
      case BluetoothConstants.STATE_CONNECTED: return '已连接';
      case BluetoothConstants.STATE_CONNECTING: return '连接中...';
      case BluetoothConstants.STATE_DISCONNECTING: return '断开中...';
      default: return '未连接';
    }
  }

  private getStateColor(): Color {
    switch (this.connectionState) {
      case BluetoothConstants.STATE_CONNECTED: return Color.Green;
      case BluetoothConstants.STATE_CONNECTING: return Color.Orange;
      case BluetoothConstants.STATE_DISCONNECTING: return Color.Orange;
      default: return Color.Red;
    }
  }

  private getButtonText(): string {
    switch (this.connectionState) {
      case BluetoothConstants.STATE_CONNECTED: return '断开连接';
      case BluetoothConstants.STATE_CONNECTING: return '连接中...';
      case BluetoothConstants.STATE_DISCONNECTING: return '断开中...';
      default: return '连接';
    }
  }

  private getButtonColor(): Color {
    return this.connectionState === BluetoothConstants.STATE_CONNECTED ? Color.Red : Color.Blue;
  }

  private getStateBgColor(): number {
    switch (this.connectionState) {
      case BluetoothConstants.STATE_CONNECTED: return 0xE6F9ED;
      case BluetoothConstants.STATE_CONNECTING: return 0xFFF3E0;
      case BluetoothConstants.STATE_DISCONNECTING: return 0xFFF3E0;
      default: return 0xF3F4F6;
    }
  }

  private canToggle(): boolean {
    return this.connectionState !== BluetoothConstants.STATE_CONNECTING
      && this.connectionState !== BluetoothConstants.STATE_DISCONNECTING
      && (this.connectionState === BluetoothConstants.STATE_CONNECTED || this.deviceId.length > 0);
  }

  private toggleConnection(): void {
    const repo = BluetoothRepository.getInstance();
    if (this.connectionState === BluetoothConstants.STATE_CONNECTED) {
      repo.disconnectDevice(this.deviceId);
    } else if (this.connectionState === BluetoothConstants.STATE_DISCONNECTED) {
      if (this.deviceId.length > 0) {
        repo.connectDevice(this.deviceId);
      }
    }
  }

  build() {
    Column() {
      // 蓝牙图标 + 状态指示点
      Stack({ alignContent: Alignment.BottomEnd }) {
        Column() {
          Image($r('app.media.lib_icon_166'))
            .width('48vp')
            .height('48vp')
            .fillColor(this.connectionState === BluetoothConstants.STATE_CONNECTED ? 0x007DFF : 0xAAAAAA)
        }
        .width('56vp')
        .height('56vp')
        .borderRadius('28vp')
        .backgroundColor(this.connectionState === BluetoothConstants.STATE_CONNECTED ? 0xE8F2FF : 0xF3F4F6)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)

        // 状态指示点
        Column()
          .width('14vp')
          .height('14vp')
          .borderRadius('7vp')
          .backgroundColor(this.getStateColor())
          .border({ width: 2, color: Color.White })
      }
      .margin({ bottom: '16vp' })

      Text(this.deviceName)
        .fontSize('18fp')
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.font_primary'))
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .width('100%')
        .textAlign(TextAlign.Center)
        .margin({ bottom: '6vp' })

      if (this.deviceId.length > 0) {
        Text(this.deviceId)
          .fontSize('11fp')
          .fontColor($r('app.color.content_sub_title_font_color'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')
          .textAlign(TextAlign.Center)
          .margin({ bottom: '10vp' })
      }

      // 状态标签
      Row() {
        Column()
          .width('6vp')
          .height('6vp')
          .borderRadius('3vp')
          .backgroundColor(this.getStateColor())
          .margin({ right: '6vp' })
        Text(this.getStateText())
          .fontSize('13fp')
          .fontColor(this.getStateColor())
          .fontWeight(FontWeight.Medium)
      }
      .padding({ left: '12vp', right: '12vp', top: '4vp', bottom: '4vp' })
      .backgroundColor(this.getStateBgColor())
      .borderRadius('12vp')
      .margin({ bottom: '20vp' })

      // 连接/断开按钮
      Button(this.getButtonText())
        .type(ButtonType.Normal)
        .backgroundColor(this.canToggle() ? this.getButtonColor() : 0xDDDDDD)
        .fontColor(this.canToggle() ? Color.White : 0x888888)
        .fontSize('13fp')
        .fontWeight(FontWeight.Medium)
        .height('32vp')
        .padding({ left: '20vp', right: '20vp' })
        .borderRadius('16vp')
        .enabled(this.canToggle())
        .onClick(() => {
          this.toggleConnection();
        })
    }
    .width('92%')
    .padding({ top: '28vp', bottom: '28vp', left: '20vp', right: '20vp' })
    .backgroundColor($r('app.color.comp_background_primary_trans'))
    .borderRadius($r('sys.float.corner_radius_level8'))
    .alignItems(HorizontalAlign.Center)
    .justifyContent(FlexAlign.Center)
    .margin({ bottom: '12vp' })
  }
}