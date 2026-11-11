import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { beforeEach, describe, expect, it, vi } from "vitest";
import { computed, defineComponent, h, ref } from "vue";
import { createRouter, createWebHashHistory } from "vue-router";
import type { Vehicle, WishlistParams } from "@/services/fyApi";
import Component from "./index.vue";

const NAMES = ["hangar-wishlist", "ship", "ships"];

const Stub = defineComponent({ render: () => h("div") });

const router = async () => {
  const instance = createRouter({
    history: createWebHashHistory(),
    routes: [
      { path: "/", name: "home", component: Stub },
      ...NAMES.map((name) => ({
        path: `/${name}/:id?/:slug?`,
        name,
        component: Stub,
      })),
    ],
  });

  await instance.push("/");
  await instance.isReady();

  return instance;
};

let onSaleItems: Vehicle[] = [];
let recentItems: Vehicle[] = [];

vi.mock("@/services/fyApi", async () => {
  const actual =
    await vi.importActual<Record<string, unknown>>("@/services/fyApi");

  return {
    ...actual,
    useWishlist: (params: WishlistParams) => ({
      data: computed(() => ({
        items: params.q?.onSaleEq ? onSaleItems : recentItems,
        meta: {},
      })),
      isLoading: ref(false),
      isFetching: ref(false),
      isLoadingError: ref(false),
    }),
  };
});

const vehicle = (
  id: string,
  name: string,
  model: Partial<Vehicle["model"]> = {},
): Vehicle =>
  ({
    id,
    model: {
      id: `m-${id}`,
      name,
      slug: name.toLowerCase(),
      onSale: false,
      media: {},
      manufacturer: { name: "RSI" },
      ...model,
    },
  }) as unknown as Vehicle;

const items = (subject: Awaited<ReturnType<typeof mountWithDefaults>>) =>
  subject.findAll('[data-test="home-wishlist-item"]');

describe("HomeDashboardWishlistPanel", () => {
  beforeEach(() => {
    onSaleItems = [];
    recentItems = [];
  });

  it("marks a ship on sale and shows its current price", async () => {
    const zeus = vehicle("1", "Zeus", { onSale: true, pledgePrice: 150 });
    onSaleItems = [zeus];
    recentItems = [zeus];

    const subject = await mountWithDefaults(Component, {
      plugins: [await router()],
    });

    const [row] = items(subject);
    expect(row.text()).toContain("On sale");
    expect(row.text()).toContain("$150");
  });

  it("shows no price for a ship that is not on sale", async () => {
    recentItems = [vehicle("2", "Polaris", { pledgePrice: 975 })];

    const subject = await mountWithDefaults(Component, {
      plugins: [await router()],
    });

    const [row] = items(subject);
    expect(row.text()).not.toContain("On sale");
    expect(row.text()).not.toContain("975");
  });

  it("lists ships on sale first, each once", async () => {
    const zeus = vehicle("1", "Zeus", { onSale: true, pledgePrice: 150 });
    recentItems = [vehicle("2", "Polaris"), zeus];
    onSaleItems = [zeus];

    const subject = await mountWithDefaults(Component, {
      plugins: [await router()],
    });

    expect(items(subject).map((row) => row.text())).toEqual([
      expect.stringContaining("Zeus"),
      expect.stringContaining("Polaris"),
    ]);
  });
});
