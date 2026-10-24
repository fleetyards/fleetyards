import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { mountWithDefaults } from "@/shared/utils/TestUtils";
import Component from "./index.vue";

const anchors = [
  { id: "radar", label: "Radar" },
  { id: "weapons", label: "Weapons" },
];

describe("TabNavViewMobileDropdown", () => {
  // jsdom does not lay anything out, so it has no scrollIntoView of its own.
  beforeEach(() => {
    if (!("scrollIntoView" in Element.prototype)) {
      Object.defineProperty(Element.prototype, "scrollIntoView", {
        value: () => {},
        configurable: true,
        writable: true,
      });
    }
  });

  afterEach(() => {
    vi.restoreAllMocks();
  });

  it("brings the opened panel into view", async () => {
    const scrollIntoView = vi
      .spyOn(Element.prototype, "scrollIntoView")
      .mockImplementation(() => {});

    const wrapper = await mountWithDefaults(Component, {
      props: { anchors, activeId: "radar" },
    });

    await wrapper.find(".tab-nav-dropdown__trigger").trigger("click");
    await nextTick();

    expect(wrapper.find(".tab-nav-dropdown__panel").exists()).toBe(true);
    expect(scrollIntoView).toHaveBeenCalledWith({ block: "nearest" });

    wrapper.unmount();
  });

  it("does not scroll when the panel closes", async () => {
    const scrollIntoView = vi
      .spyOn(Element.prototype, "scrollIntoView")
      .mockImplementation(() => {});

    const wrapper = await mountWithDefaults(Component, {
      props: { anchors, activeId: "radar" },
    });
    const trigger = wrapper.find(".tab-nav-dropdown__trigger");

    await trigger.trigger("click");
    await nextTick();
    scrollIntoView.mockClear();
    await trigger.trigger("click");
    await nextTick();

    expect(scrollIntoView).not.toHaveBeenCalled();

    wrapper.unmount();
  });
});
