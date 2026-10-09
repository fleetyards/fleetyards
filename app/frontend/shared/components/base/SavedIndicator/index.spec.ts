import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import Component from "./index.vue";

describe("SavedIndicator", () => {
  beforeEach(() => {
    vi.useFakeTimers();
  });

  afterEach(() => {
    vi.useRealTimers();
  });

  it("shows the label on demand and hides it again", async () => {
    const wrapper = await mountWithDefaults(Component);

    expect(wrapper.text()).toBe("");

    (wrapper.vm as unknown as { show: () => void }).show();
    await nextTick();
    expect(wrapper.find(".saved-indicator__label").exists()).toBe(true);

    vi.advanceTimersByTime(2000);
    await nextTick();
    expect(wrapper.find(".saved-indicator__label").exists()).toBe(false);
  });
});
