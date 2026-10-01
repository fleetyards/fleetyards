import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { mountWithDefaults } from "@/shared/utils/TestUtils";
import Component from "./index.vue";

const status = (wrapper: Awaited<ReturnType<typeof mountWithDefaults>>) =>
  wrapper.find("[role='status']").text();

describe("LoadingLine", () => {
  beforeEach(() => {
    vi.useFakeTimers();
  });

  afterEach(() => {
    vi.useRealTimers();
  });

  it("runs while loading, and announces itself a moment after it mounts", async () => {
    const wrapper = await mountWithDefaults(Component, {
      props: { loading: true, label: "Loading Glacier" },
    });

    expect(wrapper.classes()).toContain("loading-line--active");
    // Empty at first: a live region only announces text that changes after
    // it is already in the document, and this one mounted already loading.
    expect(status(wrapper)).toBe("");

    await vi.advanceTimersByTimeAsync(200);

    expect(status(wrapper)).toBe("Loading Glacier");
  });

  it("keeps its live region mounted, and empty, while idle", async () => {
    const wrapper = await mountWithDefaults(Component, {
      props: { loading: false, label: "Loading Glacier" },
    });
    await vi.advanceTimersByTimeAsync(200);

    expect(wrapper.classes()).not.toContain("loading-line--active");
    expect(wrapper.find("[role='status']").exists()).toBe(true);
    expect(status(wrapper)).toBe("");
  });

  it("says nothing for a load that ends before it is announced", async () => {
    const wrapper = await mountWithDefaults(Component, {
      props: { loading: true, label: "Loading Glacier" },
    });

    await wrapper.setProps({ loading: false });
    await vi.advanceTimersByTimeAsync(200);

    expect(status(wrapper)).toBe("");
  });

  it("falls back to the generic loading text", async () => {
    const wrapper = await mountWithDefaults(Component, {
      props: { loading: true },
    });
    await vi.advanceTimersByTimeAsync(200);

    expect(status(wrapper)).not.toBe("");
  });

  it("is a span, so it can sit inside a paragraph or a button", async () => {
    const wrapper = await mountWithDefaults(Component, {
      props: { edge: "bottom" },
    });

    expect(wrapper.element.tagName).toBe("SPAN");
    expect(wrapper.classes()).toContain("loading-line--bottom");
  });
});
