import { describe, expect, it } from "vitest";
import { mountWithDefaults } from "@/shared/utils/TestUtils";
import Component from "./index.vue";

describe("LoadingLine", () => {
  it("runs and announces itself while loading", async () => {
    const wrapper = await mountWithDefaults(Component, {
      props: { loading: true, label: "Loading Glacier" },
    });

    expect(wrapper.classes()).toContain("loading-line--active");
    expect(wrapper.find("[role='status']").text()).toBe("Loading Glacier");
  });

  it("keeps its live region mounted, and empty, while idle", async () => {
    const wrapper = await mountWithDefaults(Component, {
      props: { loading: false, label: "Loading Glacier" },
    });

    expect(wrapper.classes()).not.toContain("loading-line--active");
    expect(wrapper.find("[role='status']").exists()).toBe(true);
    expect(wrapper.find("[role='status']").text()).toBe("");
  });

  it("falls back to the generic loading text", async () => {
    const wrapper = await mountWithDefaults(Component, {
      props: { loading: true },
    });

    expect(wrapper.find("[role='status']").text()).not.toBe("");
  });

  it("runs along the edge it is given", async () => {
    const wrapper = await mountWithDefaults(Component, {
      props: { edge: "bottom" },
    });

    expect(wrapper.classes()).toContain("loading-line--bottom");
  });
});
