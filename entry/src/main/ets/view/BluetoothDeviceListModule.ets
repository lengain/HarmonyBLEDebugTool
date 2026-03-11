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
import {
  Data,
  BluetoothDeviceSortMode
} from '../viewmodel/BluetoothDeviceListModuleData';
import { LoadingStatus } from '../common/CommonEnums';
import { LoadingFailedView } from '../view/LoadingFailedView';
import { BreakpointConstants } from '../common/BreakpointConstants';
import { BreakpointType } from '../util/BreakpointType';
import { CommonConstants } from '../common/CommonConstants';
import Logger from '../util/Logger';
import { BluetoothRepository } from '../bluetooth/BluetoothRepository';
import { BluetoothDevice } from '../bluetooth/BluetoothService';

@Component
export struct BluetoothDeviceListModule {
  @State itemModel: Data =
    Data.getInstance();
  @Prop listDirection: Axis = Axis.Vertical
  @State moduleTitle: string = "蓝牙设备列表";
  @State loadingStatus: LoadingStatus = LoadingStatus.OFF;
  @State scannedDevices: BluetoothDevice[] = [];
  @State isScanning: boolean = false;
  @State scanButtonText: string = "开始扫描";
  @State isScanActionPending: boolean = false;
  @State scanErrorMessage: string = '';
  @State filterKeyword: string = '';
  @State selectedSortMode: string = BluetoothDeviceSortMode.DISCOVERY;
  @State showSortPanel: boolean = false;
  @State rawScannedDeviceCount: number = 0;
  private readonly searchKeywordPreferenceKey: string = 'ble_device_list_search_keyword';
  private spaceArray: string[] = ['8vp', '6vp', '10vp'];
  private lanesArray: number[] = [1, 2, 3];
  @Consume('appPathStack') appPathStack: NavPathStack;
  @StorageLink('currentWidthBreakpoint') currentWidthBreakpoint: string = BreakpointConstants.BREAKPOINT_SM;

  aboutToAppear() {
    this.restoreSearchKeywordPreference();
    this.loadResources();
    this.setupRepositoryListener();
  }

  aboutToDisappear() {
    // Cleanup handled by listeners
  }

  private setupRepositoryListener(): void {
    const repository: BluetoothRepository = BluetoothRepository.getInstance();
    repository.onScanStateChanged((isScanning: boolean) => {
      this.isScanning = isScanning;
      this.scanButtonText = isScanning ? "停止扫描" : "开始扫描";
      this.isScanActionPending = false;
    });

    repository.onDevicesChanged(() => {
      Logger.info('Device list changed, updating UI');
      this.refreshDeviceList();
    });

    repository.onScanErrorChanged((errorMessage: string) => {
      this.scanErrorMessage = errorMessage;
      if (errorMessage.length > 0) {
        this.isScanActionPending = false;
      }
    });
  }

  jump(pageName: string = 'EmptyPagePathStack'): void {
    this.appPathStack.pushPathByName(pageName, null);
  }

  loadResources(): void {
    this.loadingStatus = LoadingStatus.LOADING;
    this.refreshDeviceList().catch(() => {
      this.loadingStatus = LoadingStatus.FAILED;
    });
  }

  onScanButtonClick(): void {
    if (this.isScanActionPending) {
      return;
    }

    this.isScanActionPending = true;
    if (this.isScanning) {
      Logger.info('Stop scanning');
      this.itemModel.stopScan();
    } else {
      Logger.info('Start scanning');
      this.scanErrorMessage = '';
      this.itemModel.startScan();
    }
  }

  private refreshDeviceList(): Promise<void> {
    this.syncFilterState();
    return this.itemModel.getResources().then(() => {
      this.rawScannedDeviceCount = this.itemModel.getRawScannedDeviceCount();
      this.scannedDevices = this.itemModel.getFilteredAndSortedDevices();
      this.loadingStatus = LoadingStatus.SUCCESS;
      this.isScanning = this.itemModel.isScanning();
      this.scanButtonText = this.isScanning ? "停止扫描" : "开始扫描";
      this.scanErrorMessage = this.itemModel.getScanErrorMessage();
    });
  }

  private syncFilterState(): void {
    this.itemModel.setFilterKeyword(this.filterKeyword);
    this.itemModel.setSortMode(this.selectedSortMode);
  }

  private updateFilterKeyword(keyword: string): void {
    this.filterKeyword = keyword;
    this.saveSearchKeywordPreference();
    this.refreshDeviceList();
  }

