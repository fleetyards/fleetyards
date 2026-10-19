import { flushPromises } from "@vue/test-utils";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { createMemoryHistory, createRouter } from "vue-router";
import { mountWithDefaults } from "@/shared/utils/TestUtils";
import {
  HangarPledgeItemKindEnum,
  type AddPledgeItemsToInventoryResult,
  type HangarPledgeItem,
} from "@/services/fyApi";
import Component from "./index.vue";

const inventories = ref<{ items: { name: string; slug: string }[] }>();

const mutateAsync = vi.fn(
  (_input: unknown): Promise<AddPledgeItemsToInventoryResult> =>
    Promise.resolve({ addedPledgeItemIds: ["part"], skippedPledgeItemIds: [] }),
);

vi.mock("@/services/fyApi", async (importOriginal) => ({
  ...(await importOriginal<Record<string, unknown>>()),
  useHangarInventories: () => ({ data: inventories, isLoading: ref(false) }),
  useAddPledgeItemsToHangarInventory: () => ({
    mutateAsync,
    isPending: ref(false),
  }),
}));

const comlinkEmit = vi.fn();

vi.mock("@/shared/composables/useComlink", () => ({
  useComlink: () => ({ emit: comlinkEmit, on: vi.fn(), off: vi.fn() }),
}));

const displaySuccess = vi.fn();
const displayInfo = vi.fn();

vi.mock("@/shared/composables/useAppNotifications", () => ({
  useAppNotifications: () => ({
    displaySuccess,
    displayInfo,
    displayAlert: vi.fn(),
  }),
}));

vi.mock("@/shared/components/AppModal/Inner/index.vue", () => ({
  default: { template: "<div><slot /><slot name='footer' /></div>" },
}));

const item = (attrs: Partial<HangarPledgeItem> = {}): HangarPledgeItem => ({
  id: "part",
  rsiPledgeId: "1",
  kind: HangarPledgeItemKindEnum.SHIP_COMPONENT,
  name: "BriskAir IC-20",
  quantity: 2,
  standalone: false,
  meltable: false,
  createdAt: "2026-10-19T12:00:00Z",
  updatedAt: "2026-10-19T12:00:00Z",
  ...attrs,
});

// Unmounted after each test: the inventories are shared, and a modal left
// mounted re-renders when the next test changes them.
let mounted: { unmount: () => void } | undefined;

describe("Hangar/AddToInventoryModal", () => {
  afterEach(() => {
    mounted?.unmount();
    mounted = undefined;
  });

  beforeEach(() => {
    inventories.value = {
      items: [{ name: "Spare Parts", slug: "spare-parts" }],
    };
    mutateAsync.mockClear();
    comlinkEmit.mockClear();
    displaySuccess.mockClear();
    displayInfo.mockClear();
  });

  it("adds what is not in an inventory yet to the one picked", async () => {
    const onAdded = vi.fn();
    const wrapper = await mountWithDefaults(Component, {
      props: {
        items: [
          item(),
          item({
            id: "kept",
            name: "Sovereign IP-10",
            inventory: { name: "Spare Parts", slug: "spare-parts" },
          }),
        ],
        onAdded,
      },
    });
    mounted = wrapper;

    expect(
      wrapper.get("[data-test='add-to-inventory-items']").text(),
    ).toContain("BriskAir IC-20");
    expect(
      wrapper.find("[data-test='add-to-inventory-skipped']").exists(),
    ).toBe(true);

    await wrapper.get("form").trigger("submit");
    await flushPromises();

    expect(mutateAsync).toHaveBeenCalledWith({
      hangarInventorySlug: "spare-parts",
      data: { pledgeItemIds: ["part"] },
    });
    expect(onAdded).toHaveBeenCalled();
    expect(comlinkEmit).toHaveBeenCalledWith("close-modal", true);
  });

  it("says so when everything was already in an inventory", async () => {
    mutateAsync.mockResolvedValueOnce({
      addedPledgeItemIds: [],
      skippedPledgeItemIds: ["part"],
    });
    const wrapper = await mountWithDefaults(Component, {
      props: { items: [item()] },
    });
    mounted = wrapper;

    await wrapper.get("form").trigger("submit");
    await flushPromises();

    expect(displaySuccess).not.toHaveBeenCalled();
    expect(displayInfo).toHaveBeenCalled();
  });

  it("points to creating an inventory when there is none", async () => {
    inventories.value = { items: [] };

    // The link names the inventories page, which the shared test router lacks.
    const router = createRouter({
      history: createMemoryHistory(),
      routes: [
        { path: "/", component: { template: "<div />" } },
        {
          path: "/hangar/inventories/",
          name: "hangar-inventories",
          component: { template: "<div />" },
        },
      ],
    });

    const wrapper = await mountWithDefaults(Component, {
      plugins: [router],
      props: { items: [item()] },
    });
    mounted = wrapper;

    expect(wrapper.find("[data-test='add-to-inventory-none']").exists()).toBe(
      true,
    );
    expect(wrapper.find("form").exists()).toBe(false);
  });
});
