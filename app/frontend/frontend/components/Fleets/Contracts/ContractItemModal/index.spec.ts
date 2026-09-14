import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { afterEach, beforeAll, describe, expect, it, vi } from "vitest";
import type { VueWrapper } from "@vue/test-utils";
import { defineRule } from "vee-validate";
import { required, min, min_value } from "@vee-validate/rules";
import Component from "./index.vue";

// The form's fields carry vee-validate rule names. Without them registered
// every mount throws "No such validator" as an unhandled error, which fails
// the run even when the assertions pass. Registered here one by one rather
// than through the app's `setupRules`, which reaches for a pinia store.
beforeAll(() => {
  defineRule("required", required);
  defineRule("min", min);
  defineRule("min_value", min_value);
});

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

const existingItem = {
  id: "line-1",
  name: "Quantanium",
  category: "commodity",
  unit: "scu",
  quantity: "42.0",
  quality: 500,
  qualityMatch: "exact",
  item: null,
} as never;

let wrapper: VueWrapper | undefined;

afterEach(() => {
  wrapper?.unmount();
  wrapper = undefined;
});

const mount = async (kind?: string, item?: unknown) => {
  wrapper = await mountWithDefaults<typeof Component>(Component, {
    props: {
      fleet: { slug: "test-fleet" } as never,
      contract: contract(kind),
      item: item as never,
    },
  });

  return wrapper;
};

describe("FleetContractsItemModal", () => {
  // The grade belongs to the goods, not to crafting — every kind can ask for one.
  it("offers the grade on a contract that is not crafting", async () => {
    const subject = await mount("procurement");

    expect(subject.find("[data-test='input-itemQuality']").exists()).toBe(true);
  });

  // As an affix inside the number field the selector read as the field's
  // value, which is the number's job -- it is a choice about the grade, so it
  // is offered as one.
  it("offers the match as a choice beside the grade, not inside it", async () => {
    const subject = await mount();

    expect(subject.find(".base-input__prefix").exists()).toBe(false);
    expect(subject.find("[data-test='quality-match-at_least']").exists()).toBe(
      true,
    );
    expect(subject.find("[data-test='quality-match-exact']").exists()).toBe(
      true,
    );
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

  // A line that was entered wrongly has to be fixable; before this the only
  // repair was deleting it and asking again.
  it("opens on an existing line with its values filled in", async () => {
    const subject = await mount("procurement", existingItem);

    const name = subject.find("[data-test='input-itemName']")
      .element as HTMLInputElement;
    const quantity = subject.find("[data-test='input-itemQuantity']")
      .element as HTMLInputElement;

    expect(name.value).toBe("Quantanium");
    expect(quantity.value).toBe("42");
  });

  it("asks for a quantity and its unit", async () => {
    const subject = await mount();

    expect(subject.find("[data-test='input-itemQuantity']").exists()).toBe(
      true,
    );
  });
});
