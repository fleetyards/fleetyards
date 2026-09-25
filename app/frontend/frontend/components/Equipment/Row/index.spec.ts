import { describe, expect, it } from "vitest";
import { createRouter, createWebHashHistory } from "vue-router";
import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { EquipmentTypeEnum, type Equipment } from "@/services/fyApi";
import Component from "./index.vue";

// The row links to the item and back into the list it is read from, and
// `filterLink` builds its target off the current route's name.
const routerOnList = async () => {
  const router = createRouter({
    history: createWebHashHistory(),
    routes: [
      {
        path: "/catalogue/equipment",
        name: "equipment",
        component: { template: "<div />" },
      },
      {
        path: "/catalogue/equipment/:slug",
        name: "equipment-item",
        component: { template: "<div />" },
      },
    ],
  });

  await router.push({ name: "equipment" });
  await router.isReady();

  return router;
};

const equipment = (attrs: Partial<Equipment> = {}) =>
  ({
    id: "0f2c0f2c-0f2c-0f2c-0f2c-0f2c0f2c0f2c",
    name: "P4-AR Rifle",
    slug: "p4-ar-rifle",
    equipmentType: EquipmentTypeEnum.WEAPON,
    equipmentTypeLabel: "Weapon",
    itemType: "assault_rifle",
    itemTypeLabel: "Assault Rifle",
    size: "2",
    retired: false,
    availability: { boughtAt: [], soldAt: [] },
    createdAt: "2026-01-01",
    updatedAt: "2026-01-01",
    ...attrs,
  }) as Equipment;

const mount = async (attrs: Partial<Equipment> = {}) =>
  mountWithDefaults(Component, {
    props: { equipment: equipment(attrs) },
    plugins: [await routerOnList()],
  });

describe("Equipment/Row", () => {
  it("links the name to the item", async () => {
    const wrapper = await mount();

    expect(wrapper.find(".row-list-item__name").attributes("href")).toContain(
      "/catalogue/equipment/p4-ar-rifle",
    );
  });

  it("makes the type and item type links that narrow the list", async () => {
    const wrapper = await mount();

    const links = wrapper.findAll(".row-list-item__sub a");

    expect(links.map((link) => link.text())).toEqual([
      "Weapon",
      "Assault Rifle",
    ]);
    expect(links[0].attributes("href")).toContain("equipmentTypeIn=weapon");
    expect(links[1].attributes("href")).toContain("itemTypeIn=assault_rifle");
  });

  it("marks an item the current build has dropped", async () => {
    const wrapper = await mount({ retired: true });

    expect(wrapper.text()).toContain("No longer in the current build");
  });
});
