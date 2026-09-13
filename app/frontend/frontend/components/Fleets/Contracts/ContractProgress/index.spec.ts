import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { afterEach, describe, expect, it } from "vitest";
import type { VueWrapper } from "@vue/test-utils";
import {
  type FleetContractProgress,
  type FleetContractProgressLine,
  InventoryCategoryEnum,
  InventoryUnitEnum,
} from "@/services/fyApi";
import Component from "./index.vue";

const line = (
  overrides: Partial<FleetContractProgressLine> = {},
): FleetContractProgressLine => ({
  itemId: "11111111-1111-4111-8111-111111111111",
  name: "Titanium",
  category: InventoryCategoryEnum.COMMODITY,
  unit: InventoryUnitEnum.SCU,
  minQuality: null,
  requested: "800.0",
  delivered: "240.0",
  pickedUp: "0.0",
  remaining: "560.0",
  complete: false,
  fraction: 0.3,
  contributions: [],
  ...overrides,
});

const progress = (
  overrides: Partial<FleetContractProgress> = {},
): FleetContractProgress => ({
  complete: false,
  fraction: 0.3,
  lines: [line()],
  shares: [],
  ...overrides,
});

// A wrapper that is never unmounted leaves its pinia behind, and the next test
// then asserts against a second store and passes either way.
let wrapper: VueWrapper | undefined;

afterEach(() => {
  wrapper?.unmount();
  wrapper = undefined;
});

const mount = async (props: InstanceType<typeof Component>["$props"]) => {
  wrapper = await mountWithDefaults<typeof Component>(Component, { props });

  return wrapper;
};

describe("FleetContractsProgress", () => {
  it("renders one row per line", async () => {
    const subject = await mount({
      progress: progress({
        lines: [
          line(),
          line({ itemId: "22222222-2222-4222-8222-222222222222" }),
        ],
      }),
    });

    expect(
      subject.findAll("[data-test='contract-progress-line']"),
    ).toHaveLength(2);
  });

  it("labels the bar with the quantities, not the percentage", async () => {
    const subject = await mount({ progress: progress() });

    expect(subject.text()).toContain("240 / 800");
  });

  it("hides the pickup row unless the contract collects from somewhere", async () => {
    const subject = await mount({ progress: progress() });

    expect(subject.find(".contract-progress__pickup").exists()).toBe(false);
  });

  it("shows what is still in the courier's hold on a transport contract", async () => {
    const subject = await mount({
      progress: progress({ lines: [line({ pickedUp: "400.0" })] }),
      showPickup: true,
    });

    expect(subject.find(".contract-progress__pickup").text()).toContain("400");
  });

  it("shows the required grade when a line has one", async () => {
    const subject = await mount({
      progress: progress({ lines: [line({ minQuality: 500 })] }),
    });

    expect(subject.find(".contract-progress__quality").text()).toContain("500");
  });
});
