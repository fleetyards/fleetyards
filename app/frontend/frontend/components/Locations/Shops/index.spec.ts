import { describe, expect, it } from "vitest";
import { createRouter, createWebHashHistory } from "vue-router";
import { mountWithDefaults } from "@/shared/utils/TestUtils";
import {
  ItemPriceItemTypeEnum,
  ItemPriceTypeEnum,
  type LocationShop,
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
    ],
  });

  await instance.push({ name: "home" });
  await instance.isReady();

  return instance;
};

const shops: LocationShop[] = [
  {
    name: "Casaba Outlet",
    itemsCount: 1,
    items: [
      {
        id: "jacket",
        name: "Adiva Jacket",
        slug: "adiva-jacket",
        itemType: ItemPriceItemTypeEnum.EQUIPMENT,
        prices: [
          { priceType: ItemPriceTypeEnum.SELL, price: 210, timeRange: null },
        ],
      },
    ],
  },
];

describe("LocationShops", () => {
  it("lists a shop closed, and opens it into what it sells", async () => {
    const wrapper = await mountWithDefaults(Component, {
      props: { shops },
      plugins: [await router()],
    });

    expect(wrapper.find(".location-shops__name").text()).toBe("Casaba Outlet");
    expect(wrapper.find(".location-shops__items").exists()).toBe(false);

    await wrapper.find(".location-shops__head").trigger("click");

    const link = wrapper.find("a.location-shops__item-name");
    expect(link.text()).toBe("Adiva Jacket");
    expect(link.attributes("href")).toContain("/equipment/adiva-jacket");
  });
});
