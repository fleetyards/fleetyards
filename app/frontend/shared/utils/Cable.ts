import { createCable } from "@anycable/web";
import type { Cable } from "@anycable/web";

const cableUrl = (): string | undefined => {
  if (!window.CABLE_ENDPOINT) {
    console.warn("Subscriptions: CABLE_ENDPOINT not set, skipping cable setup");
    return undefined;
  }

  try {
    new URL(window.CABLE_ENDPOINT);
  } catch {
    console.warn(
      "Subscriptions: CABLE_ENDPOINT is not a valid URL:",
      window.CABLE_ENDPOINT,
    );
    return undefined;
  }

  return window.CABLE_ENDPOINT;
};

const setupCable = (): Cable | undefined => {
  const url = cableUrl();

  if (!url) {
    return undefined;
  }

  console.info("Subscriptions: Setup cable on:", url);

  try {
    // `createCable` opens no socket -- it is lazy, and the first subscription
    // connects -- but it does construct the transport, which needs a WebSocket
    // implementation to exist at all. Live updates are an enhancement, so a
    // client that has none renders without them.
    return createCable(url);
  } catch (error) {
    console.warn("Subscriptions: could not set up the cable", error);

    return undefined;
  }
};

let cable: Cable | undefined;
let setupAttempted = false;

// One cable for the whole app: both cable documents describe the same
// connection, and every channel multiplexes over that one socket.
export const getCable = (): Cable | undefined => {
  if (!setupAttempted) {
    setupAttempted = true;
    cable = setupCable();
  }

  return cable;
};
