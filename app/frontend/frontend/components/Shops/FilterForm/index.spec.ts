import { describe, expect, it, vi } from "vitest";
import { createRouter, createWebHashHistory } from "vue-router";
import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { ItemPriceItemTypeEnum, type ShopCategory } from "@/services/fyApi";
import Component from "./index.vue";

const categories: ShopCategory[] = [
  {
    id: "Model",
    itemType: ItemPriceItemTypeEnum.MODEL,
    key: null,
    label: null,
    count: 3,
  },
];

describe("ShopFilterForm", () => {
  it("takes a category out of the exclusions when the select picks it", async () => {
    const router = createRouter({
      history: createWebHashHistory(),
      routes: [
        {
          path: "/shops/:slug",
          name: "shop",
          component: { template: "<div />" },
        },
      ],
    });

    await router.push({
      name: "shop",
      params: { slug: "casaba" },
      query: { categoryNotIn: "Model" },
    });
    await router.isReady();

    vi.useFakeTimers();

    const wrapper = await mountWithDefaults(Component, {
      props: { categories },
      plugins: [router],
    });

    wrapper
      .findComponent({ name: "BaseSelect" })
      .vm.$emit("update:modelValue", ["Model"]);

    await vi.advanceTimersByTimeAsync(400);
    vi.useRealTimers();

    expect(router.currentRoute.value.query.categoryIn).toEqual(["Model"]);
    expect(router.currentRoute.value.query.categoryNotIn).toBeUndefined();
  });
});
