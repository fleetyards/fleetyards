import { mount, flushPromises } from "@vue/test-utils";
import { createPinia, setActivePinia } from "pinia";
import { VueQueryPlugin } from "@tanstack/vue-query";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { ref, type MaybeRef } from "vue";
import type { VueWrapper } from "@vue/test-utils";

const { route, replace, push, sizes, grades } = vi.hoisted(() => ({
  sizes: [
    { category: "size", label: "Size 1", value: "1" },
    { category: "size", label: "Size 10", value: "10" },
  ],
  grades: [
    { category: "grade", label: "Grade A", value: "1" },
    { category: "grade", label: "Grade C", value: "3" },
  ],
  route: {
    name: "components",
    params: {},
    query: {} as Record<string, unknown>,
  },
  replace: vi.fn((_to: { query: Record<string, unknown> }) =>
    Promise.resolve(),
  ),
  push: vi.fn((_to: { query: Record<string, unknown> }) => Promise.resolve()),
}));

vi.mock("vue-router", () => ({
  useRoute: () => route,
  useRouter: () => ({ replace, push }),
}));

vi.mock("@/shared/composables/useI18n", () => ({
  useI18n: () => ({ t: (key: string) => key, tExists: () => false }),
}));

// Coolers here only come in size 1 and grade A, so picking the category
// narrows both.
vi.mock("@/services/fyApi", async (importOriginal) => {
  const { computed, toValue } = await import("vue");
  type Params = { q?: { categoryIn?: string[] } };
  const narrowed =
    <T>(options: T[]) =>
    (params: MaybeRef<Params>) => ({
      data: computed(() =>
        toValue(params).q?.categoryIn?.includes("cooler")
          ? options.slice(0, 1)
          : options,
      ),
    });

  return {
    ...(await importOriginal<typeof import("@/services/fyApi")>()),
    useComponentCategoriesFilters: () => ({ data: ref([]) }),
    useComponentSubTypesFilters: () => ({ data: ref([]) }),
    useComponentSizesFilters: narrowed(sizes),
    useComponentGradesFilters: narrowed(grades),
  };
});

vi.mock("@/frontend/components/base/ManufacturerSelect/index.vue", () => ({
  default: { name: "ManufacturerSelect", render: () => null },
}));

import Component from "./index.vue";

const mountForm = () =>
  mount(Component, {
    global: {
      plugins: [VueQueryPlugin],
      stubs: { teleport: true },
      directives: { Tooltip: {} },
    },
  });

const select = (wrapper: VueWrapper, name: string) =>
  wrapper
    .findAllComponents({ name: "BaseSelect" })
    .find((component) => component.props("name") === name)!;

const lastQuery = () => {
  const calls = [...push.mock.calls, ...replace.mock.calls];

  return calls[calls.length - 1][0].query;
};

describe("ComponentsFilterForm", () => {
  beforeEach(() => {
    setActivePinia(createPinia());
    vi.useFakeTimers();
    replace.mockClear();
    push.mockClear();
  });

  afterEach(() => {
    vi.useRealTimers();
  });

  // A link saved before the alias search still carries `nameCont`, which the
  // API keeps accepting -- left in the URL it would narrow every search typed
  // into the box, and miss what players call a part.
  it("folds a legacy nameCont into the alias search", async () => {
    route.query = { nameCont: "ore pod" };
    const wrapper = mountForm();
    await flushPromises();

    const input = wrapper.find("input[name='search']");
    expect((input.element as HTMLInputElement).value).toBe("ore pod");

    vi.advanceTimersByTime(2000);
    push.mockClear();
    replace.mockClear();

    await input.setValue("mining bag");
    vi.advanceTimersByTime(400);

    const calls = [...push.mock.calls, ...replace.mock.calls];
    expect(calls.length).toBeGreaterThan(0);
    const { query } = calls[calls.length - 1][0];
    expect(query.searchNameCont).toBe("mining bag");
    expect(query).not.toHaveProperty("nameCont");
  });

  it("offers the sizes and grades the catalogue has", async () => {
    route.query = {};
    const wrapper = mountForm();
    await flushPromises();

    expect(select(wrapper, "size").props("options")).toEqual(sizes);
    expect(select(wrapper, "grade").props("options")).toEqual(grades);
  });

  it("writes a picked size and grade to sizeIn and gradeIn", async () => {
    route.query = {};
    const wrapper = mountForm();
    await flushPromises();

    select(wrapper, "size").vm.$emit("update:modelValue", ["10"]);
    select(wrapper, "grade").vm.$emit("update:modelValue", ["1", "3"]);
    await flushPromises();
    vi.advanceTimersByTime(400);

    expect(lastQuery().sizeIn).toEqual(["10"]);
    expect(lastQuery().gradeIn).toEqual(["1", "3"]);
  });

  it("prefills from a single value in the URL as a list", async () => {
    route.query = { sizeIn: "10", gradeIn: "3" };
    const wrapper = mountForm();
    await flushPromises();

    expect(select(wrapper, "size").props("modelValue")).toEqual(["10"]);
    expect(select(wrapper, "grade").props("modelValue")).toEqual(["3"]);
  });

  it("narrows to the chosen category and drops a size or grade it no longer has", async () => {
    route.query = { sizeIn: ["1", "10"], gradeIn: ["1", "3"] };
    const wrapper = mountForm();
    await flushPromises();

    select(wrapper, "category").vm.$emit("update:modelValue", ["cooler"]);
    await flushPromises();

    expect(select(wrapper, "size").props("options")).toEqual([sizes[0]]);
    expect(select(wrapper, "size").props("modelValue")).toEqual(["1"]);
    expect(select(wrapper, "grade").props("options")).toEqual([grades[0]]);
    expect(select(wrapper, "grade").props("modelValue")).toEqual(["1"]);
  });
});
