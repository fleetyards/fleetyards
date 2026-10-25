import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { flushPromises, type VueWrapper } from "@vue/test-utils";
import {
  commodities as fetchCommodities,
  components as fetchComponents,
  equipment as fetchEquipment,
  equipmentItemTypesFilters,
  equipmentSlotsFilters,
} from "@/services/fyApi";
import Component from "./index.vue";

const page = (items: unknown[]) => ({
  items,
  meta: {
    pagination: { currentPage: 1, totalPages: 1, totalCount: items.length },
  },
});

vi.mock("@/services/fyApi", async (importOriginal) => ({
  ...(await importOriginal<typeof import("@/services/fyApi")>()),
  componentCategoriesFilters: vi.fn().mockResolvedValue([]),
  commodityTypesFilters: vi.fn().mockResolvedValue([]),
  equipmentItemTypesFilters: vi.fn().mockResolvedValue([]),
  equipmentSlotsFilters: vi
    .fn()
    .mockResolvedValue([
      { category: "slot", label: "Helmet", value: "helmet" },
    ]),
  components: vi.fn(),
  commodities: vi.fn(),
  equipment: vi.fn(),
}));

let wrapper: VueWrapper | undefined;

beforeEach(() => {
  vi.mocked(fetchComponents).mockResolvedValue(
    page([
      {
        id: "bulwark",
        name: "Bulwark",
        size: 1,
        category: "shieldgenerator",
      },
    ]) as never,
  );
  vi.mocked(fetchCommodities).mockResolvedValue(
    page([{ id: "gold", name: "Gold", counted: true }]) as never,
  );
  vi.mocked(fetchEquipment).mockResolvedValue(
    page([{ id: "p4", name: "P4-AR Rifle", equipmentType: "weapon" }]) as never,
  );
});

afterEach(() => {
  wrapper?.unmount();
  wrapper = undefined;
  vi.clearAllMocks();
});

const mount = async (props: Record<string, unknown> = {}) => {
  wrapper = await mountWithDefaults<typeof Component>(Component, { props });
  await flushPromises();

  return wrapper;
};

const categorySelect = (subject: VueWrapper) =>
  subject
    .findAllComponents({ name: "BaseSelect" })
    .find((select) => select.props("name") === "item-picker-category")!;

const slotSelect = (subject: VueWrapper) =>
  subject
    .findAllComponents({ name: "BaseSelect" })
    .find((select) => select.props("name") === "item-picker-slot");

const chooseCategory = async (subject: VueWrapper, category: string) => {
  categorySelect(subject).vm.$emit("update:modelValue", category);
  await flushPromises();
};

