import { describe, expect, it, vi } from "vitest";
import { mount } from "@vue/test-utils";

vi.mock("@/shared/composables/useI18n", () => ({
  useI18n: () => ({ t: (key: string) => key }),
}));

vi.mock("@/shared/composables/useComlink", () => ({
  useComlink: () => ({ emit: vi.fn() }),
}));

import TransferAcceptModal from "./index.vue";

const INVENTORIES = [
  { id: "cargo", name: "Cargo" },
  { id: "locker", name: "Locker" },
];

const mountModal = (contract: Record<string, unknown> | null) =>
  mount(TransferAcceptModal, {
    props: {
      transfer: { id: "t-1", contract } as never,
      inventories: INVENTORIES as never,
      onAccept: vi.fn(),
    },
    global: {
      stubs: {
        Modal: { template: "<div><slot /><slot name='footer' /></div>" },
        BaseSelect: true,
        Btn: true,
      },
    },
  });

const selected = (wrapper: ReturnType<typeof mountModal>) =>
  (wrapper.vm as unknown as { inventoryId?: string }).inventoryId;

describe("TransferAcceptModal", () => {
  // A contract delivery only counts where the contract collects it.
  it("opens on the inventory the contract delivers into", () => {
    expect(
      selected(mountModal({ id: "c-1", destinationInventoryId: "locker" })),
    ).toBe("locker");
  });

  it("opens on the first inventory otherwise", () => {
    expect(selected(mountModal(null))).toBe("cargo");
    expect(
      selected(mountModal({ id: "c-1", destinationInventoryId: null })),
    ).toBe("cargo");
  });
});
