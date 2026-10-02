import { describe, expect, it } from "vitest";
import { createRouter, createWebHashHistory } from "vue-router";
import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { ItemPriceItemTypeEnum, type ShopCategory } from "@/services/fyApi";
import Component from "./index.vue";

const router = async (query: Record<string, string> = {}) => {
  const instance = createRouter({
    history: createWebHashHistory(),
    routes: [
      {
        path: "/shops/:slug",
        name: "shop",
        component: { template: "<div />" },
      },
    ],
  });

  await instance.push({ name: "shop", params: { slug: "casaba" }, query });
  await instance.isReady();

  return instance;
};

const categories: ShopCategory[] = [
  {
    id: "Equipment.clothing",
    itemType: ItemPriceItemTypeEnum.EQUIPMENT,
    key: "clothing",
    label: "Clothing",
    count: 70,
  },
  {
    id: "Model",
    itemType: ItemPriceItemTypeEnum.MODEL,
    key: null,
    label: null,
    count: 3,
  },
];

describe("ShopCategoryFilters", () => {
  it("offers every category with its count, after one for everything", async () => {
    const wrapper = await mountWithDefaults(Component, {
      props: { categories, total: 73 },
      plugins: [await router()],
    });

    const buttons = wrapper.findAll("a");

    expect(buttons.map((button) => button.text().replace(/\s+/g, " "))).toEqual(
      ["All 73", "Clothing 70", "Ship 3"],
    );
    expect(buttons[1].attributes("href")).toContain(
      "categoryIn=Equipment.clothing",
    );
  });

  it("marks the one category the list is narrowed to", async () => {
    const wrapper = await mountWithDefaults(Component, {
      props: { categories, total: 73 },
      plugins: [await router({ categoryIn: "Model" })],
    });

    expect(
      wrapper.get('[data-test="shop-category-Model"]').classes(),
    ).toContain("active");
  });
});
