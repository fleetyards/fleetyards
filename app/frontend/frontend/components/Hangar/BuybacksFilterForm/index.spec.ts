import { describe, expect, it, vi } from "vitest";
import { createRouter, createWebHashHistory } from "vue-router";
import { mountWithDefaults } from "@/shared/utils/TestUtils";
import Component from "./index.vue";

vi.mock("@/services/fyApi", async (importOriginal) => {
  const { ref } = await import("vue");

  return {
    ...(await importOriginal<Record<string, unknown>>()),
    useModel: () => ({ data: ref(undefined) }),
  };
});

const setup = async (query: Record<string, string | string[]> = {}) => {
  const router = createRouter({
    history: createWebHashHistory(),
    routes: [
      {
        path: "/hangar/buybacks",
        name: "hangar-buybacks",
        component: { template: "<div />" },
      },
    ],
  });

  await router.push({ name: "hangar-buybacks", query });
  await router.isReady();

  const wrapper = await mountWithDefaults(Component, { plugins: [router] });

  return { router, wrapper };
};

const picker = (
  wrapper: Awaited<ReturnType<typeof setup>>["wrapper"],
  name: string,
) =>
  wrapper
    .findAllComponents({ name: "ModelPickerSelect" })
    .find((component) => component.props("name") === name)!;

describe("HangarBuybacksFilterForm", () => {
  it("keeps the price presets in ascending order", async () => {
    const { wrapper } = await setup();

    const priceSelect = wrapper
      .findAllComponents({ name: "BaseSelect" })
      .find((component) => component.props("name") === "priceIn")!;

    expect(priceSelect.props("unsorted")).toBe(true);
    expect(
      priceSelect
        .props("options")
        .map((option: { value: string }) => option.value)
        .slice(0, 3),
    ).toEqual(["-25", "25-50", "50-75"]);
  });

  it("offers lifetime insurance before the month terms", async () => {
    const { wrapper } = await setup();

    const insuranceSelect = wrapper
      .findAllComponents({ name: "BaseSelect" })
      .find((component) => component.props("name") === "insuranceIn")!;

    expect(insuranceSelect.props("unsorted")).toBe(true);
    expect(
      insuranceSelect
        .props("options")
        .map((option: { value: string }) => option.value)
        .slice(0, 2),
    ).toEqual(["lifetime", "120"]);
  });

  it("prefills the insurance from the URL", async () => {
    const { wrapper } = await setup({ insuranceIn: ["lifetime", "120"] });

    const insuranceSelect = wrapper
      .findAllComponents({ name: "BaseSelect" })
      .find((component) => component.props("name") === "insuranceIn")!;

    expect(insuranceSelect.props("modelValue")).toEqual(["lifetime", "120"]);
  });

  it("prefills the upgrade ships from the URL", async () => {
    const { wrapper } = await setup({
      upgradeFromModelSlugEq: "clipper",
      upgradeToModelSlugEq: "s-65-stingray",
    });

    expect(picker(wrapper, "upgradeFromModelSlugEq").props("modelValue")).toBe(
      "clipper",
    );
    expect(picker(wrapper, "upgradeToModelSlugEq").props("modelValue")).toBe(
      "s-65-stingray",
    );
  });

  it("puts a picked ship in the URL and removes it again on clear", async () => {
    const { router, wrapper } = await setup();

    vi.useFakeTimers();

    picker(wrapper, "upgradeToModelSlugEq").vm.$emit(
      "update:modelValue",
      "s-65-stingray",
    );
    await vi.advanceTimersByTimeAsync(400);

    expect(router.currentRoute.value.query.upgradeToModelSlugEq).toBe(
      "s-65-stingray",
    );

    picker(wrapper, "upgradeToModelSlugEq").vm.$emit(
      "update:modelValue",
      undefined,
    );
    await vi.advanceTimersByTimeAsync(400);
    vi.useRealTimers();

    expect(
      router.currentRoute.value.query.upgradeToModelSlugEq,
    ).toBeUndefined();
  });
});