  private selectSortMode(sortMode: string): void {
    this.selectedSortMode = sortMode;
    this.showSortPanel = false;
    this.refreshDeviceList();
  }

  private toggleSortPanel(): void {
    this.showSortPanel = !this.showSortPanel;
  }

  private resetFilters(): void {
    this.filterKeyword = '';
    this.saveSearchKeywordPreference();
    this.selectedSortMode = BluetoothDeviceSortMode.DISCOVERY;
    this.showSortPanel = false;
    this.refreshDeviceList();
  }

  private restoreSearchKeywordPreference(): void {
    try {
      const keyword: string | undefined = AppStorage.Get<string>(this.searchKeywordPreferenceKey);
      this.filterKeyword = keyword ? keyword : '';
    } catch (err) {
      Logger.error('Restore search keyword preference failed: ' + JSON.stringify(err));
      this.filterKeyword = '';
    }
  }

  private saveSearchKeywordPreference(): void {
    try {
      AppStorage.Set<string>(this.searchKeywordPreferenceKey, this.filterKeyword);
    } catch (err) {
      Logger.error('Save search keyword preference failed: ' + JSON.stringify(err));
    }
  }

  private hasActiveFilters(): boolean {
    return this.filterKeyword.trim().length > 0;
  }

  private hasActiveFilterOrSort(): boolean {
    return this.hasActiveFilters() || this.selectedSortMode !== BluetoothDeviceSortMode.DISCOVERY;
  }

  private getEmptyStateMessage(): string {
    if (this.rawScannedDeviceCount > 0 && this.hasActiveFilters()) {
      return '当前筛选条件下无匹配设备';
    }
    return '未扫描到设备，请点击右上角开始扫描';
  }

  private getSortButtonText(): string {
    if (this.selectedSortMode === BluetoothDeviceSortMode.NAME_ASC) {
      return '排序: 名称 A-Z';
    }
    if (this.selectedSortMode === BluetoothDeviceSortMode.NAME_DESC) {
      return '排序: 名称 Z-A';
    }
    return '排序: 发现顺序';
  }

  build() {
    Stack() {
      Column() {
        Column() {
          BluetoothDeviceListModuleTitleInfo({
            title: this.moduleTitle,
            actionText: this.scanButtonText,
            actionEnabled: !this.isScanActionPending,
            onJump: () => {
              this.onScanButtonClick()
            }
          })
          BluetoothDeviceListToolbar({
            searchValue: this.filterKeyword,
            sortText: this.getSortButtonText(),
            resetActive: this.hasActiveFilterOrSort(),
            onKeywordChange: (value: string) => {
              this.updateFilterKeyword(value);
            },
            onSortClick: () => {
              this.toggleSortPanel();
            },
            onResetClick: () => {
              this.resetFilters();
            }
          })
          if (this.showSortPanel) {
            BluetoothDeviceSortPanel({
              selectedSortMode: this.selectedSortMode,
              onSelect: (sortMode: string) => {
                this.selectSortMode(sortMode);
              }
            })
          }
          if (this.loadingStatus === LoadingStatus.FAILED) {
            LoadingFailedView(() => this.loadResources())
          }
          if (this.loadingStatus === LoadingStatus.SUCCESS) {
            if (this.scannedDevices.length === 0) {
              Column() {
                Text(this.getEmptyStateMessage())
                  .fontSize('16fp')
                  .fontColor($r('app.color.content_font_color'))
                  .textAlign(TextAlign.Center)
                  .width('100%')
                  .padding({ top: 24, bottom: 12 })
                if (this.scanErrorMessage.length > 0) {
                  Text(this.scanErrorMessage)
                    .fontSize('12fp')
                    .fontColor(Color.Red)
                    .textAlign(TextAlign.Center)
                    .width('100%')
                    .padding({ left: 12, right: 12, bottom: 24 })
                }
              }
              .width('100%')
              .alignItems(HorizontalAlign.Center)
            } else {
              List({
                space: new BreakpointType(this.spaceArray[0], this.spaceArray[1],
                  this.spaceArray[2]).getValue(this.currentWidthBreakpoint)
              }) {
                ForEach(this.scannedDevices, (device: BluetoothDevice) => {
                  ListItem() {
                    HorizontalGraphicTextDisplayItem({
                      mainText: device.deviceName,
                      subText: device.rssi + 'dBm',
                      descriptionText: '设备ID: ' + device.deviceId,
                      tagTextList: [],
                      tagTextColorList: [],
                      onConnect: () => {
                        const repo = BluetoothRepository.getInstance();
                        if (repo.getIsConnected() && repo.getDisplayDeviceId() === device.deviceId) {
                          // 已连接该设备，直接跳转详情页
                          this.jump("Detail");
                          return;
                        }
                        repo.setTargetDevice(device.deviceId, device.deviceName);
                        this.itemModel.connectDevice(device.deviceId);
                        this.jump("Detail");
                      }
                    })
                  }
                  .width('100%')
                  .borderRadius($r('sys.float.corner_radius_level8'))
                  .backgroundColor($r('app.color.module_item_bg_color'))
                }, (device: BluetoothDevice) => device.deviceId)
              }
              .width('auto')
              .edgeEffect(EdgeEffect.Spring, { alwaysEnabled: true })
              .listDirection(this.listDirection)
              .lanes(new BreakpointType(this.lanesArray[0], this.lanesArray[1],
                this.lanesArray[2]).getValue(this.currentWidthBreakpoint), "12vp")
            }
          }
        }
        .borderRadius($r('sys.float.corner_radius_level8'))
        .margin({ bottom: "10vp" })
        .align(Alignment.Center)
        .width('92%')
      }
      .width("100%")
    }
    .width("100%")
    .align(Alignment.TopStart)
  }
}

