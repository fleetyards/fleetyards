import { flushPromises } from "@vue/test-utils";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { DisconnectedError } from "@anycable/core";
import { createCable, type Channel } from "@anycable/web";
import { AppVersionChannel } from "@/services/fyCable/channels/AppVersionChannel";

let subscribed: Channel | undefined;
let disconnect: ReturnType<typeof vi.spyOn> | undefined;

const subscribe = vi.fn((channel: Channel) => {
  subscribed = channel;
  disconnect = vi.spyOn(channel, "disconnect");

  return channel;
});

let cable: { subscribe: (channel: Channel) => Channel } | undefined = {
  subscribe,
};

vi.mock("@/shared/utils/Cable", () => ({
  getCable: () => cable,
}));

const { useSubscription } = await import("./useSubscription");

beforeEach(() => {
  vi.spyOn(console, "info").mockImplementation(() => {});
});

afterEach(() => {
  vi.restoreAllMocks();
  subscribe.mockClear();
  subscribed = undefined;
  disconnect = undefined;
  cable = { subscribe };
});

describe("useSubscription", () => {
  it("subscribes to the channel it was given", () => {
    const { subscribe: start, channel } = useSubscription({
      channel: AppVersionChannel,
    });

    start();

    expect(subscribe).toHaveBeenCalledOnce();
    expect(subscribed).toBeInstanceOf(AppVersionChannel);
    expect(channel.value).toBe(subscribed);
  });

  it("hands the payload the channel declares to the receiver", () => {
    const received = vi.fn();

    const { subscribe: start } = useSubscription({
      channel: AppVersionChannel,
      received,
    });

    start();

    subscribed?.emit("message", { version: "7.15.0", codename: "Arrow" });

    expect(received).toHaveBeenCalledWith({
      version: "7.15.0",
      codename: "Arrow",
    });
  });

  /*
   * anycable reopens the socket by itself and resubscribes every channel it
   * still holds -- returning to a backgrounded tab is enough to trigger it.
   * Dropping the subscription when the socket goes down takes it out of that
   * set, and the channel stays quiet for good.
   */
  it("keeps the subscription when the socket drops", () => {
    const disconnected = vi.fn();

    const { subscribe: start } = useSubscription({
      channel: AppVersionChannel,
      disconnected,
    });

    start();

    subscribed?.emit("disconnect", new DisconnectedError("no connection"));

    expect(disconnected).toHaveBeenCalled();
    expect(disconnect).not.toHaveBeenCalled();
  });

  /*
   * The channel replays nothing, so a consumer that has to catch up on what it
   * missed needs to tell a resubscribe from the first connect.
   */
  it("reports whether a connect is a reconnect", () => {
    const connected = vi.fn();

    const { subscribe: start } = useSubscription({
      channel: AppVersionChannel,
      connected,
    });

    start();

    subscribed?.emit("connect", { reconnect: true, restored: false });

    expect(connected).toHaveBeenCalledWith({
      reconnect: true,
      restored: false,
    });
  });

  it("drops the subscription on unsubscribe", () => {
    const {
      subscribe: start,
      unsubscribe,
      channel,
    } = useSubscription({
      channel: AppVersionChannel,
    });

    start();

    unsubscribe();

    expect(disconnect).toHaveBeenCalled();
    expect(channel.value).toBeUndefined();
  });

  /*
   * The socket opens on the first subscription rather than when the cable is
   * built, so this is where a client that cannot open one -- a proxy rewriting
   * the URL, a policy blocking wss -- used to take the mount down with it.
   * 1,163 reports came from clients in that state.
   */
  it("survives a socket the client cannot open", async () => {
    vi.spyOn(console, "error").mockImplementation(() => {});
    vi.spyOn(console, "warn").mockImplementation(() => {});

    const attempted = vi.fn();

    class UnopenableWebSocket {
      constructor() {
        attempted();

        throw new SyntaxError(
          "Failed to construct 'WebSocket': the provided URL is invalid.",
        );
      }
    }

    const realCable = createCable("wss://fleetyards.test/cable", {
      websocketImplementation: UnopenableWebSocket,
      monitor: false,
    });

    cable = realCable;

    const { subscribe: start, channel } = useSubscription({
      channel: AppVersionChannel,
    });

    expect(() => start()).not.toThrow();

    await flushPromises();

    expect(attempted).toHaveBeenCalled();
    expect(channel.value).toBeDefined();

    realCable.disconnect();
  });

  /*
   * Live updates are an enhancement: a client that cannot have a cable at all
   * -- no endpoint, no WebSocket -- still renders the page.
   */
  it("does nothing when there is no cable at all", () => {
    cable = undefined;

    const { subscribe: start, channel } = useSubscription({
      channel: AppVersionChannel,
    });

    expect(() => start()).not.toThrow();
    expect(subscribe).not.toHaveBeenCalled();
    expect(channel.value).toBeUndefined();
  });
});
