import { describe, expect, it } from "vitest";
import { createRouter, createWebHashHistory } from "vue-router";
import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { type Commodity } from "@/services/fyApi";
import Component from "./index.vue";

// The row links to the commodity and back into the list it is being read from,
// and `filterLink` builds its target off the current route's name -- so the
// default single-route test router cannot resolve either.
const routerOnList = async () => {
  const router = createRouter({
    history: createWebHashHistory(),
    routes: [
      {
        path: "/catalogue/commodities",
        name: "commodities",
        component: { template: "<div />" },
      },
      {
        path: "/catalogue/commodities/:slug",
        name: "commodity",
        component: { template: "<div />" },
      },
    ],
  });

  await router.push({ name: "commodities" });
  await router.isReady();

  return router;
};

const commodity = (attrs: Partial<Commodity> = {}) =>
  ({
    id: "0f2c0f2c-0f2c-0f2c-0f2c-0f2c0f2c0f2c",
    name: "Agricium",
    slug: "agricium",
    commodityType: "metal",
    counted: false,
    consumable: false,
    containerSizes: [],
    retired: false,
    availability: { boughtAt: [], soldAt: [] },
    createdAt: "2026-01-01",
    updatedAt: "2026-01-01",
    ...attrs,
  }) as Commodity;

const mount = async (attrs: Partial<Commodity> = {}) =>
  mountWithDefaults(Component, {
    props: { commodity: commodity(attrs) },
    plugins: [await routerOnList()],
  });

const BADGES = ".row-list-item__badge-value";

describe("Commodities/Row", () => {
  it("links the name to the commodity", async () => {
    const wrapper = await mount();

    expect(wrapper.find(".row-list-item__name").attributes("href")).toContain(
      "/catalogue/commodities/agricium",
    );
  });

  // Every value the catalogue can be narrowed by is a link that narrows it,
  // and the filters live in the route query rather than a store.
  it("makes the type a link that narrows the list", async () => {
    const wrapper = await mount();

    const link = wrapper.find(".row-list-item__sub a");

    expect(link.text()).toBe("Metals");
    expect(link.attributes("href")).toContain("commodityTypeIn=metal");
  });

  // Shop-perspective in the payload: what a terminal sells it for is what the
  // reader pays, so `sellPrice` is the figure under "Buy".
  it("states the two prices the reader's way round", async () => {
    const wrapper = await mount({ buyPrice: 17500, sellPrice: 23000 });

    const values = wrapper.findAll(BADGES).map((badge) => badge.text());

    expect(values[0]).toContain("23");
    expect(values[1]).toContain("17");
  });

  // 108 of the 232 are traded nowhere we know of. A column of dashes says less
  // than a column of nothing.
  it("shows no price badges at all when nothing trades it", async () => {
    const wrapper = await mount();

    expect(wrapper.findAll(BADGES)).toHaveLength(0);
  });

  it("marks a commodity the current build has dropped", async () => {
    const wrapper = await mount({ retired: true });

    expect(wrapper.text()).toContain("No longer in the current build");
  });

  // A type a later patch introduces has no label yet, and falling back to
  // nothing would leave the row's meta line empty rather than merely raw.
  it("falls back to the raw type for one nobody has labelled", async () => {
    const wrapper = await mount({ commodityType: "newfangledgoo" });

    expect(wrapper.find(".row-list-item__sub a").text()).toBe("newfangledgoo");
  });
});
