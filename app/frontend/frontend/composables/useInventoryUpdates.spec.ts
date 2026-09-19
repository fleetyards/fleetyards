import { mount } from "@vue/test-utils";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { REFRESH_WAIT_MS } from "@/shared/composables/useDebouncedRefresh";
import { createPinia, setActivePinia } from "pinia";
import { useSessionStore } from "@/frontend/stores/session";

type Handler = {
  channel: { identifier?: string; name?: string };
  received?: (change: unknown) => void;
  connected?: (event: { reconnect?: boolean }) => void;
};

const handlers: Handler[] = [];

vi.mock("@/shared/composables/useSubscription", () => ({
  useSubscription: (options: Handler) => {
    handlers.push(options);

    return {};
  },
}));

// A real pinia rather than a mocked one: `storeToRefs` is handed the store
// itself, and the module graph behind the session store defines others of its
// own -- mocking the package takes `defineStore` out from under them.
vi.mock("@/frontend/composables/useFeatures", () => ({
  useFeatures: () => ({ isFeatureEnabled: () => true }),
}));

const { useInventoryUpdates } = await import("./useInventoryUpdates");

const HANGAR_PING = { inventoryId: "one", inventorySlug: "refinery" };
const FLEET_PING = {
  inventoryId: "two",
  inventorySlug: "refinery",
  fleetSlug: "acme",
};

// A component, because the composable hangs its debounce off the surrounding
// scope and subscribes on mount.
const render = (
  refresh: () => unknown,
  options?: Parameters<typeof useInventoryUpdates>[1],
) =>
  mount(
    defineComponent({
      setup() {
        useInventoryUpdates(refresh, options);

        return () => h("div");
      },
    }),
  );

const receive = (change: unknown) =>
  handlers.forEach((handler) => handler.received?.(change));

beforeEach(() => {
  vi.useFakeTimers();
  handlers.length = 0;
  setActivePinia(createPinia());
  useSessionStore().authenticated = true;
});

afterEach(() => {
  vi.useRealTimers();
});

describe("useInventoryUpdates", () => {
  it("subscribes to both the hangar and the fleet channel", () => {
    render(vi.fn());

    expect(handlers).toHaveLength(2);
  });

  it("refreshes when an inventory changes", () => {
    const refresh = vi.fn();

    render(refresh);
    receive(HANGAR_PING);

    expect(refresh).not.toHaveBeenCalled();

    vi.advanceTimersByTime(REFRESH_WAIT_MS);

    expect(refresh).toHaveBeenCalledOnce();
  });

  it("collapses a burst into one refresh", () => {
    const refresh = vi.fn();

    render(refresh);
    receive(HANGAR_PING);
    receive(HANGAR_PING);
    receive(HANGAR_PING);
    vi.advanceTimersByTime(REFRESH_WAIT_MS);

    expect(refresh).toHaveBeenCalledOnce();
  });

  // The filter runs before the debounce. Applied after it, a burst spanning
  // two fleets would collapse to whichever ping landed last, and a page
  // watching the other one would never hear about its own change.
  it("ignores a change the filter rejects, even in the same burst", () => {
    const refresh = vi.fn();

    render(refresh, { filter: (change) => change.fleetSlug === "acme" });

    receive(FLEET_PING);
    receive({ ...FLEET_PING, fleetSlug: "other" });
    vi.advanceTimersByTime(REFRESH_WAIT_MS);

    expect(refresh).toHaveBeenCalledOnce();
  });

  it("does not refresh when every change is filtered out", () => {
    const refresh = vi.fn();

    render(refresh, { filter: (change) => change.fleetSlug === "acme" });

    receive(HANGAR_PING);
    vi.advanceTimersByTime(REFRESH_WAIT_MS);

    expect(refresh).not.toHaveBeenCalled();
  });

  // Nothing broadcast while the socket was down is replayed, so a resubscribe
  // has to resync. A first connect must not: the page has just loaded.
  it("refreshes on a reconnect but not on the first connect", () => {
    const refresh = vi.fn();

    render(refresh);

    handlers.forEach((handler) => handler.connected?.({ reconnect: false }));
    vi.advanceTimersByTime(REFRESH_WAIT_MS);

    expect(refresh).not.toHaveBeenCalled();

    handlers.forEach((handler) => handler.connected?.({ reconnect: true }));
    vi.advanceTimersByTime(REFRESH_WAIT_MS);

    expect(refresh).toHaveBeenCalledOnce();
  });
});