describe("LogisticsItemPicker", () => {
  // Three catalogues sit behind three endpoints, and nothing says which one is
  // meant until a category does.
  it("lists nothing until a category is chosen", async () => {
    const subject = await mount();

    expect(fetchComponents).not.toHaveBeenCalled();
    expect(fetchCommodities).not.toHaveBeenCalled();
    expect(fetchEquipment).not.toHaveBeenCalled();
    expect(subject.find("[data-test^='item-picker-row-']").exists()).toBe(
      false,
    );
  });

  it("lists the components once the category asks for them", async () => {
    const subject = await mount();

    await chooseCategory(subject, "component");

    expect(fetchComponents).toHaveBeenCalledWith(
      expect.objectContaining({
        q: expect.objectContaining({ currentVersion: true, hiddenEq: false }),
      }),
    );
    expect(subject.find("[data-test='item-picker-row-bulwark']").exists()).toBe(
      true,
    );
  });

  // One table backs every equipment category, so each one has to ask for its
  // own slice of it -- or "Weapon" would offer armour and clothing too.
  it("asks for the category's slice of the equipment table", async () => {
    const subject = await mount();

    await chooseCategory(subject, "consumable");

    expect(fetchEquipment).toHaveBeenCalledWith(
      expect.objectContaining({
        q: expect.objectContaining({
          equipmentTypeIn: ["sustenance", "medical"],
        }),
      }),
    );
    expect(equipmentItemTypesFilters).toHaveBeenCalledWith({
      q: { equipmentTypeIn: ["sustenance", "medical"] },
    });
  });

  // Armour is typed by weight, so the slot is the only way to list every
  // helmet together.
  it("narrows worn gear by slot", async () => {
    const subject = await mount();

    await chooseCategory(subject, "armor");

    expect(equipmentItemTypesFilters).toHaveBeenCalledWith({
      q: { equipmentTypeIn: ["armor", "undersuit"] },
    });
    expect(equipmentSlotsFilters).toHaveBeenCalledWith({
      q: { equipmentTypeIn: ["armor", "undersuit"] },
    });

    slotSelect(subject)!.vm.$emit("update:modelValue", "helmet");
    await flushPromises();

    expect(fetchEquipment).toHaveBeenLastCalledWith(
      expect.objectContaining({
        q: expect.objectContaining({
          equipmentTypeIn: ["armor", "undersuit"],
          slotIn: ["helmet"],
        }),
      }),
    );
  });

  it("offers no slot for gear that is not worn", async () => {
    const subject = await mount();

    await chooseCategory(subject, "tool");

    expect(slotSelect(subject)).toBeUndefined();
    expect(equipmentSlotsFilters).not.toHaveBeenCalled();
  });

  // A slot left over from armour would match nothing under clothing's own.
  it("drops the slot when the category changes", async () => {
    const subject = await mount();

    await chooseCategory(subject, "armor");
    slotSelect(subject)!.vm.$emit("update:modelValue", "helmet");
    await flushPromises();
    await chooseCategory(subject, "clothing");

    expect(fetchEquipment).toHaveBeenLastCalledWith(
      expect.objectContaining({
        q: expect.objectContaining({
          equipmentTypeIn: ["clothing"],
          slotIn: undefined,
        }),
      }),
    );
  });

  it("hands back the pick with the category it was found under", async () => {
    const subject = await mount();

    await chooseCategory(subject, "weapon");
    await subject
      .find("[data-test='item-picker-row-p4'] button")
      .trigger("click");

    expect(subject.emitted("select")).toEqual([
      [
        {
          item: {
            type: "Equipment",
            id: "p4",
            name: "P4-AR Rifle",
            counted: undefined,
          },
          name: "P4-AR Rifle",
          category: "weapon",
        },
      ],
    ]);
  });

  // Contract progress matches deposits on the category, so a piece of
  // equipment is filed under one wherever it was browsed to.
  it("files equipment under its own category", async () => {
    vi.mocked(fetchEquipment).mockResolvedValue(
      page([
        { id: "medpen", name: "MedPen", equipmentType: "medical" },
      ]) as never,
    );

    const subject = await mount();

    await chooseCategory(subject, "consumable");
    await subject
      .find("[data-test='item-picker-row-medpen'] button")
      .trigger("click");

    expect(subject.emitted("select")?.[0]?.[0]).toMatchObject({
      category: "equipment",
    });
  });

  // Whether a commodity is counted is what puts `units` on offer, and only the
  // catalogue record knows.
  it("says whether a picked commodity is counted", async () => {
    const subject = await mount();

    await chooseCategory(subject, "commodity");
    await subject
      .find("[data-test='item-picker-row-gold'] button")
      .trigger("click");

    expect(subject.emitted("select")?.[0]?.[0]).toMatchObject({
      item: { type: "Commodity", id: "gold", name: "Gold", counted: true },
      category: "commodity",
    });
  });

  // Goods the catalogue does not carry are named by the search and filed by
  // the category, with no catalogue reference.
  it("adds what was searched for as a custom item", async () => {
    vi.useFakeTimers();

    const subject = await mount();

    await chooseCategory(subject, "other");
    await subject
      .find("[data-test='input-item-picker-search']")
      .setValue("Grandma's teapot");
    vi.advanceTimersByTime(400);
    vi.useRealTimers();
    await flushPromises();

    await subject.find("[data-test='item-picker-custom']").trigger("click");

    expect(subject.emitted("select")).toEqual([
      [{ item: undefined, name: "Grandma's teapot", category: "other" }],
    ]);
  });

  it("reopens on the category of the last pick", async () => {
    await mount({ category: "component" });

    expect(fetchComponents).toHaveBeenCalled();
  });

  it("offers only the categories it is given", async () => {
    const subject = await mount({ categories: ["component", "weapon"] });

    const options = categorySelect(subject).props("options") as {
      value: string;
    }[];

    expect(options.map((option) => option.value)).toEqual([
      "component",
      "weapon",
    ]);
  });
});
