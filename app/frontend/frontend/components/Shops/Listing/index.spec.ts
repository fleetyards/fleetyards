import { describe, expect, it } from "vitest";
import { createRouter, createWebHashHistory } from "vue-router";
import { mountWithDefaults } from "@/shared/utils/TestUtils";
import {
  ItemPriceItemTypeEnum,
  ItemPriceTypeEnum,
  type ShopItem,
} from "@/services/fyApi";
import Component from "./index.vue";

const router = async () => {
  const instance = createRouter({
    history: createWebHashHistory(),
    routes: [
      { path: "/", name: "home", component: { template: "<div />" } },
      {
        path: "/equipment/:slug",
        name: "equipment-item",
        component: { template: "<div />" },
      },
      {
        path: "/ships/:slug",
        name: "ship",
        component: { template: "<div />" },
      },
    ],
  });

  await instance.push({ name: "home" });
  await instance.isReady();

  return instance;
};

const item = (
  id: string,
  name: string,
  itemType: ItemPriceItemTypeEnum,
): ShopItem => ({
  id,
  name,
  slug: id,
  itemType,
  prices: [{ priceType: ItemPriceTypeEnum.SELL, price: 210, timeRange: null }],
});

describe("ShopListing", () => {
  it("groups what a shop sells by kind, the largest first, each linked", async () => {
    const wrapper = await mountWithDefaults(Component, {
      props: {
        items: [
          item("aurora", "Aurora MR", ItemPriceItemTypeEnum.MODEL),
          item("adiva", "Adiva Jacket", ItemPriceItemTypeEnum.EQUIPMENT),
          item("arden", "Arden-SL Helmet", ItemPriceItemTypeEnum.EQUIPMENT),
        ],
      },
      plugins: [await router()],
    });

    const groups = wrapper.findAll(".shop-listing__group");
    expect(groups).toHaveLength(2);
    expect(groups[0].findAll('[data-test="shop-item"]')).toHaveLength(2);
    expect(wrapper.find("a.shop-listing__name").attributes("href")).toContain(
      "/equipment/adiva",
    );
  });
});
