import { describe, expect, it } from "vitest";
import { createRouter, createWebHashHistory } from "vue-router";
import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { ItemPriceItemTypeEnum, type LocationShop } from "@/services/fyApi";
import Component from "./index.vue";

const router = async () => {
  const instance = createRouter({
    history: createWebHashHistory(),
    routes: [
      { path: "/", name: "home", component: { template: "<div />" } },
      {
        path: "/shops/:slug",
        name: "shop",
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
    id: "casaba",
    name: "Casaba Outlet",
    slug: "casaba-outlet-everus-harbor",
    itemsCount: 78,
    categories: [
      {
        id: "Equipment.clothing",
        itemType: ItemPriceItemTypeEnum.EQUIPMENT,
        key: "clothing",
        label: "Clothing",
        count: 70,
      },
      {
        id: "Equipment.backpack",
        itemType: ItemPriceItemTypeEnum.EQUIPMENT,
        key: "backpack",
        label: "Backpacks",
        count: 8,
      },
    ],
  },
];

describe("LocationShops", () => {
  it("lists each shop as a tile that opens its page", async () => {
    const wrapper = await mountWithDefaults(Component, {
      props: { shops },
      plugins: [await router()],
    });

    const tile = wrapper.find("a.location-shops__tile");

    expect(tile.attributes("href")).toContain(
      "/shops/casaba-outlet-everus-harbor",
    );
    expect(wrapper.find(".location-shops__name").text()).toBe("Casaba Outlet");
    expect(wrapper.find(".location-shops__carries").text()).toBe(
      "Clothing · Backpacks",
    );
  });
});
