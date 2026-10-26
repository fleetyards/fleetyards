import { beforeEach, describe, expect, it, vi } from "vitest";
import { mountWithDefaults } from "@/shared/utils/TestUtils";
import {
  type Cart,
  type CartList,
  InventoryItemTypeEnum,
} from "@/services/fyApi";

const mutate = vi.fn();
const updateCart = vi.fn();
const emit = vi.fn();
const displaySuccess = vi.fn();
const displayWarning = vi.fn();

const authenticated = { value: true };
const enabled = { value: true };
const lists = ref<CartList[]>([]);

let mutationOptions:
  { mutation: { onSuccess: (cart: Cart) => void } } | undefined;

vi.mock("@/services/fyApi", async (importOriginal) => ({
  ...(await importOriginal<Record<string, unknown>>()),
  useCartLists: () => ({ data: lists }),
  useAddCartItem: (options: typeof mutationOptions) => {
    mutationOptions = options;

    return { mutate, isPending: ref(false) };
  },
}));

vi.mock("@/frontend/composables/useFeatures", () => ({
  useFeatures: () => ({ isFeatureEnabled: () => enabled.value }),
}));

vi.mock("@/frontend/composables/useCartCache", () => ({
  useCartCache: () => ({ updateCart }),
}));

vi.mock("@/shared/composables/useComlink", () => ({
  useComlink: () => ({ emit }),
}));

vi.mock("@/frontend/stores/session", () => ({
  useSessionStore: () => ({
    get isAuthenticated() {
      return authenticated.value;
    },
  }),
}));

vi.mock("@/shared/composables/useAppNotifications", () => ({
  useAppNotifications: () => ({
    displaySuccess,
    displayWarning,
    displayAlert: vi.fn(),
  }),
}));

const Component = (await import("./index.vue")).default;

const item = {
  id: "item-id",
  type: InventoryItemTypeEnum.EQUIPMENT,
  name: "Adiva Jacket",
};

const list = (id: string, active = false) =>
  ({ id, name: `List ${id}`, active, itemsCount: 0 }) as CartList;

const mount = () =>
  mountWithDefaults<typeof Component>(Component, { props: { item } });

describe("CartAddToCart", () => {
  beforeEach(() => {
    authenticated.value = true;
    enabled.value = true;
    lists.value = [list("a", true)];
    mutate.mockClear();
    emit.mockClear();
    updateCart.mockClear();
    displaySuccess.mockClear();
    displayWarning.mockClear();
  });

  it("is an icon alone", async () => {
    const wrapper = await mount();

    expect(wrapper.find("[data-test='cart-add']").text()).toBe("");
  });

  it("adds one of the item right away with a single list", async () => {
    const wrapper = await mount();

    await wrapper.find("[data-test='cart-add']").trigger("click");

    expect(mutate).toHaveBeenCalledWith({
      data: { itemType: "Equipment", itemId: "item-id", quantity: 1 },
    });
    expect(emit).not.toHaveBeenCalled();
  });

  it("asks which list with more than one", async () => {
    lists.value = [list("a", true), list("b")];
    const wrapper = await mount();

    await wrapper.find("[data-test='cart-add']").trigger("click");

    expect(mutate).not.toHaveBeenCalled();
    expect(emit).toHaveBeenCalledWith(
      "open-modal",
      expect.objectContaining({
        props: {
          name: "Adiva Jacket",
          items: [{ itemType: "Equipment", itemId: "item-id" }],
        },
      }),
    );
  });

  it("takes the answer as the new cart", async () => {
    await mount();
    const cart = { items: [], name: "List a" } as unknown as Cart;

    mutationOptions?.mutation.onSuccess(cart);

    expect(updateCart).toHaveBeenCalledWith(cart);
    expect(displaySuccess).toHaveBeenCalled();
  });

  it("asks an anonymous reader to sign in", async () => {
    authenticated.value = false;
    const wrapper = await mount();

    await wrapper.find("[data-test='cart-add']").trigger("click");

    expect(mutate).not.toHaveBeenCalled();
    expect(displayWarning).toHaveBeenCalled();
  });

  it("is not shown while the feature is off", async () => {
    enabled.value = false;
    const wrapper = await mount();

    expect(wrapper.find("[data-test='cart-add']").exists()).toBe(false);
  });
});
