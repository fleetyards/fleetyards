import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { describe, expect, it } from "vitest";
import { h } from "vue";
import Component from "./index.vue";

describe("VehicleTabLayout", () => {
  it("renders the content and the side column", async () => {
    const wrapper = await mountWithDefaults(Component, {
      slots: {
        default: () => [h("p", "content")],
        side: () => [h("p", "side")],
      },
    });

    expect(wrapper.find(".vehicle-tab-layout__main").text()).toBe("content");
    expect(wrapper.find(".vehicle-tab-layout__side").text()).toBe("side");
  });
});
