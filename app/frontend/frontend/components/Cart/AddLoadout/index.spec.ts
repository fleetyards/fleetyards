import { beforeEach, describe, expect, it, vi } from "vitest";
import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { type LoadoutComponentRef, type LoadoutSlot } from "@/services/fyApi";

const mutate = vi.fn();
const displayWarning = vi.fn();

const authenticated = { value: true };
const enabled = { value: true };

vi.mock("@/services/fyApi", async (importOriginal) => ({
  ...(await importOriginal<Record<string, unknown>>()),
  useAddCartItems: () => ({ mutate, isPending: ref(false) }),
}));

vi.mock("@/frontend/components/Cart/ListMenu/index.vue", () => ({
  default: {
    name: "CartListMenu",
    emits: ["pick"],
    template:
      "<button data-test='cart-list-pick' @click=\"$emit('pick', 'list-b')\" />",
  },
}));

vi.mock("@/frontend/composables/useFeatures", () => ({
  useFeatures: () => ({ isFeatureEnabled: () => enabled.value }),
}));

vi.mock("@/frontend/composables/useCartCache", () => ({
  useCartCache: () => ({ updateCart: vi.fn() }),
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
    displaySuccess: vi.fn(),
    displayWarning,
    displayAlert: vi.fn(),
  }),
}));

const Component = (await import("./index.vue")).default;

const part = (id: string) => ({ id, name: id }) as LoadoutComponentRef;

const slot = (stock: string, fitted?: string): LoadoutSlot => ({
  name: "hardpoint",
  hardpointId: "hp",
  types: [],
  editable: true,
  slots: [],
  stock: part(stock),
  fitted: fitted ? part(fitted) : undefined,
});

const mount = (slots: LoadoutSlot[]) =>
  mountWithDefaults<typeof Component>(Component, { props: { slots } });

describe("CartAddLoadout", () => {
  beforeEach(() => {
    authenticated.value = true;
    enabled.value = true;
    mutate.mockClear();
    displayWarning.mockClear();
  });

  it("adds every non-stock part in one request", async () => {
    const wrapper = await mount([
      slot("stock-gun", "panther"),
      slot("stock-gun", "panther"),
      slot("stock-cooler"),
    ]);

    await wrapper.find("[data-test='cart-add-loadout']").trigger("click");

    expect(mutate).toHaveBeenCalledWith({
      data: {
        items: [{ itemType: "Component", itemId: "panther", quantity: 2 }],
        cartId: undefined,
      },
    });
  });

  it("adds to another list when one is picked from the menu", async () => {
    const wrapper = await mount([slot("stock-gun", "panther")]);

    await wrapper.find("[data-test='cart-list-pick']").trigger("click");

    expect(mutate).toHaveBeenCalledWith({
      data: {
        items: [{ itemType: "Component", itemId: "panther", quantity: 1 }],
        cartId: "list-b",
      },
    });
  });

  it("is not shown for a stock loadout", async () => {
    const wrapper = await mount([slot("stock-gun")]);

    expect(wrapper.find("[data-test='cart-add-loadout']").exists()).toBe(false);
  });

  it("asks an anonymous reader to sign in", async () => {
    authenticated.value = false;
    const wrapper = await mount([slot("stock-gun", "panther")]);

    await wrapper.find("[data-test='cart-add-loadout']").trigger("click");

    expect(mutate).not.toHaveBeenCalled();
    expect(displayWarning).toHaveBeenCalled();
  });

  it("is not shown while the feature is off", async () => {
    enabled.value = false;
    const wrapper = await mount([slot("stock-gun", "panther")]);

    expect(wrapper.find("[data-test='cart-add-loadout']").exists()).toBe(false);
  });
});
