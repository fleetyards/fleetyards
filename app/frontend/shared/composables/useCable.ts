import { createConsumer } from "@rails/actioncable";
import type { Consumer } from "@rails/actioncable";

const setupConsumer = (): Consumer => {
  console.info("Subscriptions: Setup consumer on:", window.CABLE_ENDPOINT);

  return createConsumer(window.CABLE_ENDPOINT);
};

let consumer = setupConsumer();

export const useCable = () => {
  const refresh = () => {
    console.info("Subscriptions: Refresh consumer");

    consumer.disconnect();

    consumer = setupConsumer();
  };

  return {
    consumer,
    refresh,
  };
};
