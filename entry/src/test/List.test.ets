import localUnitTest from './LocalUnit.test';
import bluetoothDeviceListFiltersTest from './BluetoothDeviceListFilters.test';
import bluetoothNotificationRegistryTest from './BluetoothNotificationRegistry.test';

export default function testsuite() {
  localUnitTest();
  bluetoothDeviceListFiltersTest();
  bluetoothNotificationRegistryTest();
}