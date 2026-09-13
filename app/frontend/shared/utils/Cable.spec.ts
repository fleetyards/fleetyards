import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";

const createCable = vi.fn(() => ({ subscribe: vi.fn() }));

vi.mock("@anycable/web", () => ({ createCable }));

const loadGetCable = async () => {
  vi.resetModules();

  return (await import("./Cable")).getCable;
};

const setEndpoint = (endpoint?: string) => {
  if (endpoint === undefined) {
    delete (window as { CABLE_ENDPOINT?: string }).CABLE_ENDPOINT;

    return;
  }

  window.CABLE_ENDPOINT = endpoint;
};

beforeEach(() => {
  vi.spyOn(console, "info").mockImplementation(() => {});
  vi.spyOn(console, "warn").mockImplementation(() => {});
});

afterEach(() => {
  vi.restoreAllMocks();
  createCable.mockClear();
  createCable.mockImplementation(() => ({ subscribe: vi.fn() }));
  setEndpoint(undefined);
});

describe("getCable", () => {
  it("sets one cable up for the endpoint the layout published", async () => {
    setEndpoint("wss://fleetyards.test/cable");

    const getCable = await loadGetCable();

    expect(getCable()).toBe(getCable());
    expect(createCable).toHaveBeenCalledExactlyOnceWith(
      "wss://fleetyards.test/cable",
    );
  });

  it("skips the setup when no endpoint was published", async () => {
    setEndpoint(undefined);

    const getCable = await loadGetCable();

    expect(getCable()).toBeUndefined();
    expect(createCable).not.toHaveBeenCalled();
    expect(console.warn).toHaveBeenCalled();
  });

  it("skips the setup when the endpoint is not a URL", async () => {
    setEndpoint("/cable");

    const getCable = await loadGetCable();

    expect(getCable()).toBeUndefined();
    expect(createCable).not.toHaveBeenCalled();
    expect(console.warn).toHaveBeenCalled();
  });

  /*
   * A client that cannot have a cable at all -- no WebSocket to construct the
   * transport over -- still renders the page: live updates are an enhancement,
   * and 1,163 reports came from clients that could not open a socket.
   */
  it("renders on when the cable cannot be constructed", async () => {
    setEndpoint("wss://fleetyards.test/cable");
    createCable.mockImplementation(() => {
      throw new Error("No WebSocket support");
    });

    const getCable = await loadGetCable();

    expect(() => getCable()).not.toThrow();
    expect(getCable()).toBeUndefined();
    expect(console.warn).toHaveBeenCalled();
  });
});
