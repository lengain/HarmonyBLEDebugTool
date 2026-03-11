import { PageMap } from '../detail/SecondPageBuilder'
import { BreakpointConstants } from '../common/BreakpointConstants';
import { CommonConstants } from '../common/CommonConstants';
import { Detail } from './Detail';
import { BluetoothDeviceListModule } from '../view/BluetoothDeviceListModule';

@Entry
@Component
struct Index {
  @State currentIndex: number = 0;
  private tabsController: TabsController = new TabsController();
  @Provide('appPathStack') appPathStack: NavPathStack = new NavPathStack();
  private readonly searchKeywordPreferenceKey: string = 'ble_device_list_search_keyword';

  aboutToAppear(): void {
    PersistentStorage.PersistProp(this.searchKeywordPreferenceKey, '');
  }

  build() {
    Navigation(this.appPathStack) {
      Column() {
        BluetoothDeviceListModule()
      }
      .width('100%')
      .height('100%')
    }
    .backgroundColor($r('app.color.page_bg_color'))
    .navDestination(PageMap)
    .hideTitleBar(true)
    .mode(NavigationMode.Stack)
  }
}