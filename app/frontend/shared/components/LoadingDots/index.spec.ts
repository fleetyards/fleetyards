import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { mountWithDefaults } from "@/shared/utils/TestUtils";
import Component from "./index.vue";

describe("LoadingDots", () => {
  beforeEach(() => {
    vi.useFakeTimers();
  });

  afterEach(() => {
    vi.useRealTimers();
  });

  it("shows three dots and announces itself while loading", async () => {
    const wrapper = await mountWithDefaults(Component, {
      props: { loading: true, label: "Loading the sync" },
    });

    expect(wrapper.findAll(".loading-dots__dot")).toHaveLength(3);
    await vi.advanceTimersByTimeAsync(200);
    expect(wrapper.find("[role='status']").text()).toBe("Loading the sync");
  });

  it("shows nothing, and keeps an empty live region, when idle", async () => {
    const wrapper = await mountWithDefaults(Component, {
      props: { loading: false },
    });
    await vi.advanceTimersByTimeAsync(200);

    expect(wrapper.find(".loading-dots__dots").exists()).toBe(false);
    expect(wrapper.find("[role='status']").text()).toBe("");
  });
});
