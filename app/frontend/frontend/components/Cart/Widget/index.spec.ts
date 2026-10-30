import { beforeEach, describe, expect, it, vi } from "vitest";
import { createMemoryHistory, createRouter } from "vue-router";
import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { type Cart } from "@/services/fyApi";

const cart = ref<Cart | undefined>();
const routeName = ref("home");

vi.mock("vue-router", async (importOriginal) => ({
  ...(await importOriginal<Record<string, unknown>>()),
  useRoute: () => ({
    get name() {
      return routeName.value;
    },
  }),
}));

vi.mock("@/services/fyApi", async (importOriginal) => ({
  ...(await importOriginal<Record<string, unknown>>()),
  useCart: () => ({ data: cart }),
}));

vi.mock("@/shared/composables/useMobile", () => ({
  useMobile: () => ref(false),
}));

const Component = (await import("./index.vue")).default;

const line = (id: string, available = true) => ({
  id,
  quantity: 2,
  available,
  total: available ? 100 : null,
  item: { id, name: `Item ${id}` },
});

const cartWith = (count: number) =>
  ({
    id: "list-a",
    name: "Mining run",
    active: true,
    items: Array.from({ length: count }, (_, index) => line(`${index}`)),
    groups: [],
    totals: {
      total: count * 100,
      itemsCount: count,
      quantity: count * 2,
      unavailableCount: 0,
      stopsCount: 1,
    },
  }) as unknown as Cart;

const router = createRouter({
  history: createMemoryHistory(),
  routes: [
    { path: "/", name: "home", component: { template: "<div />" } },
    { path: "/cart", name: "cart", component: { template: "<div />" } },
  ],
});

const mount = () =>
  mountWithDefaults<typeof Component>(Component, {
    initialState: { session: { authenticated: true } },
    plugins: [router],
  });

const expand = async (wrapper: Awaited<ReturnType<typeof mount>>) => {
  await wrapper.find("[data-test='cart-widget-expand']").trigger("click");

  return wrapper;
};

describe("CartWidget", () => {
  beforeEach(() => {
    localStorage.clear();
    routeName.value = "home";
    cart.value = cartWith(2);
  });

  it("starts as a pill with the count and total", async () => {
    const wrapper = await mount();

    expect(wrapper.find("[data-test='cart-widget-expand']").text()).toContain(
      "200",
    );
    // Two of each of the two lines: items, not lines.
    expect(wrapper.find(".cart-widget__count").text()).toBe("4");
    expect(wrapper.find("[data-test='cart-widget-total']").exists()).toBe(
      false,
    );
  });

  it("opens to the active list's lines and total", async () => {
    const wrapper = await expand(await mount());

    expect(wrapper.text()).toContain("Mining run");
    expect(wrapper.text()).toContain("2 × Item 0");
    expect(wrapper.find("[data-test='cart-widget-total']").exists()).toBe(true);
  });

  it("stays away while the active list is empty", async () => {
    cart.value = cartWith(0);
    const wrapper = await mount();

    expect(wrapper.find("[data-test='cart-widget']").exists()).toBe(false);
  });

  it("stays away on the cart page", async () => {
    routeName.value = "cart";
    const wrapper = await mount();

    expect(wrapper.find("[data-test='cart-widget']").exists()).toBe(false);
  });

  it("collapses to a pill again", async () => {
    const wrapper = await expand(await mount());

    await wrapper.find("[data-test='cart-widget-collapse']").trigger("click");

    expect(wrapper.find("[data-test='cart-widget-total']").exists()).toBe(
      false,
    );
    expect(localStorage.getItem("fy-cart-widget-collapsed")).toBe("true");
  });

  it("lists the first few lines and counts the rest", async () => {
    cart.value = cartWith(6);
    const wrapper = await expand(await mount());

    expect(wrapper.findAll(".cart-widget__line")).toHaveLength(4);
    expect(wrapper.text()).toContain("+2 more items");
  });
});
