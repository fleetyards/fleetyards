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

const contract = (kind = "procurement", items: unknown[] = []) =>
  ({ slug: "haul", kind, items }) as never;

const fleet = { slug: "black-sun" } as never;

let wrapper: VueWrapper | undefined;

afterEach(() => {
  wrapper?.unmount();
  wrapper = undefined;
});

const mount = async (kind?: string, items?: unknown[]) => {
  wrapper = await mountWithDefaults(Component, {
    props: { fleet, contract: contract(kind, items) },
  });

  return wrapper;
};

const startCreate = async (w: VueWrapper) => {
  await w.find("[data-test='add-item']").trigger("click");
  await w.vm.$nextTick();
};

describe("FleetContractsItemsForm", () => {
  it("lists the goods through the app's editable list", async () => {
    const w = await mount("procurement", [
      {
        id: "1",
        name: "Titanium",
        category: "commodity",
        unit: "scu",
        quantity: "12.0",
        quality: null,
        qualityMatch: "at_least",
      },
    ]);

    expect(w.findComponent({ name: "InlineEditableList" }).exists()).toBe(true);
    expect(w.text()).toContain("Titanium");
    expect(w.text()).toContain("12");
  });

  it("says how a quality is read rather than printing a bare number", async () => {
    const w = await mount("crafting", [
      {
        id: "1",
        name: "Ballistic Gatling",
        category: "weapon",
        unit: "piece",
        quantity: "2.0",
        quality: 600,
        qualityMatch: "exact",
      },
    ]);

    // "600" alone would leave a courier guessing whether better also passes.
    expect(w.text()).toMatch(/600/);
    expect(w.text()).not.toBe("600");
  });

  // A commodity is mined or bought, never crafted -- but everything else is,
  // so the exclusion has to stay an exclusion.
  it("offers every category but commodities while crafting", async () => {
    const w = await mount("crafting");
    await startCreate(w);

    const select = w
      .findAllComponents({ name: "BaseSelect" })
      .find((component) => component.props("name") === "create-item-category");
    const values = (select?.props("options") as { value: string }[]).map(
      (option) => option.value,
    );

    expect(values).toContain("component");
    expect(values).toContain("weapon");
    expect(values).toContain("ammunition");
    expect(values).not.toContain("commodity");
  });

  it("keeps commodities on offer when the contract is not crafting", async () => {
    const w = await mount("procurement");
    await startCreate(w);

    const select = w
      .findAllComponents({ name: "BaseSelect" })
      .find((component) => component.props("name") === "create-item-category");
    const values = (select?.props("options") as { value: string }[]).map(
      (option) => option.value,
    );

    expect(values).toContain("commodity");
  });

  // A Galant is filed as a `weapon`, so an equipment-typed filter would leave
  // it neither searchable nor scrollable to.
  it("does not filter the equipment catalogue while crafting", async () => {
    const w = await mount("crafting");
    await startCreate(w);

    const category = w
      .findAllComponents({ name: "BaseSelect" })
      .find((component) => component.props("name") === "create-item-category");
    await category?.vm.$emit("update:modelValue", "equipment");
    await w.vm.$nextTick();

    const picker = w.findComponent({ name: "LogisticsEquipmentPicker" });

    expect(picker.exists()).toBe(true);
    expect(picker.props("equipmentTypes")).toEqual([]);
  });

  it("narrows the equipment catalogue outside crafting", async () => {
    const w = await mount("procurement");
    await startCreate(w);

    const category = w
      .findAllComponents({ name: "BaseSelect" })
      .find((component) => component.props("name") === "create-item-category");
    await category?.vm.$emit("update:modelValue", "weapon");
    await w.vm.$nextTick();

    expect(
      w
        .findComponent({ name: "LogisticsEquipmentPicker" })
        .props("equipmentTypes"),
    ).toEqual(["weapon"]);
  });
});
