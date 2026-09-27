import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { ref } from "vue";
import { createRouter, createWebHashHistory, type Router } from "vue-router";
import { mountWithDefaults } from "@/shared/utils/TestUtils";
import Component from "./index.vue";

vi.mock("@/services/fyApi", async (importOriginal) => ({
  ...(await importOriginal<object>()),
  useTradeRouteStarSystemsFilters: () => ({
    data: ref([
      { label: "Pyro", value: "Pyro" },
      { label: "Stanton", value: "Stanton" },
    ]),
  }),
  useTradeRouteCommoditiesFilters: () => ({
    data: ref([{ label: "Gold", value: "gold" }]),
  }),
}));

const routerAt = async (query: Record<string, string>) => {
  const router = createRouter({
    history: createWebHashHistory(),
    routes: [
      {
        path: "/tools/trade-routes",
        name: "trade-routes",
        component: { template: "<div />" },
      },
      {
        path: "/ships/:slug",
        name: "ship",
        component: { template: "<div />" },
      },
    ],
  });

  await router.push({ name: "trade-routes", query });
  await router.isReady();

  return router;
};

const mount = async (router: Router) =>
  mountWithDefaults(Component, { plugins: [router] });

describe("TradeRoutes/RunBar", () => {
  beforeEach(() => {
    vi.useFakeTimers();
    // jsdom lays nothing out, so the document reads 0 wide and the bar would
    // fold into its phone summary.
    Object.defineProperty(document.documentElement, "clientWidth", {
      configurable: true,
      value: 1440,
    });
  });

  afterEach(() => {
    vi.useRealTimers();
  });

  it("leaves a purchase's buyers when another system is picked", async () => {
    const router = await routerAt({ commodity: "gold", origin: "terminal-1" });
    const wrapper = await mount(router);

    const pyro = wrapper
      .findAll("button")
      .find((button) => button.text() === "Pyro");
    await pyro!.trigger("click");
    await vi.runAllTimersAsync();

    expect(router.currentRoute.value.query).toEqual({
      commodity: "gold",
      system: "Pyro",
    });
  });

  it("writes a typed budget into the URL once typing pauses", async () => {
    const router = await routerAt({ ship: "c2" });
    const wrapper = await mount(router);

    await wrapper.find("#trade-routes-budget").setValue("2,000,000");
    expect(router.currentRoute.value.query.budget).toBeUndefined();

    await vi.advanceTimersByTimeAsync(500);

    expect(router.currentRoute.value.query.budget).toBe("2000000");
  });

  it("drops a pending edit when the URL brings its own budget", async () => {
    const router = await routerAt({ ship: "c2" });
    const wrapper = await mount(router);

    await wrapper.find("#trade-routes-budget").setValue("2000000");
    await router.push({
      name: "trade-routes",
      query: { ship: "c2", budget: "500000" },
    });
    await vi.advanceTimersByTimeAsync(500);

    expect(router.currentRoute.value.query.budget).toBe("500000");
    expect(
      (wrapper.find("#trade-routes-budget").element as HTMLInputElement).value,
    ).toBe("500000");
  });
});
