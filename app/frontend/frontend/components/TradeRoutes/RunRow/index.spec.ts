import { describe, expect, it } from "vitest";
import { createRouter, createWebHashHistory } from "vue-router";
import { mountWithDefaults } from "@/shared/utils/TestUtils";
import {
  type Terminal,
  type TradeRoute,
  NullableTradeRouteLoadLimitEnum,
  NullableTradeRouteUnflyableReasonEnum,
} from "@/services/fyApi";
import Component from "./index.vue";

const routerOnList = async () => {
  const router = createRouter({
    history: createWebHashHistory(),
    routes: [
      {
        path: "/tools/trade-routes",
        name: "trade-routes",
        component: { template: "<div />" },
      },
      {
        path: "/catalogue/commodities/:slug",
        name: "commodity",
        component: { template: "<div />" },
      },
    ],
  });

  await router.push({ name: "trade-routes", query: { ship: "freelancer" } });
  await router.isReady();

  return router;
};

const terminal = (attrs: Partial<Terminal>) =>
  ({
    id: "00000000-0000-0000-0000-000000000001",
    name: "Terminal",
    hasFreightElevator: true,
    hasLoadingDock: false,
    hasDockingPort: false,
    available: true,
    ...attrs,
  }) as Terminal;

const tradeRoute = (attrs: Partial<TradeRoute> = {}) =>
  ({
    id: "10000000-0000-0000-0000-000000000000",
    commodity: {
      id: "20000000-0000-0000-0000-000000000000",
      name: "Bexalite",
      slug: "bexalite",
    },
    originTerminal: terminal({
      id: "30000000-0000-0000-0000-000000000000",
      name: "Fallow Field",
      starSystem: "Pyro",
      outpost: "Fallow Field",
    }),
    destinationTerminal: terminal({
      id: "40000000-0000-0000-0000-000000000000",
      name: "Admin - Endgame",
      starSystem: "Pyro",
      spaceStation: "Endgame",
    }),
    priceOrigin: 23556,
    priceDestination: 30000,
    profitPerScu: 6444,
    scuOrigin: 516,
    scuDestination: 1000,
    containerSizes: [1, 2, 4, 8, 16],
    distance: 56,
    otherDestinations: 5,
    ...attrs,
  }) as TradeRoute;

const mount = async (attrs: Partial<TradeRoute> = {}) =>
  mountWithDefaults(Component, {
    props: { route: tradeRoute(attrs), rank: 4, topValue: 727792 },
    plugins: [await routerOnList()],
  });

describe("TradeRoutes/RunRow", () => {
  it("links the commodity to its page", async () => {
    const wrapper = await mount();

    expect(wrapper.find(".run-row__name").attributes("href")).toContain(
      "/catalogue/commodities/bexalite",
    );
  });

  it("names both terminals with their system and place", async () => {
    const wrapper = await mount();

    expect(wrapper.text()).toContain("Fallow Field");
    expect(wrapper.text()).toContain("Pyro · Endgame");
  });

  it("links the other buyers to every destination of this purchase", async () => {
    const wrapper = await mount();

    const link = wrapper.find(".run-row__others");
    expect(link.text()).toBe("+5 other places buy it");
    expect(link.attributes("href")).toContain(
      "origin=30000000-0000-0000-0000-000000000000",
    );
    expect(link.attributes("href")).toContain("commodity=bexalite");
    expect(link.attributes("href")).toContain("ship=freelancer");
  });

  it("shows the profit per SCU without a ship", async () => {
    const wrapper = await mount();

    expect(
      wrapper.find(".run-row__profit-value").text().replace(/\s/g, ""),
    ).toBe("+6444");
    expect(wrapper.find(".run-row__load").exists()).toBe(false);
  });

  it("shows the load, what limits it and the profit of a run for a ship", async () => {
    const wrapper = await mount({
      loadableScu: 84,
      loadLimit: NullableTradeRouteLoadLimitEnum.BUDGET,
      investment: 1978704,
      profitPerRun: 541296,
    });

    expect(wrapper.find(".run-row__load").text()).toContain("84 SCU");
    expect(wrapper.find(".run-row__limit--budget").text()).toBe(
      "Limited by budget",
    );
    expect(
      wrapper.find(".run-row__profit-value").text().replace(/\s/g, ""),
    ).toBe("+541296");
  });

  it("greys out a run the ship can't fly and says why", async () => {
    const wrapper = await mountWithDefaults(Component, {
      props: {
        route: tradeRoute({
          loadableScu: 84,
          profitPerRun: 541296,
          unflyableReason: NullableTradeRouteUnflyableReasonEnum.ORIGIN,
        }),
        rank: 4,
        topValue: 727792,
        shipName: "Hull C",
      },
      plugins: [await routerOnList()],
    });

    expect(wrapper.find(".run-row").classes()).toContain("run-row--unflyable");
    expect(wrapper.find(".run-row__unflyable").text()).toBe(
      "Hull C can't land at Fallow Field",
    );
  });

  it("names the destination when that is the end the ship can't reach", async () => {
    const wrapper = await mount({
      unflyableReason: NullableTradeRouteUnflyableReasonEnum.DESTINATION,
    });

    expect(wrapper.find(".run-row__unflyable").text()).toBe(
      "This ship can't land at Admin - Endgame",
    );
  });

  it("leaves a flyable run as it is", async () => {
    const wrapper = await mount();

    expect(wrapper.find(".run-row").classes()).not.toContain(
      "run-row--unflyable",
    );
    expect(wrapper.find(".run-row__unflyable").exists()).toBe(false);
  });
});
