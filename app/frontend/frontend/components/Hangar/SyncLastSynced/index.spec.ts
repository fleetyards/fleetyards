import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import Component from "./index.vue";

describe("HangarSyncLastSynced", () => {
  beforeEach(() => {
    vi.useFakeTimers();
    vi.setSystemTime(new Date("2026-10-19T12:00:00Z"));
  });

  afterEach(() => {
    vi.useRealTimers();
  });

  it("keeps the age current while it stays on screen", async () => {
    const wrapper = await mountWithDefaults<typeof Component>(Component, {
      props: { finishedAt: "2026-10-19T11:59:50Z" },
    });

    expect(wrapper.get("time").text()).toBe("less than a minute ago");

    await vi.advanceTimersByTimeAsync(3 * 60_000);

    expect(wrapper.get("time").text()).toBe("3 minutes ago");
  });

  it("shows nothing without a last sync", async () => {
    const wrapper = await mountWithDefaults<typeof Component>(Component, {
      props: { finishedAt: null },
    });

    expect(wrapper.find("[data-test='sync-last-synced']").exists()).toBe(false);
  });
});
