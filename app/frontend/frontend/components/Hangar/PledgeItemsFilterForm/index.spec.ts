import { describe, expect, it, vi } from "vitest";
import { createRouter, createWebHashHistory } from "vue-router";
import { mountWithDefaults } from "@/shared/utils/TestUtils";
import Component from "./index.vue";

vi.mock("@/services/fyApi", async (importOriginal) => {
  const { ref } = await import("vue");

  return {
    ...(await importOriginal<Record<string, unknown>>()),
    useModel: () => ({ data: ref(undefined) }),
    useHangarBuybackInsuranceTerms: () => ({
      data: ref({ months: [120, 6], lifetime: true, none: true }),
      refetch: vi.fn(),
    }),
  };
});

const setup = async (query: Record<string, string | string[]> = {}) => {
  const router = createRouter({
    history: createWebHashHistory(),
    routes: [
      {
        path: "/hangar/upgrades",
        name: "hangar-upgrades",
        component: { template: "<div />" },
      },
    ],
  });

  await router.push({ name: "hangar-upgrades", query });
  await router.isReady();

  const wrapper = await mountWithDefaults(Component, {
    plugins: [router],
    props: { upgrades: true },
  });

  return { router, wrapper };
};

const picker = (
  wrapper: Awaited<ReturnType<typeof setup>>["wrapper"],
  name: string,
) =>
  wrapper
    .findAllComponents({ name: "ModelPickerSelect" })
    .find((component) => component.props("name") === name)!;

describe("HangarPledgeItemsFilterForm", () => {
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
