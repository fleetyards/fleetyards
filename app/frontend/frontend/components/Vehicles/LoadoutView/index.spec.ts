import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { describe, expect, it, vi } from "vitest";
import { ref } from "vue";
import {
  FeatureFlagName,
  type Vehicle,
  type VehicleLoadoutMinimal,
} from "@/services/fyApi";
import Component from "./index.vue";

const resolved = () => ({
  isPending: ref(false),
  isFetching: ref(false),
  isLoading: ref(false),
  isRefetching: ref(false),
  error: ref(undefined),
});

vi.mock("@/services/fyApi", async (importOriginal) => ({
  ...(await importOriginal<Record<string, unknown>>()),
  useModelModules: () => ({
    data: ref({
      items: [
        {
          id: "m1",
          name: "Cargo Module",
          slot: "hardpoint_front_module",
          metrics: { cargo: 32 },
        },
        { id: "m2", name: "Living Module", slot: "hardpoint_rear_module" },
        { id: "m3", name: "Spare Module", slot: "hardpoint_rear_module" },
      ],
    }),
    ...resolved(),
  }),
}));

const openLoadoutModal = vi.fn();

const enabledFlags = ref<FeatureFlagName[]>([FeatureFlagName.LOADOUT_EDITOR]);

vi.mock("@/frontend/composables/useFeatures", () => ({
  useFeatures: () => ({
    isFeatureEnabled: (flag: FeatureFlagName) =>
      enabledFlags.value.includes(flag),
  }),
}));

vi.mock("@/frontend/composables/useVehicleModals", () => ({
  useVehicleModals: () => ({ openLoadoutModal }),
}));

const vehicle = {
  id: "v1",
  modelModuleIds: ["m1", "m2", "m3"],
  modelUpgradeIds: ["u1"],
  model: {
    name: "Retaliator",
    slug: "retaliator",
    media: {},
    metrics: { cargo: 100 },
  },
} as unknown as Vehicle;

const loadout = {
  id: "l1",
  name: "Hauler",
  kind: "fleetyards",
  active: true,
  items: [
    {
      slotPath: "hardpoint_rear_module",
      itemType: "ModelModule",
      itemId: "m2",
    },
    {
      slotPath: "hardpoint_front_module",
      itemType: "ModelModule",
      itemId: "m1",
    },
  ],
} as unknown as VehicleLoadoutMinimal;

describe("VehicleLoadoutView", () => {
  it("lists what is fitted, slot by slot, and nothing it merely owns", async () => {
    const wrapper = await mountWithDefaults(Component, {
      props: { vehicle, loadout },
    });

    const fitted = wrapper
      .findAll("[data-test='vehicle-loadout-view-item']")
      .map((row) => row.text());
    expect(fitted[0]).toContain("Cargo Module");
    expect(fitted[1]).toContain("Living Module");
    expect(wrapper.text()).not.toContain("Spare Module");
  });

  it("counts the fitted cargo in the ship's stats", async () => {
    const wrapper = await mountWithDefaults(Component, {
      props: { vehicle, loadout },
    });

    expect(wrapper.get("[data-test='vehicle-specs']").text()).toContain("132");
  });

  it("says when nothing is fitted", async () => {
    const wrapper = await mountWithDefaults(Component, {
      props: { vehicle },
    });

    expect(
      wrapper.find("[data-test='vehicle-loadout-view-empty']").exists(),
    ).toBe(true);
  });

  it("takes the owner into the editor on this loadout", async () => {
    const wrapper = await mountWithDefaults(Component, {
      props: { vehicle, loadout, editable: true },
    });

    await wrapper
      .get("[data-test='vehicle-loadout-view-edit']")
      .trigger("click");

    expect(openLoadoutModal).toHaveBeenCalledWith(vehicle, {
      editable: true,
      loadoutId: "l1",
      tab: "modules",
    });
  });

  it("offers the owner no way in until the editor is switched on", async () => {
    enabledFlags.value = [];
    const wrapper = await mountWithDefaults(Component, {
      props: { vehicle, loadout, editable: true },
    });

    expect(
      wrapper.find("[data-test='vehicle-loadout-view-edit']").exists(),
    ).toBe(false);
    enabledFlags.value = [FeatureFlagName.LOADOUT_EDITOR];
  });

  it("offers a visitor no way to edit", async () => {
    const wrapper = await mountWithDefaults(Component, {
      props: { vehicle, loadout },
    });

    expect(
      wrapper.find("[data-test='vehicle-loadout-view-edit']").exists(),
    ).toBe(false);
  });
});
