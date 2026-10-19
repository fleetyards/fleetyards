import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { afterEach, beforeAll, describe, expect, it, vi } from "vitest";
import { flushPromises, type VueWrapper } from "@vue/test-utils";
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

// The picker fetches its catalogues, which is not what this is about.
vi.mock("@/frontend/components/Logistics/ItemPicker/index.vue", () => ({
  default: {
    name: "LogisticsItemPicker",
    // Declared so they arrive as props rather than falling through.
    props: {
      category: { type: String, default: undefined },
      categories: { type: Array, default: undefined },
    },
    emits: ["select"],
    render: () => null,
  },
}));

// A recipe makes the Bulwark and nothing else.
vi.mock("@/services/fyApi", async (importOriginal) => {
  const { computed } = await import("vue");

  return {
    ...(await importOriginal<typeof import("@/services/fyApi")>()),
    useBlueprints: (params: { value: { q: { craftableIdEq?: string } } }) => ({
      isPlaceholderData: computed(() => false),
      data: computed(() => ({
        items:
          params.value.q.craftableIdEq === "bulwark"
            ? [{ id: "bp-1", name: "Bulwark Blueprint", slug: "bulwark-bp" }]
            : [],
        meta: {},
      })),
    }),
  };
});

// The step's own page is specced on its own.
vi.mock("@/frontend/components/Logistics/CraftingStep/index.vue", () => ({
  default: {
    name: "LogisticsCraftingStep",
    props: {
      modelValue: { type: Object, default: undefined },
      item: { type: Object, default: undefined },
      optional: { type: Boolean, default: false },
    },
    emits: ["update:modelValue", "valid"],
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

const mount = async (
  kind?: string,
  item?: unknown,
  onDraft?: (values: unknown) => void,
) => {
  wrapper = await mountWithDefaults<typeof Component>(Component, {
    props: {
      fleet: { slug: "test-fleet" } as never,
      contract: onDraft ? undefined : contract(kind),
      kind: (kind ?? "procurement") as never,
      item: item as never,
      onDraft: onDraft as never,
    },
  });

  return wrapper;
};

const pickCommodity = async (subject: VueWrapper) => {
  await subject.find("[data-test='item-picker-field-open']").trigger("click");
  subject.findComponent({ name: "LogisticsItemPicker" }).vm.$emit("select", {
    item: { type: "Commodity", id: "quantanium", name: "Quantanium" },
    name: "Quantanium",
    category: "commodity",
  });
  await flushPromises();
};

describe("FleetContractsItemModal", () => {
  // Only raw resources carry a grade, and nothing does before it is named.
  it("offers the grade on a resource line", async () => {
    const subject = await mount("procurement");

    expect(subject.find("[data-test='input-itemQuality']").exists()).toBe(
      false,
    );

    await pickCommodity(subject);

    expect(subject.find("[data-test='input-itemQuality']").exists()).toBe(true);
  });

  // FormInput wraps its suffix slot but not its prefix slot, so an unwrapped
  // affix select is unconstrained and takes the whole field -- the number then
  // has nowhere to render.
  it("keeps the number field beside the match selector", async () => {
    const subject = await mount();

    await pickCommodity(subject);

    const prefix = subject.find(".base-input__prefix");

    expect(prefix.exists()).toBe(true);
    expect(prefix.findComponent({ name: "BaseSelect" }).exists()).toBe(true);
    expect(subject.find("[data-test='input-itemQuality']").exists()).toBe(true);
  });

  const pickerCategories = async (kind: string) => {
    const subject = await mount(kind);

    await subject.find("[data-test='item-picker-field-open']").trigger("click");

    return subject
      .findComponent({ name: "LogisticsItemPicker" })
      .props("categories") as string[];
  };

  // You cannot craft a commodity — those are mined, bought or hauled — so the
  // catalogue offers everything the ledger knows except that.
  it("offers only craftable categories on a crafting contract", async () => {
    expect(await pickerCategories("crafting")).toEqual([
      "component",
      "weapon",
      "equipment",
      "ammunition",
      "consumable",
      "other",
    ]);
  });

  it("offers every category on a contract that is not crafting", async () => {
    expect(await pickerCategories("procurement")).toContain("commodity");
  });

  // The catalogue takes the form's place instead of opening a modal of its
  // own, which would throw this form away.
  it("keeps what was typed while the catalogue is open", async () => {
    const subject = await mount();

    await subject.find("[data-test='input-itemQuantity']").setValue("7");
    await subject.find("[data-test='item-picker-field-open']").trigger("click");

    expect(subject.find("form").attributes("style")).toContain("display: none");

    await subject.find("[data-test='item-picker-back']").trigger("click");

    expect(subject.find("form").attributes("style") ?? "").not.toContain(
      "display: none",
    );
    expect(
      (
        subject.find("[data-test='input-itemQuantity']")
          .element as HTMLInputElement
      ).value,
    ).toBe("7");
  });

  // A rifle the ledger records as `weapon` must be asked for as `weapon`, or
  // Progress will never match it -- so the line takes the category the item
  // was picked under.
  it("files a pick under the category it was found in", async () => {
    const subject = await mount("crafting");

    await subject.find("[data-test='item-picker-field-open']").trigger("click");
    subject.findComponent({ name: "LogisticsItemPicker" }).vm.$emit("select", {
      item: { type: "Equipment", id: "galant", name: "Galant Rifle" },
      name: "Galant Rifle",
      category: "weapon",
    });
    await flushPromises();

    expect(
      subject.findComponent({ name: "LogisticsItemPicker" }).exists(),
    ).toBe(false);
    const field = subject.find("[data-test='item-picker-field-catalogueItem']");

    expect(field.text()).toContain("Galant Rifle");
    expect(field.text()).toContain("Weapon");
    // Only raw resources carry a grade.
    expect(subject.find("[data-test='input-itemQuality']").exists()).toBe(
      false,
    );
  });

  // A line that was entered wrongly has to be fixable; before this the only
  // repair was deleting it and asking again.
  it("opens on an existing line with its values filled in", async () => {
    const subject = await mount("procurement", existingItem);

    const field = subject.find("[data-test='item-picker-field-catalogueItem']");
    const quantity = subject.find("[data-test='input-itemQuantity']")
      .element as HTMLInputElement;

    expect(field.text()).toContain("Quantanium");
    expect(quantity.value).toBe("42");
  });

  it("asks for a quantity and its unit", async () => {
    const subject = await mount();

    expect(subject.find("[data-test='input-itemQuantity']").exists()).toBe(
      true,
    );
  });

  describe("a crafted part", () => {
    const pickBulwark = async (subject: VueWrapper) => {
      await subject
        .find("[data-test='item-picker-field-open']")
        .trigger("click");
      subject
        .findComponent({ name: "LogisticsItemPicker" })
        .vm.$emit("select", {
          item: { type: "Component", id: "bulwark", name: "Bulwark" },
          name: "Bulwark",
          category: "component",
        });
      await flushPromises();
    };

    it("asks for the recipe and the grades the step names", async () => {
      const onDraft = vi.fn();
      const subject = await mount("crafting", undefined, onDraft);

      await pickBulwark(subject);
      await subject
        .find("[data-test='item-picker-field-craft']")
        .trigger("click");

      const step = subject.findComponent({ name: "LogisticsCraftingStep" });

      // A request may leave a slot open.
      expect(step.props("optional")).toBe(true);

      step.vm.$emit("update:modelValue", {
        blueprintId: "bp-1",
        qualities: { 1: 700, 2: undefined },
      });
      step.vm.$emit("valid", true);
      await flushPromises();
      await subject.find("[data-test='crafting-apply']").trigger("click");

      expect(
        subject.find("[data-test='input-wrapper-itemQuantity']").exists(),
      ).toBe(true);

      await subject.find("[data-test='input-itemQuantity']").setValue("2");
      await subject.find("form").trigger("submit");
      await flushPromises();

      expect(onDraft).toHaveBeenCalledWith(
        expect.objectContaining({
          itemId: "bulwark",
          craftedBlueprintId: "bp-1",
          craftedQualities: { 1: 700 },
        }),
        expect.anything(),
      );
    });

    // A slot typed into and cleared again is a slot left open.
    it("names no grade for a slot left open", async () => {
      const subject = await mount("crafting", undefined, vi.fn());

      await pickBulwark(subject);
      await subject
        .find("[data-test='item-picker-field-craft']")
        .trigger("click");

      const step = subject.findComponent({ name: "LogisticsCraftingStep" });

      step.vm.$emit("update:modelValue", {
        blueprintId: "bp-1",
        qualities: { 1: undefined },
      });
      step.vm.$emit("valid", true);
      await flushPromises();
      await subject.find("[data-test='crafting-apply']").trigger("click");

      const field = subject.find(
        "[data-test='item-picker-field-catalogueItem']",
      );

      expect(field.text()).toContain("Crafted");
      expect(field.text()).not.toContain("undefined");
    });

    it("opens on a crafted line with its crafting", async () => {
      const subject = await mount("crafting", {
        id: "line-2",
        name: "Bulwark",
        category: "component",
        unit: "units",
        quantity: "2",
        qualityMatch: "at_least",
        item: { id: "bulwark", type: "Component", name: "Bulwark" },
        crafted: {
          blueprint: {
            id: "bp-1",
            name: "Bulwark Blueprint",
            slug: "bulwark-bp",
          },
          qualities: { 1: 700 },
        },
      });

      expect(
        subject.find("[data-test='item-picker-field-catalogueItem']").text(),
      ).toContain("Crafted 700");
    });

    // An edit that drops the crafting must clear it, not leave it be.
    it("sends no crafting for a plain line", async () => {
      const onDraft = vi.fn();
      const subject = await mount("crafting", undefined, onDraft);

      await pickBulwark(subject);
      await subject.find("[data-test='input-itemQuantity']").setValue("2");
      await subject.find("form").trigger("submit");
      await flushPromises();

      expect(onDraft).toHaveBeenCalledWith(
        expect.objectContaining({
          craftedBlueprintId: null,
          craftedQualities: null,
        }),
        expect.anything(),
      );
    });
  });
});
