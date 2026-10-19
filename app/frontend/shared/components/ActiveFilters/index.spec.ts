import { describe, expect, it, vi } from "vitest";
import { mountWithDefaults } from "@/shared/utils/TestUtils";
import Component from "./index.vue";

const filters = () =>
  Array.from({ length: 8 }, (_, index) => ({
    id: String(index),
    label: `Filter ${index}`,
    remove: vi.fn(),
  }));

describe("ActiveFilters", () => {
  it("limits the toolbar to two chips and one overflow control", async () => {
    const wrapper = await mountWithDefaults(Component, {
      props: { filters: filters() },
    });
    expect(wrapper.findAll(".active-filters__chip")).toHaveLength(2);
    expect(
      wrapper.find(".active-filters__chip button").attributes("aria-pressed"),
    ).toBeUndefined();
    expect(wrapper.find(".active-filters__chip button").text()).toContain(
      "Remove Filter 0",
    );
    expect(wrapper.find(".active-filters__more").text()).toBe("+6 more");
    await wrapper.find(".active-filters__more button").trigger("click");
    expect(wrapper.emitted("open")).toHaveLength(1);
  });
  it("shows every filter in the panel and removes the selected filter", async () => {
    const items = filters();
    const wrapper = await mountWithDefaults(Component, {
      props: { filters: items, expanded: true },
    });
    expect(wrapper.findAll(".active-filters__chip")).toHaveLength(8);
    expect(wrapper.find(".active-filters__more").exists()).toBe(false);
    await wrapper.findAll(".active-filters__chip button")[5].trigger("click");
    expect(items[5].remove).toHaveBeenCalledOnce();
    expect(items[0].remove).not.toHaveBeenCalled();
  });
});
