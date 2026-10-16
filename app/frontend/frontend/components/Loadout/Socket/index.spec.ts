import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { afterEach, describe, expect, it, vi } from "vitest";
import Component from "./index.vue";
import type { LoadoutSocketSlot } from "./types";

const EMPTY: LoadoutSocketSlot = { id: "left", label: "Left module slot" };

const FILLED: LoadoutSocketSlot = {
  ...EMPTY,
  size: "S3",
  item: { id: "tier-1", name: "Tier 1 Module Left", figure: "4 beds" },
};

const mount = (props: {
  socket: LoadoutSocketSlot;
  active?: boolean;
  editable?: boolean;
}) => mountWithDefaults(Component, { props });

describe("LoadoutSocket", () => {
  afterEach(() => {
    vi.useRealTimers();
  });

  it("names what it holds, its size and its figure", async () => {
    const wrapper = await mount({ socket: FILLED });

    expect(wrapper.text()).toContain("Left module slot");
    expect(wrapper.text()).toContain("S3");
    expect(wrapper.text()).toContain("Tier 1 Module Left");
    expect(wrapper.text()).toContain("4 beds");
    expect(wrapper.classes()).not.toContain("loadout-socket--empty");
  });

  it("reads as empty when nothing is fitted", async () => {
    const wrapper = await mount({ socket: EMPTY });

    expect(wrapper.classes()).toContain("loadout-socket--empty");
    expect(wrapper.find("[data-test='loadout-socket-name']").text()).toBe(
      "Empty",
    );
  });

  it("is a button that selects itself only while editable", async () => {
    const editable = await mount({ socket: EMPTY, editable: true });

    expect(editable.element.tagName).toBe("BUTTON");
    await editable.trigger("click");
    expect(editable.emitted("select")).toHaveLength(1);

    const readOnly = await mount({ socket: EMPTY });

    expect(readOnly.element.tagName).toBe("DIV");
    await readOnly.trigger("click");
    expect(readOnly.emitted("select")).toBeUndefined();
  });

  it("says it is the one being filled", async () => {
    const wrapper = await mount({
      socket: EMPTY,
      editable: true,
      active: true,
    });

    expect(wrapper.attributes("aria-pressed")).toBe("true");
    expect(wrapper.classes()).toContain("loadout-socket--active");
  });

  it("plays the fill when something new lands in it, then settles", async () => {
    vi.useFakeTimers();
    const wrapper = await mount({ socket: EMPTY, editable: true });

    await wrapper.setProps({ socket: FILLED });
    expect(wrapper.classes()).toContain("loadout-socket--filled");

    vi.advanceTimersByTime(800);
    await nextTick();
    expect(wrapper.classes()).not.toContain("loadout-socket--filled");
  });

  it("plays no fill when the socket is emptied", async () => {
    const wrapper = await mount({ socket: FILLED, editable: true });

    await wrapper.setProps({ socket: EMPTY });

    expect(wrapper.classes()).not.toContain("loadout-socket--filled");
  });
});
