import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { afterEach, describe, expect, it } from "vitest";
import type { VueWrapper } from "@vue/test-utils";
import { type ItemPickerEntry } from "@/frontend/components/Logistics/types";
import Component from "./index.vue";

let wrapper: VueWrapper | undefined;

afterEach(() => {
  wrapper?.unmount();
  wrapper = undefined;
});

const badges = async (entry: ItemPickerEntry) => {
  wrapper = await mountWithDefaults<typeof Component>(Component, {
    props: { entry },
  });

  return wrapper
    .findAll(".row-list-item__badge-value")
    .map((badge) => badge.text());
};

describe("LogisticsItemPickerRow", () => {
  // Every ore pod is size 1, so what tells them apart is what they hold. The
  // ROC's pods write it as `storage`.
  it("tells the ore pods apart by what they hold", async () => {
    expect(
      await badges({
        type: "Component",
        record: {
          id: "1",
          name: "MISC Ore Pod",
          size: 1,
          category: "ore_pods",
          typeData: { capacity: 8 },
        } as never,
      }),
    ).toEqual(["8 SCU"]);

    wrapper?.unmount();

    expect(
      await badges({
        type: "Component",
        record: {
          id: "2",
          name: "Greycat ROC Ore Pod",
          size: 1,
          category: "ore_pods",
          typeData: { storage: 1.2 },
        } as never,
      }),
    ).toEqual(["1.2 SCU"]);
  });

  it("labels every other component with its size", async () => {
    expect(
      await badges({
        type: "Component",
        record: {
          id: "3",
          name: "Bulwark",
          size: 1,
          category: "shieldgenerator",
        } as never,
      }),
    ).toEqual(["1"]);
  });

  // The pick button covers the row with no text of its own, so its name has
  // to say which of two same-named guns it picks.
  it("names the pick after what the row shows", async () => {
    wrapper = await mountWithDefaults<typeof Component>(Component, {
      props: {
        entry: {
          type: "Equipment",
          record: {
            id: "4",
            name: "Arrowhead",
            size: "3",
            manufacturer: { name: "Klaus & Werner" },
            itemTypeLabel: "Sniper Rifle",
          } as never,
        },
      },
    });

    expect(wrapper.find("button").attributes("aria-label")).toContain(
      "Klaus & Werner",
    );
    expect(wrapper.find("button").attributes("aria-label")).toContain(
      "Sniper Rifle",
    );
  });

  it("asks to be picked when clicked", async () => {
    wrapper = await mountWithDefaults<typeof Component>(Component, {
      props: {
        entry: {
          type: "Commodity",
          record: { id: "5", name: "Gold" } as never,
        },
      },
    });

    await wrapper.find("button").trigger("click");

    expect(wrapper.emitted("pick")).toHaveLength(1);
  });
});
