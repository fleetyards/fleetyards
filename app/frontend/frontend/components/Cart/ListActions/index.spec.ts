import { beforeEach, describe, expect, it, vi } from "vitest";
import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { type CartList } from "@/services/fyApi";

const update = vi.fn();
const destroy = vi.fn();
const clear = vi.fn();
const replace = vi.fn();
const displayConfirm = vi.fn();

const lists = ref<CartList[]>([]);

vi.mock("vue-router", async (importOriginal) => ({
  ...(await importOriginal<Record<string, unknown>>()),
  useRoute: () => ({ query: {} }),
  useRouter: () => ({ replace }),
}));

vi.mock("@/services/fyApi", async (importOriginal) => ({
  ...(await importOriginal<Record<string, unknown>>()),
  useCartLists: () => ({ data: lists }),
  useUpdateCartList: () => ({ mutate: update, isPending: ref(false) }),
  useDestroyCartList: () => ({ mutate: destroy, isPending: ref(false) }),
  useClearCartList: () => ({ mutate: clear, isPending: ref(false) }),
}));

vi.mock("@/frontend/composables/useCartCache", () => ({
  useCartCache: () => ({ refreshCarts: vi.fn(), updateCart: vi.fn() }),
}));

vi.mock("@/shared/composables/useAppNotifications", () => ({
  useAppNotifications: () => ({ displayConfirm, displayAlert: vi.fn() }),
}));

const Component = (await import("./index.vue")).default;

const list = (id: string, active = false): CartList => ({
  id,
  name: `List ${id}`,
  active,
  itemsCount: 0,
  createdAt: "2026-10-26T10:00:00Z",
  updatedAt: "2026-10-26T10:00:00Z",
});

const mount = (listId = "a") =>
  mountWithDefaults<typeof Component>(Component, { props: { listId } });

describe("CartListActions", () => {
  beforeEach(() => {
    lists.value = [list("a", true), list("b")];
    update.mockClear();
    destroy.mockClear();
    clear.mockClear();
    document.body.innerHTML = "";
    replace.mockClear();
    displayConfirm.mockClear();
  });

  it("makes the shown list the active one", async () => {
    const wrapper = await mount("b");

    await wrapper.find("[data-test='cart-list-activate']").trigger("click");

    expect(update).toHaveBeenCalledWith(
      { id: "b", data: { active: true } },
      expect.anything(),
    );
  });

  it("marks the active list instead of offering to activate it", async () => {
    const wrapper = await mount("a");

    expect(wrapper.find("[data-test='cart-list-activate']").exists()).toBe(
      false,
    );
    expect(wrapper.find("[data-test='cart-list-active']").exists()).toBe(true);
  });

  // The list's own actions sit in a dropdown, whose menu renders into the body.
  const menuItem = (name: string) =>
    document.body.querySelector<HTMLElement>(`[data-test='${name}']`);

  it("deletes the shown list once confirmed", async () => {
    await mount("b");

    menuItem("cart-list-delete")?.click();
    displayConfirm.mock.calls[0][0].onConfirm();

    expect(destroy).toHaveBeenCalledWith({ id: "b" });
  });

  it("clears the shown list once confirmed", async () => {
    await mountWithDefaults<typeof Component>(Component, {
      props: { listId: "b", hasItems: true },
    });

    menuItem("cart-clear")?.click();
    displayConfirm.mock.calls[0][0].onConfirm();

    expect(clear).toHaveBeenCalledWith({ id: "b" });
  });

  it("has no list actions before any list exists", async () => {
    lists.value = [];
    const wrapper = await mount();

    expect(wrapper.find("[data-test='cart-list-menu-actions']").exists()).toBe(
      false,
    );
  });
});
