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
  default: {
    name: "LogisticsEquipmentPicker",
    // Declared so the filter arrives as a prop rather than falling through.
    props: { equipmentTypes: { type: Array, default: undefined } },
    render: () => null,
  },
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

  // You cannot craft a commodity — those are mined, bought or hauled.
  it("offers only craftable categories on a crafting contract", async () => {
    const subject = await mount("crafting");

    const options = subject
      .findComponent({ name: "BaseSelect" })
      .props("options") as { value: string }[];

    // Everything the ledger knows except commodity: that is the only thing you
    // cannot craft.
    expect(options.map((option) => option.value)).not.toContain("commodity");
    expect(options.map((option) => option.value)).toEqual([
      "component",
      "weapon",
      "equipment",
      "ammunition",
      "consumable",
      "other",
    ]);
  });

  it("offers every category on a contract that is not crafting", async () => {
    const subject = await mount("procurement");

    const options = subject
      .findComponent({ name: "BaseSelect" })
      .props("options") as { value: string }[];

    expect(options.map((option) => option.value)).toContain("commodity");
  });

  // The picker is unfiltered while crafting, so the stored category has to come
  // from the pick — a rifle the ledger records as `weapon` must be asked for as
  // `weapon` or Progress will never match it.
  // A Galant is a `weapon`: under an "Equipment" filtered to armour and tools it
  // could be neither searched for nor scrolled to.
  it("offers the whole equipment catalogue while crafting", async () => {
    const subject = await mount("crafting");

    subject
      .findComponent({ name: "BaseSelect" })
      .vm.$emit("update:modelValue", "equipment");
    await subject.vm.$nextTick();

    const picker = subject.findComponent({ name: "LogisticsEquipmentPicker" });

    expect(picker.exists()).toBe(true);
    // Unfiltered — an armour-and-tools filter is what hid the rifles.
    expect(picker.props("equipmentTypes")).toEqual([]);
  });

  it("asks for a quantity and its unit", async () => {
    const subject = await mount();

    expect(subject.find("[data-test='input-itemQuantity']").exists()).toBe(
      true,
    );
  });
});
