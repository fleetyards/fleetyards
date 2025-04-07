import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { describe, expect, it } from "vitest";
import Component from "@/docs/components/core/AppFooter/index.vue";

describe("AppFooter", async () => {
  it("renders", async () => {
    const wrapper = await mountWithDefaults<typeof Component>(Component);
    expect(wrapper.exists()).toBe(true);
  });

  it("renders all links", async () => {
    const wrapper = await mountWithDefaults<typeof Component>(Component);
    expect(wrapper.findAll("a")).toHaveLength(8);
  });
});
