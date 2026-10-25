import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { config } from "@vue/test-utils";
import { mountWithDefaults } from "@/shared/utils/TestUtils";
import Component from "./index.vue";

const anchors = [
  { id: "radar", label: "Radar" },
  { id: "weapons", label: "Weapons" },
];

const mount = () =>
  mountWithDefaults(Component, { props: { anchors, activeId: "radar" } });

describe("TabNavViewMobileDropdown", () => {
  // jsdom has no scrollIntoView of its own; one is lent for the spy and taken
  // back after, so no later spec finds it.
  let lent = false;

  // The real transition, whose `after-enter` is when the panel is brought into
  // view; the default stub never fires it.
  const stubs = config.global.stubs;

  beforeEach(() => {
    config.global.stubs = { ...stubs, transition: false };
    if (!("scrollIntoView" in Element.prototype)) {
      Object.defineProperty(Element.prototype, "scrollIntoView", {
        value: () => {},
        configurable: true,
        writable: true,
      });
      lent = true;
    }
  });

  afterEach(() => {
    config.global.stubs = stubs;
    vi.restoreAllMocks();
    if (lent) {
      Reflect.deleteProperty(Element.prototype, "scrollIntoView");
      lent = false;
    }
  });

  it("brings the opened panel into view once it has settled", async () => {
    const scrollIntoView = vi
      .spyOn(Element.prototype, "scrollIntoView")
      .mockImplementation(() => {});
    const wrapper = await mount();

    await wrapper.find(".tab-nav-dropdown__trigger").trigger("click");

    expect(wrapper.find(".tab-nav-dropdown__panel").exists()).toBe(true);
    await vi.waitFor(() =>
      expect(scrollIntoView).toHaveBeenCalledWith({ block: "nearest" }),
    );

    wrapper.unmount();
  });

  it("does not scroll when the panel closes", async () => {
    const scrollIntoView = vi
      .spyOn(Element.prototype, "scrollIntoView")
      .mockImplementation(() => {});
    const wrapper = await mount();
    const trigger = wrapper.find(".tab-nav-dropdown__trigger");

    await trigger.trigger("click");
    await vi.waitFor(() => expect(scrollIntoView).toHaveBeenCalled());
    scrollIntoView.mockClear();
    await trigger.trigger("click");
    // Once the leave transition has run its course, which is where an enter
    // hook would have fired had it been wired to the wrong one.
    await vi.waitFor(() =>
      expect(wrapper.find(".tab-nav-dropdown__panel").exists()).toBe(false),
    );

    expect(scrollIntoView).not.toHaveBeenCalled();

    wrapper.unmount();
  });
});
