import { createConsumer } from "@rails/actioncable";
import type { Consumer } from "@rails/actioncable";

const setupConsumer = (): Consumer | undefined => {
  if (!window.CABLE_ENDPOINT) {
    console.warn(
      "Subscriptions: CABLE_ENDPOINT not set, skipping consumer setup",
    );
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

  console.info("Subscriptions: Setup consumer on:", window.CABLE_ENDPOINT);

  return createConsumer(window.CABLE_ENDPOINT);
};

let consumer = setupConsumer();

export const useCable = () => {
  if (!consumer) {
    consumer = setupConsumer();
  }

  const refresh = () => {
    console.info("Subscriptions: Refresh consumer");

    consumer?.disconnect();

    consumer = setupConsumer();
  };

  return {
    consumer,
    refresh,
  };
};
