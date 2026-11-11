import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { flushPromises, type VueWrapper } from "@vue/test-utils";
import { describe, expect, it, vi } from "vitest";
import { type EquipmentQuery, EquipmentSlotEnum } from "@/services/fyApi";

// jsdom has no matchMedia; the picker asks it for reduced motion.
vi.stubGlobal(
  "matchMedia",
  vi.fn(() => ({
    matches: false,
    addEventListener: vi.fn(),
    removeEventListener: vi.fn(),
  })),
);

const page = (id: string, currentPage: number) => ({
  items: [{ id, name: id, slug: id, media: {} }],
  meta: { pagination: { currentPage, totalPages: 2, totalCount: 2 } },
});

const fetchEquipment = vi.fn((_params: unknown) =>
  Promise.resolve(page("first", 1)),
);

const facetParams = vi.fn();

const options = (category: string, values: string[]) =>
  values.map((value) => ({ category, label: value, value }));

vi.mock("@/services/fyApi", async (importOriginal) => {
  const { ref, toValue } = await import("vue");
  const facet = (category: string, values: string[]) => (params: unknown) => {
    facetParams(toValue(params));

    return { data: ref(options(category, values)) };
  };

  return {
    ...(await importOriginal<Record<string, unknown>>()),
    equipment: (params: unknown) => fetchEquipment(params),
    useEquipmentManufacturersFilters: facet("manufacturer", [
      "behring",
      "klwe",
    ]),
    useEquipmentSubTypesFilters: facet("sub_type", ["Light", "Heavy"]),
    useEquipmentGradesFilters: facet("grade", ["1", "2"]),
    useEquipmentSizesFilters: facet("size", ["1"]),
    useEquipmentWeaponClassesFilters: facet("weapon_class", []),
  };
});

const { default: CataloguePicker } = await import("./index.vue");

describe("CataloguePicker", () => {
  it("keeps the load more button until the next page has landed", async () => {
    const wrapper = await mountWithDefaults<typeof CataloguePicker>(
      CataloguePicker,
      {
        props: {
          kind: "Equipment",
          query: { slotIn: ["helmet"] },
          cardTestPrefix: "card",
        },
      },
    );
    await flushPromises();

    let land: (value: ReturnType<typeof page>) => void = () => undefined;
    fetchEquipment.mockReturnValueOnce(
      new Promise((resolve) => {
        land = resolve;
      }),
    );

    const more = '[data-test="catalogue-picker-more"]';
    await wrapper.find(more).trigger("click");
    await flushPromises();

    expect(wrapper.find(more).exists()).toBe(true);
    expect(wrapper.find('[data-test="card-second"]').exists()).toBe(false);

    land(page("second", 2));
    await flushPromises();

    expect(wrapper.find(more).exists()).toBe(false);
    expect(wrapper.find('[data-test="card-first"]').exists()).toBe(true);
    expect(wrapper.find('[data-test="card-second"]').exists()).toBe(true);
  });

  describe("filterable", () => {
    const helmets: EquipmentQuery = {
      equipmentTypeIn: ["armor"],
      slotIn: [EquipmentSlotEnum.HELMET],
    };

    const mountFilterable = async () => {
      const wrapper = await mountWithDefaults<typeof CataloguePicker>(
        CataloguePicker,
        {
          props: {
            kind: "Equipment",
            query: helmets,
            filterable: true,
            cardTestPrefix: "card",
          },
        },
      );
      await flushPromises();

      return wrapper;
    };

    const select = (wrapper: VueWrapper, key: string) =>
      wrapper
        .findAllComponents({ name: "BaseSelect" })
        .find((field) => field.props("name") === `catalogue-picker-${key}`);

    it("offers only the filters with something to choose between", async () => {
      const wrapper = await mountFilterable();

      expect(facetParams).toHaveBeenCalledWith({
        q: expect.objectContaining(helmets),
      });
      expect(select(wrapper, "manufacturerSlugIn")).toBeDefined();
      expect(select(wrapper, "subTypeIn")).toBeDefined();
      expect(select(wrapper, "gradeIn")).toBeDefined();
      expect(select(wrapper, "sizeIn")).toBeUndefined();
      expect(select(wrapper, "weaponClassIn")).toBeUndefined();
    });

    it("narrows the pinned query by a pick until the filters are reset", async () => {
      const wrapper = await mountFilterable();

      select(wrapper, "manufacturerSlugIn")?.vm.$emit("update:modelValue", [
        "behring",
      ]);
      await flushPromises();

      expect(fetchEquipment).toHaveBeenLastCalledWith(
        expect.objectContaining({
          page: "1",
          q: expect.objectContaining({
            ...helmets,
            manufacturerSlugIn: ["behring"],
          }),
        }),
      );

      await wrapper
        .find('[data-test="catalogue-picker-reset-filters"]')
        .trigger("click");
      await flushPromises();

      expect(fetchEquipment).toHaveBeenLastCalledWith(
        expect.objectContaining({
          q: expect.not.objectContaining({ manufacturerSlugIn: ["behring"] }),
        }),
      );
      expect(
        wrapper.find('[data-test="catalogue-picker-reset-filters"]').exists(),
      ).toBe(false);
    });
  });
});
