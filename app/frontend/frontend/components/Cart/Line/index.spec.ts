import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { flushPromises } from "@vue/test-utils";
import { createMemoryHistory, createRouter } from "vue-router";
import { mountWithDefaults } from "@/shared/utils/TestUtils";
import {
  type CartLine,
  type ItemPrice,
  InventoryItemTypeEnum,
} from "@/services/fyApi";

const update = vi.fn();
const remove = vi.fn();

vi.mock("@/services/fyApi", async (importOriginal) => ({
  ...(await importOriginal<Record<string, unknown>>()),
  useUpdateCartItem: () => ({ mutate: update, isPending: ref(false) }),
  useRemoveCartItem: () => ({ mutate: remove, isPending: ref(false) }),
}));

vi.mock("@/frontend/composables/useCartCache", () => ({
  useCartCache: () => ({ updateCart: vi.fn() }),
}));

vi.mock("@/shared/composables/useAppNotifications", () => ({
  useAppNotifications: () => ({ displayAlert: vi.fn() }),
}));

const Component = (await import("./index.vue")).default;

const price = (id: string, amount: number, shopName: string) =>
  ({
    id,
    price: amount,
    priceType: "sell",
    itemId: "item-id",
    itemType: "Equipment",
    location: `${shopName} - Everus Harbor - Hurston`,
    shop: null,
    createdAt: "2026-01-01",
    updatedAt: "2026-01-01",
  }) as unknown as ItemPrice;

const cheap = price("cheap", 210, "Casaba Outlet");
const dear = price("dear", 250, "Garrity Defense");

const line = (attrs: Partial<CartLine> = {}) =>
  ({
    id: "line-id",
    quantity: 2,
    item: {
      id: "item-id",
      type: InventoryItemTypeEnum.EQUIPMENT,
      name: "Adiva Jacket",
      slug: "adiva-jacket",
      listed: true,
    },
    available: true,
    pinned: false,
    unitPrice: 210,
    total: 420,
    price: cheap,
    offers: [cheap, dear],
    createdAt: "2026-01-01",
    updatedAt: "2026-01-01",
    ...attrs,
  }) as CartLine;

const router = createRouter({
  history: createMemoryHistory(),
  routes: [
    { path: "/", component: { template: "<div />" } },
    {
      path: "/catalogue/equipment/:slug/",
      name: "equipment-item",
      component: { template: "<div />" },
    },
  ],
});

// Attached, because the place menu teleports to the body.
const mount = (attrs: Partial<CartLine> = {}) =>
  mountWithDefaults<typeof Component>(Component, {
    props: { line: line(attrs) },
    plugins: [router],
    attachTo: document.body,
  });

const placeOption = async (
  wrapper: Awaited<ReturnType<typeof mount>>,
  label: (text: string) => boolean,
) => {
  await wrapper.find("[data-test='cart-line-places'] button").trigger("click");
  await flushPromises();

  return [...document.body.querySelectorAll<HTMLButtonElement>("button")].find(
    (button) => label(button.textContent?.trim() ?? ""),
  );
};

describe("CartLine", () => {
  beforeEach(() => {
    update.mockClear();
    remove.mockClear();
  });

  afterEach(() => {
    vi.useRealTimers();
    document.body.innerHTML = "";
  });

  it("shows the line total and where to buy it", async () => {
    const wrapper = await mount();

    expect(wrapper.find("a").attributes("href")).toBe(
      "/catalogue/equipment/adiva-jacket/",
    );

    expect(wrapper.find("[data-test='cart-line-total']").text()).toContain(
      "420",
    );
    expect(wrapper.text()).toContain("Casaba Outlet");
  });

  it("pins the line to another place", async () => {
    const wrapper = await mount();

    const option = await placeOption(wrapper, (text) =>
      text.includes("Garrity Defense"),
    );
    option?.click();

    expect(update).toHaveBeenCalledWith({
      id: "line-id",
      data: { itemPriceId: "dear" },
    });
  });

  it("goes back to the cheapest place", async () => {
    const wrapper = await mount({ pinned: true, price: dear });

    const option = await placeOption(wrapper, (text) => text === "Cheapest");
    option?.click();

    expect(update).toHaveBeenCalledWith({
      id: "line-id",
      data: { itemPriceId: null },
    });
  });

  it("saves a new quantity once typing stops", async () => {
    vi.useFakeTimers();
    const wrapper = await mount();

    await wrapper
      .find("[data-test='cart-line-quantity'] input")
      .setValue("5");
    vi.advanceTimersByTime(600);

    expect(update).toHaveBeenCalledWith({
      id: "line-id",
      data: { quantity: 5 },
    });
  });

  it("keeps a quantity being typed when an earlier save answers", async () => {
    vi.useFakeTimers();
    const wrapper = await mount();
    const input = wrapper.find("[data-test='cart-line-quantity'] input");

    await input.setValue("12");
    vi.advanceTimersByTime(600);
    await input.setValue("120");
    await wrapper.setProps({ line: line({ quantity: 12 }) });
    vi.advanceTimersByTime(600);

    expect(update).toHaveBeenLastCalledWith({
      id: "line-id",
      data: { quantity: 120 },
    });
  });

  it("lets a pinned line go back to the cheapest place when only one place is left", async () => {
    const wrapper = await mount({ pinned: true, price: dear, offers: [cheap] });

    const option = await placeOption(wrapper, (text) => text === "Cheapest");
    option?.click();

    expect(update).toHaveBeenCalledWith({
      id: "line-id",
      data: { itemPriceId: null },
    });
  });

  it("puts back the saved quantity when the field is left on one it cannot save", async () => {
    vi.useFakeTimers();
    const wrapper = await mount();
    const input = wrapper.find("[data-test='cart-line-quantity'] input");

    await input.setValue("0");
    vi.advanceTimersByTime(600);
    await wrapper.find(".cart-line__quantity").trigger("focusout");

    expect(update).not.toHaveBeenCalled();
    expect((input.element as HTMLInputElement).value).toBe("2");
  });

  it("removes the line", async () => {
    const wrapper = await mount();

    await wrapper.find("[data-test='cart-line-remove']").trigger("click");

    expect(remove).toHaveBeenCalledWith({ id: "line-id" });
  });

  it("shows no price for an item nobody sells", async () => {
    const wrapper = await mount({
      available: false,
      price: null,
      unitPrice: null,
      total: null,
      offers: [],
    });

    expect(wrapper.find("[data-test='cart-line-total']").exists()).toBe(false);
    expect(wrapper.find("[data-test='cart-line-places']").exists()).toBe(false);
  });
});
