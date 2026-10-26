import { beforeEach, describe, expect, it, vi } from "vitest";
import { mountWithDefaults } from "@/shared/utils/TestUtils";
import {
  type Cart,
  type CartList,
  type Fleet,
  type FleetShoppingList,
} from "@/services/fyApi";

const mutate = vi.fn();
const emit = vi.fn();
const updateCart = vi.fn();
const refreshCarts = vi.fn();
const displaySuccess = vi.fn();

const lists = ref<CartList[]>([]);

let mutationOptions:
  { mutation: { onSuccess: (cart: Cart) => void } } | undefined;

vi.mock("@/services/fyApi", async (importOriginal) => ({
  ...(await importOriginal<Record<string, unknown>>()),
  useCartLists: () => ({ data: lists }),
  useCopyFleetShoppingList: (options: typeof mutationOptions) => {
    mutationOptions = options;

    return { mutate, isPending: ref(false) };
  },
}));

vi.mock("@/frontend/composables/useCartCache", () => ({
  useCartCache: () => ({ updateCart, refreshCarts }),
}));

vi.mock("@/shared/composables/useComlink", () => ({
  useComlink: () => ({ emit }),
}));

vi.mock("@/shared/composables/useAppNotifications", () => ({
  useAppNotifications: () => ({ displaySuccess, displayAlert: vi.fn() }),
}));

const Component = (await import("./index.vue")).default;

const fleet = { slug: "merc" } as Fleet;
const list = { id: "kit", name: "Standard kit" } as FleetShoppingList;

const cartList = (id: string, active = false) =>
  ({ id, name: `List ${id}`, active, itemsCount: 1 }) as CartList;

const mount = () =>
  mountWithDefaults<typeof Component>(Component, { props: { fleet, list } });

describe("FleetShoppingListCopyModal", () => {
  beforeEach(() => {
    lists.value = [cartList("b"), cartList("a", true)];
    mutate.mockClear();
    emit.mockClear();
    updateCart.mockClear();
    refreshCarts.mockClear();
  });

  it("offers a new list first, then the user's lists with the active one leading", async () => {
    const wrapper = await mount();

    expect(
      wrapper.findAll(".add-to-hangar-choice__title").map((el) => el.text()),
    ).toEqual(["A new list", "List a", "List b"]);
  });

  it("copies into a new list when that is picked", async () => {
    const wrapper = await mount();

    await wrapper
      .find("[data-test='fleet-shopping-list-copy-new']")
      .trigger("click");

    expect(mutate).toHaveBeenCalledWith({
      fleetSlug: "merc",
      id: "kit",
      data: {},
    });
  });

  it("copies into the picked list", async () => {
    const wrapper = await mount();

    await wrapper
      .find("[data-test='fleet-shopping-list-copy-b']")
      .trigger("click");

    expect(mutate).toHaveBeenCalledWith({
      fleetSlug: "merc",
      id: "kit",
      data: { cartId: "b" },
    });
  });

  it("updates the cart and closes once copied", async () => {
    await mount();
    const cart = { id: "c", name: "Standard kit", active: true } as Cart;

    mutationOptions?.mutation.onSuccess(cart);

    expect(updateCart).toHaveBeenCalledWith(cart);
    expect(refreshCarts).toHaveBeenCalled();
    expect(displaySuccess).toHaveBeenCalled();
    expect(emit).toHaveBeenCalledWith("close-modal", true);
  });
});
