import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { describe, expect, it, vi } from "vitest";
import { flushPromises } from "@vue/test-utils";
import { ModelProductionStatusEnum, type Vehicle } from "@/services/fyApi";
import Component from "./loadouts.vue";

const { updateLoadout, loadouts, mutation, displayAlert } = vi.hoisted(() => ({
  displayAlert: vi.fn(),
  mutation:
    (mutateAsync = vi.fn(() => Promise.resolve())) =>
    () => ({
      mutateAsync,
      isPending: ref(false),
    }),
  updateLoadout: vi.fn(() => Promise.resolve()),
  loadouts: [
    {
      id: "l1",
      name: "Hauler",
      kind: "fleetyards",
      active: true,
      public: false,
      items: [],
      createdAt: "2026-10-01T00:00:00Z",
      updatedAt: "2026-10-01T00:00:00Z",
    },
    {
      id: "l2",
      name: "Brawler",
      kind: "fleetyards",
      active: false,
      public: true,
      items: [],
      createdAt: "2026-10-01T00:00:00Z",
      updatedAt: "2026-10-01T00:00:00Z",
    },
  ],
}));

vi.mock("@/services/fyApi", async (importOriginal) => ({
  ...(await importOriginal<Record<string, unknown>>()),
  useVehicleLoadouts: () => ({ data: ref(loadouts), isLoading: ref(false) }),
  useCreateVehicleLoadout: mutation(),
  useUpdateVehicleLoadout: mutation(updateLoadout),
  useDestroyVehicleLoadout: mutation(),
  useActivateVehicleLoadout: mutation(),
}));

// The desktop row, whose actions sit in the row rather than a menu.
vi.mock("@/shared/composables/useMobile", () => ({
  useMobile: () => ref(false),
}));

vi.mock("@/frontend/composables/useFeatures", () => ({
  useFeatures: () => ({ isFeatureEnabled: () => true }),
}));

vi.mock("@/shared/composables/useAppNotifications", () => ({
  useAppNotifications: () => ({ displayAlert, displayConfirm: vi.fn() }),
}));

vi.mock("@/frontend/composables/useVehicleMutations", () => ({
  useVehicleMutations: () => ({ invalidateVehiclePage: vi.fn() }),
}));

const vehicle = {
  id: "v1",
  model: {
    slug: "scorpius",
    productionStatus: ModelProductionStatusEnum.FLIGHT_READY,
  },
} as unknown as Vehicle;

describe("HangarVehicleLoadoutsPage", () => {
  it("marks the public loadouts and switches a loadout's visibility", async () => {
    const wrapper = await mountWithDefaults(Component, {
      props: { vehicle },
    });

    expect(wrapper.find("[data-test='loadout-public-l1']").exists()).toBe(
      false,
    );
    expect(wrapper.find("[data-test='loadout-public-l2']").exists()).toBe(true);

    await wrapper.get("[data-test='loadout-visibility-l1']").trigger("click");
    await flushPromises();

    expect(updateLoadout).toHaveBeenCalledWith({
      vehicleId: "v1",
      id: "l1",
      data: { public: true },
    });
  });

  it("says so when a visibility switch fails", async () => {
    updateLoadout.mockImplementationOnce(() => Promise.reject(new Error("x")));
    const wrapper = await mountWithDefaults(Component, {
      props: { vehicle },
    });

    await wrapper.get("[data-test='loadout-visibility-l2']").trigger("click");
    await flushPromises();

    expect(displayAlert).toHaveBeenCalled();
  });

  it("starts a new loadout on a ship without modules, which still has parts to fit", async () => {
    const wrapper = await mountWithDefaults(Component, {
      props: { vehicle },
    });

    expect(
      wrapper
        .get("[data-test='loadouts-new-fleetyards']")
        .attributes("disabled"),
    ).toBeUndefined();
  });
});
