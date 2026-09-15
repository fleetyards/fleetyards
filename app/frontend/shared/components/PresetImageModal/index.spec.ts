import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { afterEach, describe, expect, it, vi } from "vitest";
import type { VueWrapper } from "@vue/test-utils";
import Component from "./index.vue";

const emit = vi.fn();

vi.mock("@/shared/composables/useComlink", () => ({
  useComlink: () => ({ emit, on: () => () => undefined }),
}));

// jsdom reports a narrow viewport, and the chip row folds into a closed
// dropdown there -- no chip would be in the document at all.
vi.mock("@/shared/composables/useMobile", () => ({
  useMobile: () => false,
}));

let wrapper: VueWrapper | undefined;

const onSelect = vi.fn();

afterEach(() => {
  wrapper?.unmount();
  wrapper = undefined;
  emit.mockClear();
  onSelect.mockClear();
});

const mount = async (props: Record<string, unknown> = {}) => {
  wrapper = await mountWithDefaults(Component, {
    props: { catalogue: "missions", onSelect, ...props } as never,
  });

  return wrapper;
};

const tiles = (subject: VueWrapper) => subject.findAll(".preset-image");

describe("PresetImageModal", () => {
  it("opens on the record's own type", async () => {
    const subject = await mount({ group: "mining" });

    expect(tiles(subject).length).toBeGreaterThan(0);
    expect(subject.find("[data-test='preset-image-mining']").exists()).toBe(
      true,
    );
    expect(
      subject.find("[data-test='preset-image-exploration']").exists(),
    ).toBe(false);
  });

  /*
   * The whole point of the chips: the art filed under a category is a starting
   * point, not a restriction. A salvage job set at a mining site wants the
   * mining picture.
   */
  it("offers every other type one chip away", async () => {
    const subject = await mount({ group: "mining" });

    // The chip's frame carries the marker; the control inside it is the button.
    await subject
      .find("[data-test='preset-group-exploration'] button")
      .trigger("click");

    expect(
      subject.find("[data-test='preset-image-exploration']").exists(),
    ).toBe(true);
    expect(subject.find("[data-test='preset-image-mining']").exists()).toBe(
      false,
    );
  });

  it("shows everything when no type is given", async () => {
    const all = tiles(await mount());
    wrapper?.unmount();

    const mining = tiles(await mount({ group: "mining" }));

    expect(all.length).toBeGreaterThan(mining.length);
  });

  // A kind with no art of its own would otherwise open on an empty grid.
  it("shows everything when the type it opens on carries no art", async () => {
    const subject = await mount({ catalogue: "contracts", group: "transport" });

    expect(tiles(subject).length).toBeGreaterThan(0);
  });

  it("hands the choice back and closes", async () => {
    const subject = await mount({ group: "mining" });

    await subject.find("[data-test='preset-image-mining']").trigger("click");

    expect(onSelect).toHaveBeenCalledWith("mining");
    expect(emit).toHaveBeenCalledWith("close-modal");
  });

  it("offers a way back to no picture at all, and only once there is one", async () => {
    const without = await mount({ group: "mining" });
    expect(without.find("[data-test='preset-image-remove']").exists()).toBe(
      false,
    );
    wrapper?.unmount();

    const subject = await mount({ group: "mining", selected: "mining" });
    await subject.find("[data-test='preset-image-remove']").trigger("click");

    expect(onSelect).toHaveBeenCalledWith(null);
  });

  // An inventory picture is not "of" anything, so there is nothing to narrow by.
  it("renders no filter for a catalogue that is not divided", async () => {
    const subject = await mount({ catalogue: "inventories" });

    expect(subject.find(".chip-row").exists()).toBe(false);
    expect(tiles(subject).length).toBeGreaterThan(0);
  });
});
