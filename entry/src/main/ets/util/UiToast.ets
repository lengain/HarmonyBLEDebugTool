import { promptAction } from '@kit.ArkUI';
import Logger from './Logger';

export class UiToast {
  private static lastMessage: string = '';
  private static lastShownAt: number = 0;

  public static show(message: string): void {
    const normalized: string = message.trim();
    if (normalized.length === 0) {
      return;
    }

    const now: number = Date.now();
    if (normalized === UiToast.lastMessage && now - UiToast.lastShownAt < 1500) {
      return;
    }

    UiToast.lastMessage = normalized;
    UiToast.lastShownAt = now;
    try {
      promptAction.showToast({
        message: normalized,
        duration: 2000
      });
    } catch (err) {
      Logger.warn('Show toast failed');
    }
  }
}
