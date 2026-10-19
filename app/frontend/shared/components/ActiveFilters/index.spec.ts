import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { mountWithDefaults } from "@/shared/utils/TestUtils";
import Component from "./index.vue";

const filters = () =>
  Array.from({ length: 8 }, (_, index) => ({
    id: String(index),
    label: `Filter ${index}`,
    remove: vi.fn(),
  }));

// jsdom has no layout: the row is 500px, a chip 100px and the overflow chip
// 60px, so four chips and the overflow chip fit.
const stubWidths = () => {
  vi.spyOn(HTMLElement.prototype, "clientWidth", "get").mockImplementation(
    function (this: HTMLElement) {
      return this.classList.contains("active-filters") ? 500 : 0;
    },
  );
  vi.spyOn(HTMLElement.prototype, "offsetWidth", "get").mockImplementation(
    function (this: HTMLElement) {
      if (this.classList.contains("active-filters__chip")) return 100;
      if (this.classList.contains("active-filters__more")) return 60;
      return 0;
    },
  );
};

describe("ActiveFilters", () => {
  beforeEach(stubWidths);
  afterEach(() => {
    vi.restoreAllMocks();
  });

  it("shows as many chips as fit the row and one overflow control", async () => {
    const wrapper = await mountWithDefaults(Component, {
      props: { filters: filters() },
    });
    await nextTick();
    expect(
      wrapper.findAll(".active-filters > .active-filters__chip"),
    ).toHaveLength(4);
    expect(
      wrapper
        .find(".active-filters > .active-filters__chip button")
        .attributes("aria-pressed"),
    ).toBeUndefined();
    expect(
      wrapper.find(".active-filters > .active-filters__chip button").text(),
    ).toContain("Remove Filter 0");
    expect(wrapper.find(".active-filters > .active-filters__more").text()).toBe(
      "+4 more",
    );
    await wrapper
      .find(".active-filters > .active-filters__more button")
      .trigger("click");
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