@Component
export struct HorizontalGraphicTextDisplayItem {
  @State mainText: string = '主标题文本';
  @State subText: string = '子标题文本';
  @State descriptionText: string = '这是一个描述文本，用于展示一些详细信息。';
  @State tagTextList: string[] = ['标签1', '标签2', '标签3', "标签4"];
  @State tagTextColorList: Color[] = [Color.Brown, Color.Green, Color.Gray, Color.Blue];
  @StorageLink('currentWidthBreakpoint') currentWidthBreakpoint: string = BreakpointConstants.BREAKPOINT_SM;
  public onConnect: () => void = () => {};

  build() {
    Row() {
      Column() {

        Row({space: 12}) {
          Text(this.mainText)
            .fontSize('16fp')
            .fontColor($r('app.color.content_font_color'))
            .fontWeight(FontWeight.Bold)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })

          Text(this.subText)
            .fontSize('12fp')
            .fontColor(0x007DFF)
            .fontWeight(FontWeight.Medium)
            .padding({ left: 8, right: 8, top: 2, bottom: 2 })
            .backgroundColor(0xE8F2FF)
            .borderRadius(10)
        }
        .justifyContent(FlexAlign.Start)
        .width('100%')

        Row() {
          Text(this.descriptionText)
            .fontSize('13fp')
            .fontColor($r('app.color.description_font_color_List_HorizontalGraphicTextDisplayItem'))
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })

          Button('连接')
            .type(ButtonType.Normal)
            .fontSize('11vp')
            .height('22vp')
            .backgroundColor(0x007DFF)
            .fontColor(Color.White)
            .borderRadius(11)
            .onClick(() => this.onConnect())
            .width('64vp')
        }
        .margin({ bottom: 6 })
        .width(CommonConstants.FULL_PERCENT)
        .justifyContent(FlexAlign.SpaceBetween)
      }
      .padding({ left: 14, right: 14 })
      .width('100%')
      .height('50vp')
      .alignItems(HorizontalAlign.Start)
      .justifyContent(FlexAlign.Center)
    }
    .borderRadius($r('sys.float.corner_radius_level8'))
    .backgroundColor($r('app.color.comp_background_primary_trans'))
    .width(CommonConstants.FULL_PERCENT)
    .padding({ top: 3, bottom: 3 })
    .alignItems(VerticalAlign.Center)
  }
}

@Component
export struct BluetoothDeviceListModuleTitleInfo {
  @StorageLink('currentWidthBreakpoint') currentWidthBreakpoint: string = BreakpointConstants.BREAKPOINT_LG;
  public title: string = '';
  @Prop actionText: string = '开始扫描';
  public actionEnabled: boolean = true;
  @Consume('appPathStack') appPathStack: NavPathStack;
  public onJump?: () => void;

  jump(): void {
    this.appPathStack.pushPathByName('EmptyPagePathStack', null);
  }

