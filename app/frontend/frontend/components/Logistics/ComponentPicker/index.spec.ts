import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { afterEach, describe, expect, it, vi } from "vitest";
import type { VueWrapper } from "@vue/test-utils";
import Component from "./index.vue";

vi.mock("@/services/fyApi", async (importOriginal) => ({
  ...(await importOriginal<typeof import("@/services/fyApi")>()),
  componentCategoriesFilters: vi.fn().mockResolvedValue([]),
  components: vi.fn().mockResolvedValue({ items: [] }),
}));

let wrapper: VueWrapper | undefined;

afterEach(() => {
  wrapper?.unmount();
  wrapper = undefined;
});

const labels = async (items: unknown[]) => {
  wrapper = await mountWithDefaults<typeof Component>(Component);

  const select = wrapper
    .findAllComponents({ name: "BaseSelect" })
    .find((candidate) => candidate.props("name") === "component");
  const format = select?.props("queryResponseFormatter") as (response: {
    items: unknown[];
  }) => { label: string }[];

  return format({ items }).map((option) => option.label);
};

describe("LogisticsComponentPicker", () => {
  it("tells the ore pods apart by what they hold", async () => {
    expect(
      await labels([
        {
          id: "1",
          name: "MISC Ore Pod",
          size: "1",
          category: "ore_pods",
          typeData: { capacity: 8 },
        },
        {
          id: "2",
          name: "Greycat ROC Ore Pod",
          size: "1",
          category: "ore_pods",
          typeData: { storage: 1.2 },
        },
      ]),
    ).toEqual(["MISC Ore Pod (8 SCU)", "Greycat ROC Ore Pod (1.2 SCU)"]);
  });

  it("labels every other component with its size", async () => {
    expect(
      await labels([
        { id: "3", name: "Bulwark", size: "1", category: "shieldgenerator" },
      ]),
    ).toEqual(["Bulwark (1)"]);
  });
});
