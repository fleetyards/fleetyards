import {
  FleetyardsSyncAction,
  FleetyardsSyncDirection,
  type FleetyardsSyncHealthPayload,
  type FleetyardsSyncMessage,
} from "@/frontend/lib/FleetyardsSyncHandler";

// Without the extension nothing ever answers, so the health check gives up
// quickly. Anything that goes to RSI gets longer.
const HEALTH_TIMEOUT = 2000;
const REQUEST_TIMEOUT = 30000;

// `matches` tells this request's answer from a late one to an earlier request
// of the same action that already timed out.
type SyncExtensionRequest = (
  action: FleetyardsSyncAction,
  params?: Record<string, unknown>,
  timeout?: number,
  matches?: (message: FleetyardsSyncMessage) => boolean,
) => Promise<FleetyardsSyncMessage>;

let requestOverride: SyncExtensionRequest | undefined;

// For the visual test pages, which answer for the extension themselves. They
// cannot do that over `window`: an extension installed in the same browser
// hears every message there, answers too, and acts on what it is asked -- a
// demo card's `verify-write` would land in the tester's real RSI bio.
export const overrideSyncExtension = (request: SyncExtensionRequest) => {
  requestOverride = request;
};

// Only the override it installed: a page removing its own late must not take
// out the next page's.
export const clearSyncExtensionOverride = (request: SyncExtensionRequest) => {
  if (requestOverride === request) requestOverride = undefined;
};

// Any script on the page can post into this channel, answers included. That is
// fine for what the answers are used for here: what the UI offers. Nothing the
// extension reports is proof of anything to the server.
export const useSyncExtension = () => {
  const request: SyncExtensionRequest = (
    action,
    params = {},
    timeout = REQUEST_TIMEOUT,
    matches = () => true,
  ) => {
    if (requestOverride) {
      return requestOverride(action, params, timeout, matches);
    }

    return new Promise<FleetyardsSyncMessage>((resolve, reject) => {
      const onMessage = (event: MessageEvent) => {
        if (event.source !== window) return;
        if (event.data?.direction !== FleetyardsSyncDirection.TO) return;

        let message: FleetyardsSyncMessage;
        try {
          message = JSON.parse(event.data.message);
        } catch {
          return;
        }
        if (message.action !== action || !matches(message)) return;

        cleanup();
        resolve(message);
      };

      const timer = setTimeout(() => {
        cleanup();
        reject(new Error(`FY Extension: no answer to ${action}`));
      }, timeout);

      const cleanup = () => {
        clearTimeout(timer);
        window.removeEventListener("message", onMessage);
      };

      window.addEventListener("message", onMessage);
      window.postMessage(
        {
          direction: FleetyardsSyncDirection.FROM,
          message: JSON.stringify({ action, ...params }),
        },
        window.location.origin,
      );
    });
  };

  // Undefined when nothing answers: no extension installed.
  const health = () =>
    request(FleetyardsSyncAction.HEALTH, {}, HEALTH_TIMEOUT).catch(
      () => undefined,
    );

  // An extension from before an action existed answers it with "Unknown
  // Action", so the health check's list is asked instead.
  const supports = async (action: FleetyardsSyncAction) => {
    const answer = await health();
    const actions = (answer?.payload as FleetyardsSyncHealthPayload)?.actions;

    return answer?.code === 200 && !!actions?.includes(action);
  };

  return { request, health, supports };
};
