import { flushPromises } from "@vue/test-utils";
import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { describe, expect, it, vi } from "vitest";
import { ref } from "vue";
import { BlueprintCraftableTypeEnum } from "@/services/fyApi";
import Component from "./index.vue";

const RECIPE = {
  id: "bp",
  slug: "bp-armor",
  costSlots: [
    {
      position: 0,
      name: "Plating",
      options: [],
      modifiers: [
        {
          propertyKey: "gpp_armor_damagemitigation",
          name: "Damage Reduction",
          ramp: "linear",
          startQuality: 0,
          endQuality: 1000,
          modifierAtStart: 0.9,
          modifierAtEnd: 1.1,
          baseValue: 30,
        },
      ],
    },
  ],
};

let recipesParams: () => Record<string, unknown> = () => ({});

vi.mock("@/services/fyApi", async (importOriginal) => ({
  ...(await importOriginal<Record<string, unknown>>()),
  useBlueprints: (params: () => Record<string, unknown>) => {
    recipesParams = params;
    return {
      data: ref({ items: [{ id: "bp", slug: "bp-armor" }] }),
      isPending: ref(false),
    };
  },
  useBlueprint: () => ({ data: ref(RECIPE), isPending: ref(false) }),
}));

vi.mock("@/frontend/composables/useMaterialStock", () => ({
  useMaterialStock: () => ({
    forCommodity: () => ({ own: [], fleet: [] }),
  }),
  useMaterialStockUpdates: () => undefined,
}));

vi.mock("@/shared/composables/useI18n", () => ({
  useI18n: () => ({
    t: (key: string) => key,
    tExists: () => false,
    toNumber: (value: number) => String(value),
  }),
}));

const mount = (props: Record<string, unknown> = {}) =>
  mountWithDefaults(Component, {
    props: {
      title: "Torso",
      item: { id: "armor", name: "Field Armor", slug: "field-armor" },
      craftableType: BlueprintCraftableTypeEnum.EQUIPMENT,
      ...props,
    },
  });

describe("BlueprintCrafter", () => {
  it("looks the recipes up in the item's own catalogue", async () => {
    await mount();
    await flushPromises();

    expect(recipesParams()).toEqual({
      q: {
        craftableTypeEq: BlueprintCraftableTypeEnum.EQUIPMENT,
        craftableIdEq: "armor",
      },
    });
  });

  it("applies the draft it was set to, and nothing before", async () => {
    const wrapper = await mount();
    await flushPromises();

    await wrapper
      .get("[data-test='blueprint-crafter-slots'] input[type='number']")
      .setValue("1000");
    await flushPromises();

    expect(wrapper.emitted("apply")).toBeUndefined();
    expect(
      wrapper
        .get("[data-test='blueprint-crafter-stat-gpp_armor_damagemitigation']")
        .text(),
    ).toContain("+10.0%");

    await wrapper.get("[data-test='blueprint-crafter-apply']").trigger("click");

    expect(wrapper.emitted("apply")).toEqual([
      [
        {
          blueprintId: "bp",
          blueprintSlug: "bp-armor",
          qualities: { 0: 1000 },
        },
      ],
    ]);
  });

  it("offers Remove only for an item already crafted, and leaves the caller's crafting alone", async () => {
    const crafted = {
      blueprintId: "bp",
      blueprintSlug: "bp-armor",
      qualities: { 0: 250 },
    };
    const wrapper = await mount({ crafted });
    await flushPromises();

    await wrapper
      .get("[data-test='blueprint-crafter-slots'] input[type='number']")
      .setValue("900");
    await wrapper
      .get("[data-test='blueprint-crafter-remove']")
      .trigger("click");

    expect(wrapper.emitted("remove")).toHaveLength(1);
    expect(crafted.qualities).toEqual({ 0: 250 });

    const fresh = await mount();
    await flushPromises();
    expect(fresh.find("[data-test='blueprint-crafter-remove']").exists()).toBe(
      false,
    );
  });
});
