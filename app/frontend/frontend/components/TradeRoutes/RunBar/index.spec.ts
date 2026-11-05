import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { ref } from "vue";
import { createRouter, createWebHashHistory, type Router } from "vue-router";
import { type VueWrapper } from "@vue/test-utils";
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
  useTradeRouteOriginTerminalsFilters: () => ({
    data: ref([
      { category: "Pyro", label: "Ruin Station", value: "ruin" },
      { category: "Stanton", label: "ARC-L1", value: "arc" },
    ]),
  }),
  useTradeRouteDestinationTerminalsFilters: () => ({
    data: ref([{ category: "Stanton", label: "Area 18", value: "area18" }]),
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

  const select = (wrapper: VueWrapper, name: string) =>
    wrapper
      .findAllComponents({ name: "BaseSelect" })
      .find((component) => component.props("name") === name)!;

  const clickSystem = async (wrapper: VueWrapper, system: string) => {
    await wrapper
      .findAll("button")
      .find((button) => button.text() === system)!
      .trigger("click");
    await vi.runAllTimersAsync();
  };

  it("writes the start and target into the URL and leaves a purchase's buyers", async () => {
    const router = await routerAt({ commodity: "gold", origin: "arc" });
    const wrapper = await mount(router);

    select(wrapper, "start").vm.$emit("update:modelValue", "ruin");
    await vi.runAllTimersAsync();
    select(wrapper, "target").vm.$emit("update:modelValue", "area18");
    await vi.runAllTimersAsync();

    expect(router.currentRoute.value.query).toEqual({
      commodity: "gold",
      from: "ruin",
      to: "area18",
    });
  });

  it("offers only the starts of the picked system", async () => {
    const router = await routerAt({ system: "Pyro" });
    const wrapper = await mount(router);

    expect(select(wrapper, "start").props("options")).toEqual([
      { category: "Pyro", label: "Ruin Station", value: "ruin" },
    ]);
  });

  it("drops a start outside a newly picked system", async () => {
    const router = await routerAt({ from: "arc", to: "area18" });
    const wrapper = await mount(router);

    await clickSystem(wrapper, "Pyro");

    expect(router.currentRoute.value.query).toEqual({
      system: "Pyro",
      to: "area18",
    });
  });

  it("keeps a start inside a newly picked system", async () => {
    const router = await routerAt({ from: "ruin" });
    const wrapper = await mount(router);

    await clickSystem(wrapper, "Pyro");

    expect(router.currentRoute.value.query).toEqual({
      system: "Pyro",
      from: "ruin",
    });
  });

  it("names the start and target in the phone summary", async () => {
    Object.defineProperty(document.documentElement, "clientWidth", {
      configurable: true,
      value: 400,
    });
    const router = await routerAt({ from: "arc", to: "area18" });
    const wrapper = await mount(router);

    const chips = wrapper.findAll(".run-bar__chip").map((chip) => chip.text());

    expect(chips.join(" ")).toContain("ARC-L1");
    expect(chips.join(" ")).toContain("Area 18");
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
