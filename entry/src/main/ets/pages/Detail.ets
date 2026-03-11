import { DeviceConnectionControlModule } from '../view/DeviceConnectionControlModule';
import { ServiceListModule } from '../view/ServiceListModule';
import { AdvertisementDataModule } from '../view/AdvertisementDataModule';
import { CommonConstants } from '../common/CommonConstants';
import { BluetoothRepository } from '../bluetooth/BluetoothRepository';
import { BluetoothService } from '../bluetooth/BluetoothService';
import { BluetoothConstants } from '../bluetooth/BluetoothConstants';
import { UiToast } from '../util/UiToast';

@Component
export struct Detail {
  private scroller: Scroller = new Scroller();
  @Consume('appPathStack') appPathStack: NavPathStack;
  // Detail 作为数据层：统一 500ms 轮询 Repository 并通过 @Provide 将简单值分发给子组件。
  // @State + @Provide（简单类型）是最可靠的跨层响应路径，子组件无需自己维护 timer。
  @Provide('bleConnState') connectionState: number = BluetoothConstants.STATE_DISCONNECTED;
  @Provide('bleDeviceName') deviceName: string = '未知设备';
  @Provide('bleDeviceId') deviceId: string = '';
  @Provide('bleServices') services: BluetoothService[] = [];
  @State servicesDiscoverErrorMessage: string = '';
  @State lastToastServicesDiscoverErrorMessage: string = '';
  private refreshTimer: number = 0;
  private repo: BluetoothRepository = BluetoothRepository.getInstance();

  aboutToAppear(): void {
    this.refreshFromRepo();
    this.refreshTimer = setInterval(() => { this.refreshFromRepo(); }, 500);
  }

  aboutToDisappear(): void {
    if (this.refreshTimer > 0) { clearInterval(this.refreshTimer); }
  }

  private refreshFromRepo(): void {
    this.connectionState = this.repo.getConnectionState();
    this.deviceId = this.repo.getDisplayDeviceId();
    this.deviceName = this.repo.getDisplayDeviceName();
    this.services = this.repo.getServices().slice();
    this.servicesDiscoverErrorMessage = this.repo.getServicesDiscoverErrorMessage();

    if (this.servicesDiscoverErrorMessage.length === 0) {
      this.lastToastServicesDiscoverErrorMessage = '';
      return;
    }

    if (this.lastToastServicesDiscoverErrorMessage !== this.servicesDiscoverErrorMessage) {
      UiToast.show(this.servicesDiscoverErrorMessage);
      this.lastToastServicesDiscoverErrorMessage = this.servicesDiscoverErrorMessage;
    }
  }

  private goBack(): void {
    this.appPathStack.pop();
  }

  build() {
    NavDestination() {
      Column() {
        Scroll(this.scroller) {
          Column() {
            DeviceConnectionControlModule()
            AdvertisementDataModule()
            if (this.servicesDiscoverErrorMessage.length > 0) {
              Text(this.servicesDiscoverErrorMessage)
                .fontSize('12fp')
                .fontColor(Color.Red)
                .width('92%')
                .textAlign(TextAlign.Center)
                .margin({ top: '8vp' })
            }
            ServiceListModule()
          }
          .margin({ top: '10vp', bottom: '10vp' })
          .width('100%')
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
        }
        .scrollable(ScrollDirection.Vertical)
        .scrollBar(BarState.Off)
        .height('100%')
        .width('100%')
        .align(Alignment.Top)
        .backgroundColor($r('app.color.page_bg_color'))
      }
      .height('100%')
      .width('100%')
      .backgroundColor($r('app.color.page_bg_color'))
    }
    .title('设备详情')
    .onBackPressed(() => {
      this.goBack();
      return true;
    })
    .height(CommonConstants.FULL_PERCENT)
    .width(CommonConstants.FULL_PERCENT)
  }
}