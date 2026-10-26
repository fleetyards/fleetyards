import { beforeEach, describe, expect, it, vi } from "vitest";
import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { type Cart, type CartList } from "@/services/fyApi";

const mutate = vi.fn();
const emit = vi.fn();
const updateCart = vi.fn();
const displaySuccess = vi.fn();

const lists = ref<CartList[]>([]);

let mutationOptions:
  { mutation: { onSuccess: (cart: Cart) => void } } | undefined;

vi.mock("@/services/fyApi", async (importOriginal) => ({
  ...(await importOriginal<Record<string, unknown>>()),
  useCartLists: () => ({ data: lists }),
  useAddCartItems: (options: typeof mutationOptions) => {
    mutationOptions = options;

    return { mutate, isPending: ref(false) };
  },
}));

vi.mock("@/frontend/composables/useCartCache", () => ({
  useCartCache: () => ({ updateCart }),
}));

vi.mock("@/shared/composables/useComlink", () => ({
  useComlink: () => ({ emit }),
}));

vi.mock("@/shared/composables/useAppNotifications", () => ({
  useAppNotifications: () => ({ displaySuccess, displayAlert: vi.fn() }),
}));

const Component = (await import("./index.vue")).default;

const list = (id: string, active = false, itemsCount = 0) =>
  ({ id, name: `List ${id}`, active, itemsCount }) as CartList;

const items = [{ itemType: "Equipment" as const, itemId: "jacket" }];

const mount = () =>
  mountWithDefaults<typeof Component>(Component, {
    props: { name: "Adiva Jacket", items },
  });

describe("CartPickListModal", () => {
  beforeEach(() => {
    lists.value = [list("b", false, 2), list("a", true, 5)];
    mutate.mockClear();
    emit.mockClear();
    updateCart.mockClear();
    displaySuccess.mockClear();
  });

  it("offers every list, the active one first", async () => {
    const wrapper = await mount();

    expect(
      wrapper.findAll(".add-to-hangar-choice__title").map((el) => el.text()),
    ).toEqual(["List a", "List b"]);
  });

  it("adds to the picked list", async () => {
    const wrapper = await mount();

    await wrapper.find("[data-test='cart-pick-b']").trigger("click");

    expect(mutate).toHaveBeenCalledWith({ data: { items, cartId: "b" } });
  });

  it("closes once the list has it", async () => {
    await mount();
    const cart = { id: "b", name: "List b", active: false } as Cart;

    mutationOptions?.mutation.onSuccess(cart);

    expect(updateCart).toHaveBeenCalledWith(cart);
    expect(displaySuccess).toHaveBeenCalled();
    expect(emit).toHaveBeenCalledWith("close-modal", true);
  });
});
