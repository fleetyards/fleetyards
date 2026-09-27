import { describe, expect, it } from "vitest";
import {
  createRouter,
  createWebHashHistory,
  type LocationQueryRaw,
  type Router,
} from "vue-router";
import { createApp } from "vue";
import { useTradeRouteRun } from "./useTradeRouteRun";

const setup = async (query: LocationQueryRaw) => {
  const router = createRouter({
    history: createWebHashHistory(),
    routes: [
      { path: "/", name: "trade-routes", component: { template: "<div />" } },
    ],
  });

  await router.push({ name: "trade-routes", query });
  await router.isReady();

  let run!: ReturnType<typeof useTradeRouteRun>;
  const app = createApp({
    setup() {
      run = useTradeRouteRun();

      return () => null;
    },
  });
  app.use(router);
  app.mount(document.createElement("div"));

  return { run, router: router as Router, unmount: () => app.unmount() };
};

const apiQueryFor = async (query: LocationQueryRaw) => {
  const { run, unmount } = await setup(query);
  const result = run.apiQuery.value;
  unmount();

  return result;
};

describe("useTradeRouteRun", () => {
  it("asks for grouped runs priced within three days by default", async () => {
    expect(await apiQueryFor({})).toEqual({
      grouped: true,
      maxPriceAgeHours: 72,
    });
  });

  it("drops the price age when any age is allowed", async () => {
    expect(await apiQueryFor({ priceAge: "any" })).not.toHaveProperty(
      "maxPriceAgeHours",
    );
  });

  it("sends the ship and its budget", async () => {
    expect(
      await apiQueryFor({ ship: "misc-freelancer-max", budget: "2000000" }),
    ).toMatchObject({ modelSlug: "misc-freelancer-max", budget: 2000000 });
  });

  it("ignores a budget without a ship to load", async () => {
    expect(await apiQueryFor({ budget: "2000000" })).not.toHaveProperty(
      "budget",
    );
  });

  it("ignores a budget that is not a positive number", async () => {
    expect(
      await apiQueryFor({ ship: "misc-freelancer-max", budget: "lots" }),
    ).not.toHaveProperty("budget");
  });

  it("sends the system and commodity as lists", async () => {
    expect(
      await apiQueryFor({ system: "Pyro", commodity: "gold" }),
    ).toMatchObject({
      originTerminalStarSystemIn: ["Pyro"],
      commoditySlugIn: ["gold"],
    });
  });

  it("lists every destination of one purchase ungrouped", async () => {
    expect(
      await apiQueryFor({ commodity: "gold", origin: "terminal-1" }),
    ).toMatchObject({
      grouped: false,
      commoditySlugIn: ["gold"],
      originTerminalIdIn: ["terminal-1"],
    });
  });

  it("writes changes into the URL and keeps the rest of the run", async () => {
    const { run, router, unmount } = await setup({
      ship: "c2",
      system: "Pyro",
    });

    await run.update({ system: undefined, priceAge: "24" });

    expect(router.currentRoute.value.query).toEqual({
      ship: "c2",
      priceAge: "24",
    });
    expect(run.apiQuery.value.maxPriceAgeHours).toBe(24);
    unmount();
  });
});
