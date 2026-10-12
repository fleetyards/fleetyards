import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { createApp } from "vue";
import { createPinia, setActivePinia } from "pinia";
import piniaPluginPersistedstate from "pinia-plugin-persistedstate";
import { useFleetStore } from "./fleet";

const DAY = 24 * 60 * 60 * 1000;

describe("fleet store tours", () => {
  beforeEach(() => {
    setActivePinia(createPinia());
    vi.useFakeTimers();
  });

  afterEach(() => {
    vi.useRealTimers();
  });

  it("keeps a queued tour per account and fleet", () => {
    const store = useFleetStore();

    store.queueTour("user-a", "fleet-1");

    expect(store.isTourPending("user-a", "fleet-1")).toBe(true);
    expect(store.isTourPending("user-b", "fleet-1")).toBe(false);
    expect(store.isTourPending("user-a", "fleet-2")).toBe(false);
  });

  it("clears only the tour it was asked to", () => {
    const store = useFleetStore();

    store.queueTour("user-a", "fleet-1");
    store.queueTour("user-a", "fleet-2");
    store.clearTour("user-a", "fleet-1");

    expect(store.isTourPending("user-a", "fleet-1")).toBe(false);
    expect(store.isTourPending("user-a", "fleet-2")).toBe(true);
  });

  it("lets a tour lapse after a week and drops it with the next queue", () => {
    const store = useFleetStore();

    store.queueTour("user-a", "fleet-1");
    vi.advanceTimersByTime(8 * DAY);

    expect(store.isTourPending("user-a", "fleet-1")).toBe(false);

    store.queueTour("user-a", "fleet-2");

    expect(Object.keys(store.pendingTours)).toEqual(["user-a:fleet-2"]);
  });

  it("drops lapsed tours when one is cleared as well", () => {
    const store = useFleetStore();

    store.queueTour("user-a", "fleet-1");
    vi.advanceTimersByTime(8 * DAY);
    store.queueTour("user-a", "fleet-2");
    vi.advanceTimersByTime(8 * DAY);

    store.clearTour("user-a", "fleet-3");

    expect(store.pendingTours).toEqual({});
  });
});

describe("fleet store persisted money toggles", () => {
  const activatePersistence = () => {
    const pinia = createPinia();
    pinia.use(piniaPluginPersistedstate);
    createApp({}).use(pinia);
    setActivePinia(pinia);
  };

  beforeEach(() => {
    localStorage.clear();
  });

  it("keeps the in-game total hidden for a visitor who hid both before", () => {
    localStorage.setItem("fleet", JSON.stringify({ money: false }));

    activatePersistence();

    expect(useFleetStore().money).toBe(false);
    expect(useFleetStore().credits).toBe(false);
  });

  it("keeps a stored in-game choice", () => {
    localStorage.setItem(
      "fleet",
      JSON.stringify({ money: false, credits: true }),
    );

    activatePersistence();

    expect(useFleetStore().credits).toBe(true);
  });
});
