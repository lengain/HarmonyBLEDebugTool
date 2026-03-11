import { AbilityConstant, ConfigurationConstant, UIAbility, Want, PermissionRequestResult } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import { abilityAccessCtrl, Permissions } from '@kit.AbilityKit';
import { common } from '@kit.AbilityKit';
import { access } from '@kit.ConnectivityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import Logger from '../util/Logger';

const DOMAIN = 0x0000;

export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    try {
      this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
    } catch (err) {
      hilog.error(DOMAIN, 'testTag', 'Failed to set colorMode. Cause: %{public}s', JSON.stringify(err));
    }
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onCreate');
  }

  onDestroy(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    // Main window is created, set main page for this ability
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageCreate');

    // Prepare runtime permissions and bluetooth switch status at startup.
    void this.prepareBluetoothEnvironment();

    windowStage.loadContent('pages/Index', (err) => {
      if (err.code) {
        hilog.error(DOMAIN, 'testTag', 'Failed to load the content. Cause: %{public}s', JSON.stringify(err));
        return;
      }
      hilog.info(DOMAIN, 'testTag', 'Succeeded in loading the content.');
    });
  }

  private async prepareBluetoothEnvironment(): Promise<void> {
    await this.requestPermissions();
    this.ensureBluetoothEnabled();
  }

  private async requestPermissions(): Promise<void> {
    const atManager: abilityAccessCtrl.AtManager = abilityAccessCtrl.createAtManager();
    const permissions: Permissions[] = [
      'ohos.permission.ACCESS_BLUETOOTH',
      'ohos.permission.LOCATION'
    ];

    try {
      const context: common.UIAbilityContext = this.context as common.UIAbilityContext;
      const result: PermissionRequestResult =
        await atManager.requestPermissionsFromUser(context, permissions);
      Logger.info('Permissions requested: ' + JSON.stringify(result.authResults));
    } catch (err) {
      const error = err as BusinessError;
      Logger.error('Request permissions failed, code: ' + error.code + ', message: ' + error.message);
    }
  }

  private ensureBluetoothEnabled(): void {
    try {
      const state: access.BluetoothState = access.getState();
      if (state === access.BluetoothState.STATE_OFF) {
        access.enableBluetooth();
        Logger.info('Bluetooth is off, showing enable dialog');
      }
    } catch (err) {
      const error = err as BusinessError;
      Logger.error('Check or enable bluetooth failed, code: ' + error.code + ', message: ' + error.message);
    }
  }

  onWindowStageDestroy(): void {
    // Main window is destroyed, release UI related resources
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageDestroy');
  }

  onForeground(): void {
    // Ability has brought to foreground
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onForeground');
  }

  onBackground(): void {
    // Ability has back to background
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onBackground');
  }
}