import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { beforeEach, describe, expect, it, vi } from "vitest";
import { computed, defineComponent, h, ref } from "vue";
import { createRouter, createWebHashHistory } from "vue-router";
import Component from "./index.vue";

let hangar: { total: number; wishlistTotal: number } | undefined;
let onSaleCount = 0;

vi.mock("@/services/fyApi", async () => {
  const actual =
    await vi.importActual<Record<string, unknown>>("@/services/fyApi");

  const answer = <T>(value: () => T) => ({
    data: computed(value),
    isLoading: ref(false),
  });

  return {
    ...actual,
    useHangarStats: () => answer(() => hangar),
    useWishlist: () =>
      answer(() => ({
        items: [],
        meta: { pagination: { totalCount: onSaleCount } },
      })),
    useMyFleetSummaries: () => answer(() => ({ items: [] })),
  };
});

const Stub = defineComponent({ render: () => h("div") });

const mount = async () => {
  const router = createRouter({
    history: createWebHashHistory(),
    routes: [{ path: "/:rest(.*)*", name: "home", component: Stub }],
  });
  router.addRoute({ path: "/hangar", name: "hangar", component: Stub });
  router.addRoute({
    path: "/wishlist",
    name: "hangar-wishlist",
    component: Stub,
  });
  await router.push("/");
  await router.isReady();

  return mountWithDefaults(Component, { plugins: [router] });
};

const keys = async () =>
  (await mount())
    .findAll("[data-test^='home-stat-']")
    .map((stat) => stat.attributes("data-test"));

describe("HomeDashboardStats", () => {
  beforeEach(() => {
    hangar = { total: 27, wishlistTotal: 8 };
    onSaleCount = 0;
  });

  it("shows nothing until the hangar answers", async () => {
    hangar = undefined;

    expect(await keys()).toEqual([]);
  });

  it("names a sale only when there is one", async () => {
    expect(await keys()).toEqual(["home-stat-hangar", "home-stat-wishlist"]);

    onSaleCount = 2;

    expect(await keys()).toEqual([
      "home-stat-hangar",
      "home-stat-wishlist",
      "home-stat-on-sale",
    ]);
  });
});
