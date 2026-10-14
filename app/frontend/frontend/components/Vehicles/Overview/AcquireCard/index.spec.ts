import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { describe, expect, it, vi } from "vitest";
import { createRouter, createWebHashHistory } from "vue-router";
import Component from "./index.vue";
import {
  type BuybackPledge,
  type HangarPledgeItem,
  type Vehicle,
  BuybackPledgeKindEnum,
  HangarPledgeItemKindEnum,
} from "@/services/fyApi";

const NOW = "2026-10-15T12:00:00Z";

const buybacks = ref<BuybackPledge[]>([]);
const upgrades = ref<HangarPledgeItem[]>([]);
const params: { buybacks?: unknown; upgrades?: unknown } = {};

const page = <T>(items: T[]) => ({
  items,
  meta: {
    pagination: {
      totalCount: items.length ? items.length + 4 : 0,
      currentPage: 1,
      totalPages: 2,
      perPage: 3,
    },
  },
});

vi.mock("@/services/fyApi", async (importOriginal) => ({
  ...(await importOriginal<typeof import("@/services/fyApi")>()),
  useHangarBuybacks: (query: () => unknown) => {
    params.buybacks = query();
    return {
      data: computed(() => page(buybacks.value)),
      isLoading: ref(false),
    };
  },
  useHangarUpgrades: (query: () => unknown) => {
    params.upgrades = query();
    return {
      data: computed(() => page(upgrades.value)),
      isLoading: ref(false),
    };
  },
}));

const buyback = (overrides: Partial<BuybackPledge> = {}): BuybackPledge => ({
  id: "buyback-1",
  rsiPledgeId: "1",
  kind: BuybackPledgeKindEnum.SHIP,
  name: "Standalone Ship - Cutlass Black",
  upgraded: false,
  available: true,
  lifetimeInsurance: false,
  price: 110,
  createdAt: NOW,
  updatedAt: NOW,
  ...overrides,
});

const upgrade = (
  overrides: Partial<HangarPledgeItem> = {},
): HangarPledgeItem => ({
  id: "upgrade-1",
  rsiPledgeId: "2",
  kind: HangarPledgeItemKindEnum.CCU,
  name: "Upgrade - Aurora MR to Cutlass Black",
  quantity: 1,
  standalone: true,
  meltable: true,
  pledgeValue: 85,
  createdAt: NOW,
  updatedAt: NOW,
  ...overrides,
});

const vehicle = {
  id: "vehicle-1",
  wanted: true,
  model: { slug: "cutlass-black" },
} as Vehicle;

const router = createRouter({
  history: createWebHashHistory(),
  routes: [
    { path: "/", name: "home", component: { template: "<div />" } },
    {
      path: "/hangar/buybacks",
      name: "hangar-buybacks",
      component: { template: "<div />" },
    },
    {
      path: "/hangar/upgrades",
      name: "hangar-upgrades",
      component: { template: "<div />" },
    },
  ],
});

const mount = () =>
  mountWithDefaults(Component, { props: { vehicle }, plugins: [router] });

describe("VehicleOverviewAcquireCard", () => {
  it("asks for the buy-backs and upgrades that lead to the ship", async () => {
    await mount();

    expect(params.buybacks).toMatchObject({
      q: { modelSlugEq: "cutlass-black" },
    });
    expect(params.upgrades).toMatchObject({
      q: { upgradeToModelSlugEq: "cutlass-black" },
    });
  });

  it("lists both, each linking to its whole filtered list", async () => {
    buybacks.value = [buyback()];
    upgrades.value = [upgrade({ quantity: 2 })];

    const wrapper = await mount();

    expect(
      wrapper.find('[data-test="vehicle-overview-acquire-buyback"]').text(),
    ).toContain("Standalone Ship - Cutlass Black");
    expect(
      wrapper.find('[data-test="vehicle-overview-acquire-upgrade"]').text(),
    ).toContain("×2");

    const links = wrapper.findAll("a").map((link) => link.attributes("href"));

    expect(links).toContain("#/hangar/buybacks?modelSlugEq=cutlass-black");
    expect(links).toContain(
      "#/hangar/upgrades?upgradeToModelSlugEq=cutlass-black",
    );

    buybacks.value = [];
    upgrades.value = [];
  });

  it("marks a buy-back RSI no longer offers", async () => {
    buybacks.value = [buyback({ available: false })];

    const wrapper = await mount();

    expect(
      wrapper.find('[data-test="vehicle-overview-acquire-buyback"]').classes(),
    ).toContain("overview-acquire__row--unavailable");

    buybacks.value = [];
  });

  it("stays away when nothing leads to the ship", async () => {
    const wrapper = await mount();

    expect(
      wrapper.find('[data-test="vehicle-overview-acquire"]').exists(),
    ).toBe(false);
  });
});
