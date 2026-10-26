import { beforeEach, describe, expect, it, vi } from "vitest";
import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { type CartItemCreateInput, type CartList } from "@/services/fyApi";

const mutate = vi.fn();
const emit = vi.fn();
const displayWarning = vi.fn();

const authenticated = { value: true };
const enabled = { value: true };
const lists = ref<CartList[]>([]);

vi.mock("@/services/fyApi", async (importOriginal) => ({
  ...(await importOriginal<Record<string, unknown>>()),
  useCartLists: () => ({ data: lists }),
  useAddCartItems: () => ({ mutate, isPending: ref(false) }),
}));

vi.mock("@/frontend/composables/useFeatures", () => ({
  useFeatures: () => ({ isFeatureEnabled: () => enabled.value }),
}));

vi.mock("@/frontend/composables/useCartCache", () => ({
  useCartCache: () => ({ updateCart: vi.fn() }),
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
    displaySuccess: vi.fn(),
    displayWarning,
    displayAlert: vi.fn(),
  }),
}));

const Component = (await import("./index.vue")).default;

const line = (itemId: string, quantity = 1): CartItemCreateInput => ({
  itemType: "Component",
  itemId,
  quantity,
});

const list = (id: string, active = false) =>
  ({ id, name: `List ${id}`, active, itemsCount: 0 }) as CartList;

const mount = (items: CartItemCreateInput[]) =>
  mountWithDefaults<typeof Component>(Component, { props: { items } });

describe("CartAddLoadout", () => {
  beforeEach(() => {
    authenticated.value = true;
    enabled.value = true;
    lists.value = [list("a", true)];
    mutate.mockClear();
    emit.mockClear();
    displayWarning.mockClear();
  });

  it("adds every part it is given in one request with a single list", async () => {
    const wrapper = await mount([line("panther", 2)]);

    await wrapper.find("[data-test='cart-add-loadout']").trigger("click");

    expect(mutate).toHaveBeenCalledWith({
      data: { items: [line("panther", 2)] },
    });
  });

  it("asks which list with more than one", async () => {
    lists.value = [list("a", true), list("b")];
    const wrapper = await mount([line("panther", 2)]);

    await wrapper.find("[data-test='cart-add-loadout']").trigger("click");

    expect(mutate).not.toHaveBeenCalled();
    expect(emit).toHaveBeenCalledWith(
      "open-modal",
      expect.objectContaining({
        props: expect.objectContaining({ items: [line("panther", 2)] }),
      }),
    );
  });

  it("is not shown without parts to add", async () => {
    const wrapper = await mount([]);

    expect(wrapper.find("[data-test='cart-add-loadout']").exists()).toBe(false);
  });

  it("asks an anonymous reader to sign in", async () => {
    authenticated.value = false;
    const wrapper = await mount([line("panther")]);

    await wrapper.find("[data-test='cart-add-loadout']").trigger("click");

    expect(mutate).not.toHaveBeenCalled();
    expect(displayWarning).toHaveBeenCalled();
  });

  it("is not shown while the feature is off", async () => {
    enabled.value = false;
    const wrapper = await mount([line("panther")]);

    expect(wrapper.find("[data-test='cart-add-loadout']").exists()).toBe(false);
  });
});
