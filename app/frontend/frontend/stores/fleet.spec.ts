import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { createPinia, setActivePinia } from "pinia";
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
});
