import { describe, it, expect } from '@ohos/hypium';
import { CharacteristicNotificationRegistry } from '../main/ets/bluetooth/BluetoothService';

export default function bluetoothNotificationRegistryTest() {
  describe('Bluetooth notification registry', () => {
    it('should build stable key', 0, () => {
      const registry: CharacteristicNotificationRegistry = new CharacteristicNotificationRegistry();
      const key: string = registry.buildKey('d1', 's1', 'c1');
      expect(key).assertEqual('d1|s1|c1');
    });

    it('should replace handler by same key', 0, () => {
      const registry: CharacteristicNotificationRegistry = new CharacteristicNotificationRegistry();
      const key: string = registry.buildKey('d1', 's1', 'c1');
      const handler1 = () => {};
      const handler2 = () => {};

      registry.set(key, handler1);
      registry.set(key, handler2);

      expect(registry.size()).assertEqual(1);
      expect(registry.get(key)).assertEqual(handler2);
    });

    it('should clear only target device handlers', 0, () => {
      const registry: CharacteristicNotificationRegistry = new CharacteristicNotificationRegistry();
      const keyA1: string = registry.buildKey('device-a', 'service-1', 'char-1');
      const keyA2: string = registry.buildKey('device-a', 'service-2', 'char-2');
      const keyB1: string = registry.buildKey('device-b', 'service-1', 'char-1');

      const handlerA1 = () => {};
      const handlerA2 = () => {};
      const handlerB1 = () => {};

      registry.set(keyA1, handlerA1);
      registry.set(keyA2, handlerA2);
      registry.set(keyB1, handlerB1);

      const removed = registry.clearByDevice('device-a');

      expect(removed.length).assertEqual(2);
      expect(registry.size()).assertEqual(1);
      expect(registry.get(keyA1)).assertEqual(undefined);
      expect(registry.get(keyA2)).assertEqual(undefined);
      expect(registry.get(keyB1)).assertEqual(handlerB1);
    });

    it('should delete one key only', 0, () => {
      const registry: CharacteristicNotificationRegistry = new CharacteristicNotificationRegistry();
      const keyA: string = registry.buildKey('device-a', 'service-1', 'char-1');
      const keyB: string = registry.buildKey('device-a', 'service-1', 'char-2');

      registry.set(keyA, () => {});
      registry.set(keyB, () => {});
      registry.delete(keyA);

      expect(registry.size()).assertEqual(1);
      expect(registry.get(keyA)).assertEqual(undefined);
    });
  });
}
