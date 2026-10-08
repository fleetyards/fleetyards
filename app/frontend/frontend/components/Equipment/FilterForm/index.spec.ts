import { afterEach, describe, expect, it, vi } from "vitest";
import { createRouter, createWebHashHistory } from "vue-router";
import type { VueWrapper } from "@vue/test-utils";
import { mountWithDefaults } from "@/shared/utils/TestUtils";
import type { FilterOption } from "@/services/fyApi";
import Component from "./index.vue";

const { sizes, grades } = vi.hoisted(() => ({
  sizes: [
    { category: "size", label: "Size 1", value: "1" },
    { category: "size", label: "Size 3", value: "3" },
  ],
  grades: [
    { category: "grade", label: "Grade 1", value: "1" },
    { category: "grade", label: "Grade 2", value: "2" },
  ],
}));

vi.mock("@/services/fyApi", async (importOriginal) => {
  const { ref } = await import("vue");
  const empty = () => ({ data: ref<FilterOption[]>([]) });

  return {
    ...(await importOriginal<Record<string, unknown>>()),
    useEquipmentTypesFilters: empty,
    useEquipmentItemTypesFilters: empty,
    useEquipmentSubTypesFilters: empty,
    useEquipmentWeaponClassesFilters: empty,
    useEquipmentSlotsFilters: empty,
    useEquipmentSizesFilters: () => ({ data: ref<FilterOption[]>(sizes) }),
    useEquipmentGradesFilters: () => ({ data: ref<FilterOption[]>(grades) }),
  };
});

const mountAt = async (query: Record<string, string | string[]> = {}) => {
  const router = createRouter({
    history: createWebHashHistory(),
    routes: [
      {
        path: "/catalogue/equipment",
        name: "equipment",
        component: { template: "<div />" },
      },
    ],
  });

  await router.push({ name: "equipment", query });
  await router.isReady();

  const wrapper = await mountWithDefaults(Component, {
    props: { hideQuicksearch: true },
    plugins: [router],
  });

  return { router, wrapper };
};

const select = (wrapper: VueWrapper, name: string) =>
  wrapper
    .findAllComponents({ name: "BaseSelect" })
    .find((component) => component.props("name") === name)!;

describe("EquipmentFilterForm", () => {
  afterEach(() => {
    vi.useRealTimers();
  });

  it("offers the sizes and grades the catalogue has", async () => {
    const { wrapper } = await mountAt();

    expect(select(wrapper, "size").props("options")).toEqual(sizes);
    expect(select(wrapper, "grade").props("options")).toEqual(grades);
  });

  it("writes a picked size and grade to sizeIn and gradeIn", async () => {
    vi.useFakeTimers();
    const { router, wrapper } = await mountAt();

    select(wrapper, "size").vm.$emit("update:modelValue", ["3"]);
    select(wrapper, "grade").vm.$emit("update:modelValue", ["1", "2"]);

    await vi.advanceTimersByTimeAsync(400);

    expect(router.currentRoute.value.query.sizeIn).toEqual(["3"]);
    expect(router.currentRoute.value.query.gradeIn).toEqual(["1", "2"]);
  });

  it("prefills from a single value in the URL as a list", async () => {
    const { wrapper } = await mountAt({ sizeIn: "3", gradeIn: "2" });

    expect(select(wrapper, "size").props("modelValue")).toEqual(["3"]);
    expect(select(wrapper, "grade").props("modelValue")).toEqual(["2"]);
  });
});
