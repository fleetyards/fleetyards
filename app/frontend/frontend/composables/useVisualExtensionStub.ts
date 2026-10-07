import {
  FleetyardsSyncAction,
  FleetyardsSyncDirection,
  type FleetyardsSyncMessage,
} from "@/frontend/lib/FleetyardsSyncHandler";
import { overrideSyncExtension } from "@/frontend/composables/useSyncExtension";

export type ExtensionStubAnswer = { code: number; payload?: unknown };

// An action left out is never answered, the way a missing or older extension
// behaves: the page waits, then times out.
export type ExtensionStubConfig = Partial<
  Record<FleetyardsSyncAction, ExtensionStubAnswer>
>;

export const STUB_EXTENSION_VERSION = "9.9.9";

// The answers a current extension gives with an RSI session for `handle`.
export const signedInExtension = (handle: string): ExtensionStubConfig => ({
  [FleetyardsSyncAction.HEALTH]: {
    code: 200,
    payload: {
      version: STUB_EXTENSION_VERSION,
      actions: Object.values(FleetyardsSyncAction),
    },
  },
  [FleetyardsSyncAction.IDENTIFY]: { code: 200, payload: { handle } },
});

export const signedOutExtension = (): ExtensionStubConfig => ({
  ...signedInExtension(""),
  [FleetyardsSyncAction.IDENTIFY]: { code: 400 },
});

/*
 * Stands in for the FleetYards Sync extension on the visual test pages. Each
 * card configures the answers before it opens the real modal.
 *
 * Code that goes through `useSyncExtension` is answered in place, without a
 * message on `window`: an extension installed in the same browser hears every
 * message there -- the page cannot stop that, the content script listens in its
 * own world -- and would act on it. The hangar and buy-back sync modals still
 * post to `window` themselves; their requests only read, so the stub answers
 * them there and flags `realExtension` when an installed one answers too.
 */
export const useVisualExtensionStub = () => {
  let config: ExtensionStubConfig = {};

  // No-answer timers, so a card left behind cannot reject after the page.
  const timers = new Set<ReturnType<typeof setTimeout>>();

  const realExtension = ref(false);

  const answer = (action: FleetyardsSyncAction) => {
    const stubbed = config[action];

    return stubbed && { action, ...stubbed };
  };

  const onMessage = (event: MessageEvent) => {
    if (event.data?.direction === FleetyardsSyncDirection.TO) {
      if (!event.data.stub) realExtension.value = true;
      return;
    }

    if (event.source !== window) return;
    if (event.data?.direction !== FleetyardsSyncDirection.FROM) return;

    let action: FleetyardsSyncAction;
    try {
      action = JSON.parse(event.data.message).action;
    } catch {
      return;
    }
    const reply = answer(action);
    if (!reply) return;

    window.postMessage(
      {
        direction: FleetyardsSyncDirection.TO,
        message: JSON.stringify(reply),
        stub: true,
      },
      window.location.origin,
    );
  };

  onMounted(() => {
    window.addEventListener("message", onMessage);

    overrideSyncExtension(
      (action, _params, timeout) =>
        new Promise((resolve, reject) => {
          const reply = answer(action);
          if (reply) {
            resolve(reply as FleetyardsSyncMessage);
          } else {
            const timer = setTimeout(() => {
              timers.delete(timer);
              reject(new Error("no answer"));
            }, timeout);
            timers.add(timer);
          }
        }),
    );

    // Anything but the stub answering this is an installed extension.
    window.postMessage(
      {
        direction: FleetyardsSyncDirection.FROM,
        message: JSON.stringify({ action: FleetyardsSyncAction.HEALTH }),
      },
      window.location.origin,
    );
  });

  onBeforeUnmount(() => {
    window.removeEventListener("message", onMessage);
    overrideSyncExtension(undefined);
    timers.forEach(clearTimeout);
    timers.clear();
  });

  return {
    realExtension,
    configure: (next: ExtensionStubConfig) => {
      config = next;
    },
  };
};
