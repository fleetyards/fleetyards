import { QueryClient } from "@tanstack/vue-query";
import { AxiosError, type AxiosResponse } from "axios";
import { createPinia, setActivePinia } from "pinia";
import { beforeEach, describe, expect, it, vi } from "vitest";
import { useNotificationsStore } from "@/shared/stores/notifications";
import { useInventoryDestroy } from "./useInventoryDestroy";

const queryClient = new QueryClient();

vi.mock("@tanstack/vue-query", async (importOriginal) => ({
  ...(await importOriginal<Record<string, unknown>>()),
  useQueryClient: () => queryClient,
}));

vi.mock("@/shared/composables/useI18n", () => ({
  useI18n: () => ({ t: (key: string) => key }),
}));

const listKey = ["hangar", "inventories"] as const;
const itemsKey = ["hangar", "inventories", "north-locker", "items"] as const;

const texts = () => useNotificationsStore().messages.map(({ text }) => text);

const refusal = (message: string) =>
  new AxiosError("Bad Request", "400", undefined, undefined, {
    status: 400,
    data: {
      code: "hangar_inventories.destroy",
      errors: [{ attribute: "base", messages: [{ message }] }],
    },
  } as AxiosResponse);

const subject = (destroy: () => Promise<unknown>, onDeleted = vi.fn()) =>
  useInventoryDestroy({
    inventory: () => ({ id: "inventory-1" }),
    destroy,
    listKey: () => listKey,
    onDeleted,
  });

beforeEach(() => {
  setActivePinia(createPinia());
  queryClient.clear();
});

describe("useInventoryDestroy", () => {
  it("takes the deleted inventory out of the cached list", async () => {
    queryClient.setQueryData(listKey, {
      items: [{ id: "inventory-1" }, { id: "inventory-2" }],
    });
    const onDeleted = vi.fn();

    await subject(() => Promise.resolve(), onDeleted).destroyInventory();

    expect(queryClient.getQueryData(listKey)).toEqual({
      items: [{ id: "inventory-2" }],
    });
    expect(onDeleted).toHaveBeenCalledOnce();
    expect(texts()).toEqual(["messages.logistics.inventory.destroy.success"]);
  });

  // The list key prefixes the item lists too, whose rows are no inventories.
  it("leaves the rows of other lists under the same key alone", async () => {
    queryClient.setQueryData(itemsKey, { items: [{ id: "item-1" }] });

    await subject(() => Promise.resolve()).destroyInventory();

    expect(queryClient.getQueryData(itemsKey)).toEqual({
      items: [{ id: "item-1" }],
    });
  });

  it("names why the API refused", async () => {
    queryClient.setQueryData(listKey, { items: [{ id: "inventory-1" }] });
    const onDeleted = vi.fn();
    const destroy = subject(
      () => Promise.reject(refusal("A contract still delivers here.")),
      onDeleted,
    );

    await destroy.destroyInventory();

    expect(texts()).toEqual(["A contract still delivers here."]);
    expect(onDeleted).not.toHaveBeenCalled();
    expect(queryClient.getQueryData(listKey)).toEqual({
      items: [{ id: "inventory-1" }],
    });
    expect(destroy.deleting.value).toBe(false);
  });

  it("falls back to the generic failure without a reason", async () => {
    await subject(() =>
      Promise.reject(new Error("offline")),
    ).destroyInventory();

    expect(texts()).toEqual(["messages.logistics.inventory.destroy.failure"]);
  });
});