  build() {
    if (this.title.length) {
      Row() {
        Text(this.title)
          .fontSize('18fp')
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.font_primary'))
        Button(this.actionText)
          .type(ButtonType.Normal)
          .height('32vp')
          .borderRadius(16)
          .padding({ left: '12vp', right: '12vp' })
          .backgroundColor(0x007DFF)
          .fontColor(Color.White)
          .fontSize('12fp')
          .fontWeight(FontWeight.Medium)
          .enabled(this.actionEnabled)
          .opacity(this.actionEnabled ? 1 : 0.6)
          .onClick(() => {
            if (this.onJump) {
              this.onJump();
            } else {
              this.jump();
            }
          })
      }
      .width(CommonConstants.FULL_PERCENT)
      .height("44vp")
      .justifyContent(FlexAlign.SpaceBetween)
      .borderRadius($r('sys.float.corner_radius_level8'))
    }
  }
}

@Component
struct BluetoothDeviceListToolbar {
  @Prop searchValue: string = '';
  @Prop sortText: string = '排序: 发现顺序';
  @Prop resetActive: boolean = false;
  public onKeywordChange: (value: string) => void = () => {};
  public onSortClick: () => void = () => {};
  public onResetClick: () => void = () => {};

  build() {
    Row({ space: 8 }) {
      Search({
        placeholder: '搜索设备名',
        value: this.searchValue
      })
        .layoutWeight(1)
        .height('36vp')
        .backgroundColor($r('sys.color.ohos_id_color_sub_background'))
        .placeholderFont({ size: $r('sys.float.Body_L') })
        .textFont({ size: $r('sys.float.Body_L') })
        .onChange((value: string) => {
          this.onKeywordChange(value);
        })

      Button(this.sortText)
        .type(ButtonType.Normal)
        .height('36vp')
        .padding({ left: '10vp', right: '10vp' })
        .backgroundColor(0xEAF3FF)
        .fontColor(0x007DFF)
        .fontSize('11fp')
        .borderRadius(18)
        .onClick(() => this.onSortClick())

      Button('重置')
        .type(ButtonType.Normal)
        .height('36vp')
        .padding({ left: '10vp', right: '10vp' })
        .backgroundColor(this.resetActive ? 0xFFEFD5 : 0xE8E8E8)
        .fontColor(this.resetActive ? 0x9A3412 : $r('app.color.content_font_color'))
        .fontSize('11fp')
        .borderRadius(18)
        .enabled(this.resetActive)
        .opacity(this.resetActive ? 1 : 0.7)
        .onClick(() => this.onResetClick())
    }
    .width(CommonConstants.FULL_PERCENT)
    .margin({ top: '8vp', bottom: '10vp' })
  }
}

@Component
struct BluetoothDeviceSortPanel {
  @Prop selectedSortMode: string = BluetoothDeviceSortMode.DISCOVERY;
  public onSelect: (sortMode: string) => void = () => {};

  build() {
    Row({ space: 8 }) {
      SortOptionChip({
        text: '发现顺序',
        selected: this.selectedSortMode === BluetoothDeviceSortMode.DISCOVERY,
        onTap: () => this.onSelect(BluetoothDeviceSortMode.DISCOVERY)
      })
      SortOptionChip({
        text: '名称 A-Z',
        selected: this.selectedSortMode === BluetoothDeviceSortMode.NAME_ASC,
        onTap: () => this.onSelect(BluetoothDeviceSortMode.NAME_ASC)
      })
      SortOptionChip({
        text: '名称 Z-A',
        selected: this.selectedSortMode === BluetoothDeviceSortMode.NAME_DESC,
        onTap: () => this.onSelect(BluetoothDeviceSortMode.NAME_DESC)
      })
    }
    .width(CommonConstants.FULL_PERCENT)
    .padding({ left: '12vp', right: '12vp', top: '12vp', bottom: '12vp' })
    .margin({ bottom: '10vp' })
    .backgroundColor(Color.White)
    .borderRadius($r('sys.float.corner_radius_level8'))
  }
}

@Component
struct SortOptionChip {
  @Prop text: string = '';
  @Prop selected: boolean = false;
  public onTap: () => void = () => {};

  build() {
    Button(this.text)
      .type(ButtonType.Capsule)
      .fontSize('11fp')
      .fontColor(this.selected ? Color.White : $r('app.color.content_font_color'))
      .backgroundColor(this.selected ? 0x007DFF : 0xF3F4F6)
      .onClick(() => this.onTap())
  }
}