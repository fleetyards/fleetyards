import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { afterEach, describe, expect, it, vi } from "vitest";
import type { VueWrapper } from "@vue/test-utils";
import Component from "./index.vue";

// The pickers fetch their catalogues on mount, which is not what this is about.
vi.mock("@/frontend/components/Logistics/CommodityPicker/index.vue", () => ({
  default: { name: "LogisticsCommodityPicker", render: () => null },
}));
vi.mock("@/frontend/components/Logistics/ComponentPicker/index.vue", () => ({
  default: { name: "LogisticsComponentPicker", render: () => null },
}));
vi.mock("@/frontend/components/Logistics/EquipmentPicker/index.vue", () => ({
  default: { name: "LogisticsEquipmentPicker", render: () => null },
}));

const contract = (kind = "procurement") =>
  ({ slug: "haul", kind, items: [] }) as never;

let wrapper: VueWrapper | undefined;

afterEach(() => {
  wrapper?.unmount();
  wrapper = undefined;
});

const mount = async (kind?: string) => {
  wrapper = await mountWithDefaults<typeof Component>(Component, {
    props: { fleet: { slug: "test-fleet" } as never, contract: contract(kind) },
  });

  return wrapper;
};

describe("FleetContractsItemModal", () => {
  // The grade belongs to the goods, not to crafting — every kind can ask for one.
  it("offers the grade on a contract that is not crafting", async () => {
    const subject = await mount("procurement");

    expect(subject.find("[data-test='input-itemQuality']").exists()).toBe(true);
  });

  // FormInput wraps its suffix slot but not its prefix slot, so an unwrapped
  // affix select is unconstrained and takes the whole field — the number input
  // then has nowhere to render.
  it("keeps the number field beside the match selector", async () => {
    const subject = await mount();

    const prefix = subject.find(".base-input__prefix");

    expect(prefix.exists()).toBe(true);
    expect(prefix.findComponent({ name: "BaseSelect" }).exists()).toBe(true);
    expect(subject.find("[data-test='input-itemQuality']").exists()).toBe(true);
  });

  it("asks for a quantity and its unit", async () => {
    const subject = await mount();

    expect(subject.find("[data-test='input-itemQuantity']").exists()).toBe(
      true,
    );
  });
});
