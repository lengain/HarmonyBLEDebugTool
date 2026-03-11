import { beforeEach, describe, expect, it } from '@ohos/hypium';
import {
  BluetoothDeviceFilterConstants,
  BluetoothDeviceSortMode,
  Data
} from '../main/ets/viewmodel/BluetoothDeviceListModuleData';
import { BluetoothDevice } from '../main/ets/bluetooth/BluetoothService';

function createDevices(): BluetoothDevice[] {
  return [
    {
      deviceId: 'device-c',
      deviceName: 'Thermo C',
      rssi: -88
    },
    {
      deviceId: 'device-a',
      deviceName: 'Alpha Sensor',
      rssi: -62
    },
    {
      deviceId: 'device-b',
      deviceName: 'Beacon',
      rssi: -75
    }
  ];
}

export default function bluetoothDeviceListFiltersTest() {
  describe('BluetoothDeviceList filters and sorts', () => {
    let data: Data;

    beforeEach(() => {
      data = Data.getInstance();
      data.setFilterKeyword('');
      data.setMinRssi(BluetoothDeviceFilterConstants.NO_MIN_RSSI);
      data.setSortMode(BluetoothDeviceSortMode.DISCOVERY);
    });

    it('should keep discovery order by default', 0, () => {
      const result: BluetoothDevice[] = data.getProcessedDevices(createDevices());
      expect(result[0].deviceId).assertEqual('device-c');
      expect(result[1].deviceId).assertEqual('device-a');
      expect(result[2].deviceId).assertEqual('device-b');
    });

    it('should filter devices by keyword', 0, () => {
      data.setFilterKeyword('alpha');
      const result: BluetoothDevice[] = data.getProcessedDevices(createDevices());
      expect(result.length).assertEqual(1);
      expect(result[0].deviceId).assertEqual('device-a');
    });

    it('should filter devices by minimum rssi', 0, () => {
      data.setMinRssi(-70);
      const result: BluetoothDevice[] = data.getProcessedDevices(createDevices());
      expect(result.length).assertEqual(1);
      expect(result[0].deviceId).assertEqual('device-a');
    });

    it('should sort devices by rssi descending', 0, () => {
      data.setSortMode(BluetoothDeviceSortMode.RSSI_DESC);
      const result: BluetoothDevice[] = data.getProcessedDevices(createDevices());
      expect(result[0].deviceId).assertEqual('device-a');
      expect(result[1].deviceId).assertEqual('device-b');
      expect(result[2].deviceId).assertEqual('device-c');
    });

    it('should sort devices by name ascending', 0, () => {
      data.setSortMode(BluetoothDeviceSortMode.NAME_ASC);
      const result: BluetoothDevice[] = data.getProcessedDevices(createDevices());
      expect(result[0].deviceId).assertEqual('device-a');
      expect(result[1].deviceId).assertEqual('device-b');
      expect(result[2].deviceId).assertEqual('device-c');
    });

    it('should restore discovery order after resetting filter and sort states', 0, () => {
      data.setFilterKeyword('bea');
      data.setMinRssi(-80);
      data.setSortMode(BluetoothDeviceSortMode.NAME_DESC);

      // Simulate reset action from UI state: clear keyword, restore default rssi and discovery sort.
      data.setFilterKeyword('');
      data.setMinRssi(BluetoothDeviceFilterConstants.NO_MIN_RSSI);
      data.setSortMode(BluetoothDeviceSortMode.DISCOVERY);

      const result: BluetoothDevice[] = data.getProcessedDevices(createDevices());
      expect(result.length).assertEqual(3);
      expect(result[0].deviceId).assertEqual('device-c');
      expect(result[1].deviceId).assertEqual('device-a');
      expect(result[2].deviceId).assertEqual('device-b');
    });
  });
}