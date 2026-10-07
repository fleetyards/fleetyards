import {
  FleetyardsSyncAction,
  type FleetyardsSyncMessage,
} from "@/frontend/lib/FleetyardsSyncHandler";
import {
  clearSyncExtensionOverride,
  overrideSyncExtension,
} from "@/frontend/composables/useSyncExtension";
import { useComlink } from "@/shared/composables/useComlink";

// For when the modal never reports back: closing takes a few hundred ms.
const MODAL_CLOSE_FALLBACK = 1000;

/*
 * A visual page's modal lives above the page, so leaving the page leaves it
 * open, and a demo it still runs would reach the real extension and API once
 * the page's stubs were gone. Leaving closes it (forced: the sync modals are
 * fixed) and tears down only once it is gone -- not later either: a stub still
 * in place would answer a real sync started elsewhere with demo data.
 */
export const onVisualPageLeave = (teardown: () => void) => {
  const comlink = useComlink();

  onBeforeUnmount(() => {
    let done = false;

    const finish = () => {
      if (done) return;
      done = true;
      unbind();
      clearTimeout(fallback);
      teardown();
    };

    const unbind = comlink.on("modal-closed", finish);
    const fallback = setTimeout(finish, MODAL_CLOSE_FALLBACK);

    comlink.emit("close-modal", true);
  });
};

export type ExtensionStubAnswer = { code: number; payload?: unknown };

// An answer, or one per request -- a sync is asked for page by page. An
// action left out, or a function returning nothing, is never answered, the
// way a missing or older extension behaves: the page waits, then times out.
export type ExtensionStubConfig = Partial<
  Record<
    FleetyardsSyncAction,
    | ExtensionStubAnswer
    | ((params: Record<string, unknown>) => ExtensionStubAnswer | undefined)
  >
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
 * Stands in for the FleetYards Sync extension on the visual test pages: every
 * request the page makes through `useSyncExtension` is answered here, in code.
 * Nothing goes over `window`, where an extension installed in the same browser
 * would hear it and act on it -- reading RSI, or writing a demo token into a
 * real RSI bio. Each card configures the answers before it opens the modal.
 */
export const useVisualExtensionStub = () => {
  let config: ExtensionStubConfig = {};

  // No-answer timers, so a card left behind cannot reject after the page.
  const timers = new Set<ReturnType<typeof setTimeout>>();

  const answer = (
    action: FleetyardsSyncAction,
    params: Record<string, unknown>,
  ) => {
    const stubbed = config[action];
    const reply = typeof stubbed === "function" ? stubbed(params) : stubbed;

    return reply && ({ action, ...reply } as FleetyardsSyncMessage);
  };

  const stub = (
    action: FleetyardsSyncAction,
    params: Record<string, unknown> = {},
    timeout = 0,
  ) =>
    new Promise<FleetyardsSyncMessage>((resolve, reject) => {
      const reply = answer(action, params);
      if (reply) {
        resolve(reply);
      } else {
        const timer = setTimeout(() => {
          timers.delete(timer);
          reject(new Error("no answer"));
        }, timeout);
        timers.add(timer);
      }
    });

  onMounted(() => overrideSyncExtension(stub));

  onVisualPageLeave(() => {
    clearSyncExtensionOverride(stub);
    timers.forEach(clearTimeout);
    timers.clear();
  });

  return {
    configure: (next: ExtensionStubConfig) => {
      config = next;
    },
  };
};
