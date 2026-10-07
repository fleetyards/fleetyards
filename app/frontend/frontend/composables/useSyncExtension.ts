import {
  FleetyardsSyncAction,
  FleetyardsSyncDirection,
  type FleetyardsSyncMessage,
} from "@/frontend/lib/FleetyardsSyncHandler";

// Without the extension nothing ever answers, so the health check gives up
// quickly. Anything that goes to RSI gets longer.
const HEALTH_TIMEOUT = 2000;
const REQUEST_TIMEOUT = 30000;

// Any script on the page can post into this channel, answers included. That is
// fine for what the answers are used for here: what the UI offers. Nothing the
// extension reports is proof of anything to the server.
export const useSyncExtension = () => {
  const request = (
    action: FleetyardsSyncAction,
    params: Record<string, unknown> = {},
    timeout = REQUEST_TIMEOUT,
  ) =>
    new Promise<FleetyardsSyncMessage>((resolve, reject) => {
      const onMessage = (event: MessageEvent) => {
        if (event.source !== window) return;
        if (event.data?.direction !== FleetyardsSyncDirection.TO) return;

        let message: FleetyardsSyncMessage;
        try {
          message = JSON.parse(event.data.message);
        } catch {
          return;
        }
        if (message.action !== action) return;

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

  // An extension from before an action existed answers it with "Unknown
  // Action", so the health check's list is asked instead.
  const supports = async (action: FleetyardsSyncAction) => {
    try {
      const health = await request(
        FleetyardsSyncAction.HEALTH,
        {},
        HEALTH_TIMEOUT,
      );

      return health.code === 200 && !!health.actions?.includes(action);
    } catch {
      return false;
    }
  };

  return { request, supports };
};
