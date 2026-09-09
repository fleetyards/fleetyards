import { afterEach, describe, expect, it, vi } from "vitest";

const create = vi.fn();
let consumer: unknown = { subscriptions: { create } };

vi.mock("@/shared/composables/useCable", () => ({
  useCable: () => ({ consumer, refresh: vi.fn() }),
}));

const { useSubscription } = await import("./useSubscription");

afterEach(() => {
  vi.restoreAllMocks();
  create.mockReset();
  consumer = { subscriptions: { create } };
});

describe("useSubscription", () => {
  it("subscribes to the channel it was given", () => {
    create.mockReturnValue({ unsubscribe: vi.fn() });

    const { subscribe, channel } = useSubscription({
      channelName: "ShipsChannel",
    });

    subscribe();

    expect(create).toHaveBeenCalledWith(
      { channel: "ShipsChannel" },
      expect.objectContaining({ connected: expect.any(Function) }),
    );
    expect(channel.value).toBeDefined();
  });

  /*
   * actioncable opens the WebSocket synchronously inside `create`, so a client
   * that cannot open one -- a proxy rewriting the URL, a policy blocking wss --
   * throws out of here. Nine components subscribe on mount; none of them should
   * fail to render because live updates are unavailable.
   */
  it("survives a socket the client cannot open", () => {
    vi.spyOn(console, "warn").mockImplementation(() => {});
    create.mockImplementation(() => {
      throw new SyntaxError(
        "Failed to construct 'WebSocket': the provided URL is invalid.",
      );
    });

    const { subscribe, channel } = useSubscription({
      channelName: "ShipsChannel",
    });

    expect(() => subscribe()).not.toThrow();
    expect(channel.value).toBeUndefined();
    expect(console.warn).toHaveBeenCalled();
  });

  it("does nothing when there is no consumer at all", () => {
    consumer = undefined;

    const { subscribe, channel } = useSubscription({
      channelName: "ShipsChannel",
    });

    expect(() => subscribe()).not.toThrow();
    expect(create).not.toHaveBeenCalled();
    expect(channel.value).toBeUndefined();
  });
});
