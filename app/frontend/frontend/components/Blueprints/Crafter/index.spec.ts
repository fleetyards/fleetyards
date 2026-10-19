import { flushPromises } from "@vue/test-utils";
import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { describe, expect, it, vi } from "vitest";
import { reactive, ref } from "vue";
import { BlueprintCraftableTypeEnum } from "@/services/fyApi";
import Component from "./index.vue";

const RECIPE = {
  id: "bp",
  slug: "bp-armor",
  costSlots: [
    // Moves nothing: a record has no grade to state for it.
    { position: 1, name: "Binding", options: [], modifiers: [] },
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
      .get(
        "[data-test='blueprint-crafter-slots'] .blueprint-slot:last-child input[type='number']",
      )
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

  it("states the neutral grade for a slot a record leaves untouched", async () => {
    const wrapper = await mount();
    await flushPromises();

    await wrapper.get("[data-test='blueprint-crafter-apply']").trigger("click");

    expect(wrapper.emitted("apply")).toEqual([
      [{ blueprintId: "bp", blueprintSlug: "bp-armor", qualities: { 0: 500 } }],
    ]);
  });

  it("leaves a request's untouched slot open, and clears a set one back to any", async () => {
    const wrapper = await mount({ openSlots: true });
    await flushPromises();

    const number = () =>
      wrapper.get(
        "[data-test='blueprint-crafter-slots'] .blueprint-slot:last-child input[type='number']",
      );
    expect((number().element as HTMLInputElement).value).toBe("");

    await number().setValue("800");
    await flushPromises();
    await wrapper.get("[data-test='blueprint-slot-clear']").trigger("click");
    await flushPromises();
    await wrapper.get("[data-test='blueprint-crafter-apply']").trigger("click");

    expect(wrapper.emitted("apply")).toEqual([
      [{ blueprintId: "bp", blueprintSlug: "bp-armor", qualities: {} }],
    ]);
  });

  it("leaves its frame and actions to a host it is embedded in", async () => {
    const wrapper = await mount({ embedded: true });
    await flushPromises();

    expect(wrapper.find("[data-test='blueprint-crafter-close']").exists()).toBe(
      false,
    );
    expect(wrapper.find("[data-test='blueprint-crafter-apply']").exists()).toBe(
      false,
    );

    await wrapper.get("[data-test='blueprint-crafter']").trigger("keydown", {
      key: "Escape",
    });
    expect(wrapper.emitted("close")).toBeUndefined();

    const exposed = wrapper.vm as unknown as {
      canApply: boolean;
      apply: () => void;
    };
    expect(exposed.canApply).toBe(true);
    exposed.apply();

    expect(wrapper.emitted("apply")).toHaveLength(1);
  });

  it("opens on a crafting whose grades are reactive", async () => {
    const crafted = {
      blueprintId: "bp",
      blueprintSlug: "bp-armor",
      qualities: reactive({ 0: 250 }),
    };
    const wrapper = await mount({ crafted });
    await flushPromises();

    (wrapper.vm as unknown as { apply: () => void }).apply();

    expect(wrapper.emitted("apply")?.[0][0]).toMatchObject({
      qualities: { 0: 250 },
    });
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
