import { describe, expect, it } from "vitest";
import { mountWithDefaults } from "@/shared/utils/TestUtils";
import {
  RowListItemTonesEnum,
  type RowListItemBadge,
  type RowListItemChip,
  type RowListItemTag,
} from "@/shared/components/RowListItem/types";
import Component from "./index.vue";

const CHIP = ".row-list-item__chip";
const CHIP_MORE = ".row-list-item__chip-more";
const NAME = ".row-list-item__name";
const TAG = ".row-list-item__tag";
const BADGE = ".row-list-item__badge";

const chips = (count: number): RowListItemChip[] =>
  Array.from({ length: count }, (_, index) => ({
    key: `chip-${index}`,
    label: `Chip ${index}`,
    to: { name: "home" },
  }));

const mount = async (props: Record<string, unknown> = {}) =>
  mountWithDefaults(Component, {
    props,
    slots: { name: () => [h("span", "Some record")] },
  });

describe("RowListItem", () => {
  it("links the name where the record has a route", async () => {
    const wrapper = await mount({ to: { name: "home" } });

    expect(wrapper.find(`a${NAME}`).exists()).toBe(true);
    expect(wrapper.find(NAME).text()).toBe("Some record");
  });

  // A record the game never named has no slug and so no route, and
  // `router-link` throws on a missing required param rather than rendering
  // nothing -- which took a whole catalogue list down once.
  it("leaves the name plain where it has none", async () => {
    const wrapper = await mount();

    expect(wrapper.find(`a${NAME}`).exists()).toBe(false);
    expect(wrapper.find(NAME).text()).toBe("Some record");
  });

  describe("chips", () => {
    it("shows every chip up to the cap, and no counter", async () => {
      const wrapper = await mount({ chips: chips(4) });

      expect(wrapper.findAll(CHIP)).toHaveLength(4);
      expect(wrapper.find(CHIP_MORE).exists()).toBe(false);
    });

    // The counter is the whole point of the cap: a 320px clip used to cut both
    // the fourth chip and the `+N` that said how many more there were, so a
    // reader saw a short list with nothing to suggest it was short.
    it("counts the rest once past the cap", async () => {
      const wrapper = await mount({ chips: chips(7) });

      expect(wrapper.findAll(CHIP)).toHaveLength(4);
      expect(wrapper.find(CHIP_MORE).text()).toBe("+3");
    });

    it("takes a cap of its own", async () => {
      const wrapper = await mount({ chips: chips(5), chipsMax: 2 });

      expect(wrapper.findAll(CHIP)).toHaveLength(2);
      expect(wrapper.find(CHIP_MORE).text()).toBe("+3");
    });

    it("renders a chip with no route as plain text", async () => {
      const wrapper = await mount({
        chips: [{ key: "solo", label: "Corundum" }] as RowListItemChip[],
      });

      expect(wrapper.find(`a${CHIP}`).exists()).toBe(false);
      expect(wrapper.find(CHIP).text()).toBe("Corundum");
    });
  });

  describe("tags", () => {
    it("paints a tag with the tone it was given", async () => {
      const wrapper = await mount({
        tags: [
          {
            key: "lawful",
            label: "Lawful",
            tone: RowListItemTonesEnum.PRIMARY,
          },
          { key: "outlaw", label: "Outlaw", tone: RowListItemTonesEnum.DANGER },
        ] as RowListItemTag[],
      });

      const [lawful, outlaw] = wrapper.findAll(TAG);

      expect(lawful.classes()).toContain("row-list-item__tag--primary");
      expect(outlaw.classes()).toContain("row-list-item__tag--danger");
    });

    it("falls back to the default tone", async () => {
      const wrapper = await mount({
        tags: [{ key: "neutral", label: "Neutral" }] as RowListItemTag[],
      });

      expect(wrapper.find(TAG).classes()).toContain(
        "row-list-item__tag--default",
      );
    });
  });

  describe("badges", () => {
    it("names the figure it is showing", async () => {
      const wrapper = await mount({
        badges: [
          { key: "size", label: "Size", value: "3" },
        ] as RowListItemBadge[],
      });

      expect(wrapper.find(".row-list-item__badge-label").text()).toBe("Size");
      expect(wrapper.find(".row-list-item__badge-value").text()).toBe("3");
    });

    // A state rather than a figure -- "no known source", "unreleased" -- has
    // nothing to name, and a solid badge would read as a measurement.
    it("marks a state badge quiet and leaves its label off", async () => {
      const wrapper = await mount({
        badges: [
          { key: "unreleased", value: "Unreleased", quiet: true },
        ] as RowListItemBadge[],
      });

      expect(wrapper.find(BADGE).classes()).toContain(
        "row-list-item__badge--quiet",
      );
      expect(wrapper.find(".row-list-item__badge-label").exists()).toBe(false);
    });
  });

  // Each of these is a whole section of the row, and an empty one would draw
  // its own gap in the flex line.
  it("draws nothing for a section it was given nothing for", async () => {
    const wrapper = await mount();

    expect(wrapper.find(".row-list-item__chips").exists()).toBe(false);
    expect(wrapper.find(".row-list-item__tags").exists()).toBe(false);
    expect(wrapper.find(".row-list-item__badges").exists()).toBe(false);
    expect(wrapper.find(".row-list-item__actions").exists()).toBe(false);
  });
});
