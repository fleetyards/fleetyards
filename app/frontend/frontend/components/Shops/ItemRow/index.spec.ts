import { describe, expect, it } from "vitest";
import { createRouter, createWebHashHistory } from "vue-router";
import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { ItemPriceItemTypeEnum, type ShopItem } from "@/services/fyApi";
import Component from "./index.vue";

const router = async () => {
  const instance = createRouter({
    history: createWebHashHistory(),
    routes: [
      { path: "/", name: "home", component: { template: "<div />" } },
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

const item: ShopItem = {
  id: "cutlass",
  itemType: ItemPriceItemTypeEnum.MODEL,
  name: "Cutlass Black",
  slug: "cutlass-black",
  categoryId: "Model",
  categoryLabel: null,
  manufacturer: { name: "Drake Interplanetary", slug: "drake" },
  buyPrice: null,
  rentalPrice: 9000,
  sellPrice: null,
};

describe("ShopItemRow", () => {
  it("links the item to its page and shows only the prices it has here", async () => {
    const wrapper = await mountWithDefaults(Component, {
      props: { item },
      plugins: [await router()],
    });

    expect(wrapper.get("a.row-list-item__name").attributes("href")).toContain(
      "/ships/cutlass-black",
    );
    expect(wrapper.get(".row-list-item__sub").text()).toContain(
      "Drake Interplanetary",
    );

    const badges = wrapper.findAll(".row-list-item__badge");

    expect(badges).toHaveLength(1);
    expect(badges[0].text()).toContain("9");
  });
});
