import { createConsumer } from "@rails/actioncable";
import type { Consumer } from "@rails/actioncable";

const setupConsumer = (): Consumer => {
  console.info("Subscriptions: Setup consumer on:", window.CABLE_ENDPOINT);

  return createConsumer(window.CABLE_ENDPOINT);
};

export const useCable = () => {
  let consumer = setupConsumer();

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
