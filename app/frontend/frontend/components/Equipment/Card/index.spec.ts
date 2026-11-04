import { describe, expect, it } from "vitest";
import { createRouter, createWebHashHistory } from "vue-router";
import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { EquipmentTypeEnum, type Equipment } from "@/services/fyApi";
import Component from "./index.vue";

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

const mount = async (attrs: Partial<Equipment> = {}, details = false) =>
  mountWithDefaults(Component, {
    props: { equipment: equipment(attrs), details },
    plugins: [await routerOnList()],
  });

describe("Equipment/Card", () => {
  it("links the name to the item", async () => {
    const wrapper = await mount();

    expect(wrapper.find(".item-card__name").attributes("href")).toContain(
      "/catalogue/equipment/p4-ar-rifle",
    );
  });

  it("makes the type and item type links that narrow the list", async () => {
    const wrapper = await mount();

    const links = wrapper.findAll("[data-test='item-card-categories'] a");

    expect(links.map((link) => link.text())).toEqual([
      "Weapon",
      "Assault Rifle",
    ]);
    expect(links[0].attributes("href")).toContain("equipmentTypeIn=weapon");
    expect(links[1].attributes("href")).toContain("itemTypeIn=assault_rifle");
  });

  it("shows its store image in place of the type icon", async () => {
    const wrapper = await mount({
      storeImage: { smallUrl: "https://example.test/small.jpg" },
    } as Partial<Equipment>);

    expect(
      wrapper.find("[data-test='item-card-image']").attributes("src"),
    ).toBe("https://example.test/small.jpg");
  });

  it("keeps the type icon without a store image", async () => {
    const wrapper = await mount();

    expect(wrapper.find("[data-test='item-card-image']").exists()).toBe(false);
    expect(wrapper.findComponent({ name: "EquipmentIcon" }).exists()).toBe(
      true,
    );
  });

  it("marks a retired item over its picture", async () => {
    const wrapper = await mount({ retired: true });

    expect(wrapper.find(".item-card__tags").text()).not.toBe("");
  });

  it("names the size in a tile", async () => {
    const wrapper = await mount();

    expect(wrapper.find("[data-test='item-card-badge-size']").text()).toContain(
      "2",
    );
  });

  it("lists every figure the item has in its details", async () => {
    const wrapper = await mount(
      {
        dps: 120,
        alphaDamage: 30,
        rateOfFire: 240,
        range: 80,
        volume: 1,
      } as Partial<Equipment>,
      true,
    );

    expect(wrapper.findAll("[data-test='item-card-stat']")).toHaveLength(5);
  });

  it("works out no figures until details are on", async () => {
    const wrapper = await mount({ dps: 120 } as Partial<Equipment>);

    expect(wrapper.findAll("[data-test='item-card-stat']")).toHaveLength(0);
  });
});
