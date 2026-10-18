import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { describe, expect, it, vi } from "vitest";
import { ref } from "vue";
import {
  FeatureFlagName,
  ModelProductionStatusEnum,
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

const loadoutSlots = ref<unknown[]>([]);
const slotsLoading = ref(false);
const loadoutProblems = ref<unknown[]>([]);
const hullSlots = ref<unknown[]>([]);
const modelHardpoints = ref<unknown[]>([]);
// Whether the cargo module is the one the ship comes with.
const cargoStock = ref(false);

vi.mock("@/services/fyApi", async (importOriginal) => ({
  ...(await importOriginal<Record<string, unknown>>()),
  useVehicleLoadoutSlots: () => ({
    data: loadoutSlots,
    ...resolved(),
    isLoading: slotsLoading,
  }),
  useVehicleLoadoutProblems: () => ({ data: loadoutProblems, ...resolved() }),
  useModelLoadoutSlots: () => ({ data: hullSlots, ...resolved() }),
  useModelHardpoints: () => ({ data: modelHardpoints, ...resolved() }),
  useModelModules: () => ({
    data: ref({
      items: [
        {
          id: "m1",
          name: "Cargo Module",
          slot: "hardpoint_front_module",
          metrics: { cargo: 32 },
          stock: cargoStock.value,
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
    productionStatus: ModelProductionStatusEnum.FLIGHT_READY,
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

  it("sums up what the modules change against the stock ship", async () => {
    const wrapper = await mountWithDefaults(Component, {
      props: { vehicle, loadout },
    });

    expect(
      wrapper.get("[data-test='vehicle-loadout-view-changes-cargo']").text(),
    ).toContain("+32");
  });

  it("counts no change for the module the ship comes with", async () => {
    cargoStock.value = true;

    const wrapper = await mountWithDefaults(Component, {
      props: { vehicle, loadout },
    });

    expect(
      wrapper.find("[data-test='vehicle-loadout-view-changes-cargo']").exists(),
    ).toBe(false);

    cargoStock.value = false;
  });

  it("sums up what a swapped part changes, by the editor's figures, for the owner", async () => {
    const shield = (id: string, name: string, maxHealth: number) => ({
      id,
      name,
      size: "1",
      category: "shieldgenerator",
      type: "Shield",
      typeData: { maxHealth, maxRegen: 100 },
    });
    const stock = shield("s1", "Stock Shield", 1000);
    const better = shield("s2", "Better Shield", 3000);
    const slot = {
      name: "hardpoint_shield_generator",
      hardpointId: "hull-shield",
      category: "shieldgenerator",
      minSize: 1,
      maxSize: 1,
      types: ["Shield"],
      editable: true,
      stock,
      slots: [],
    };
    hullSlots.value = [slot];
    loadoutSlots.value = [{ ...slot, fitted: better }];
    modelHardpoints.value = [
      {
        id: "hp-shield",
        name: "hardpoint_shield_generator",
        category: "shieldgenerator",
        component: stock,
        hardpoints: [],
      },
    ];

    const wrapper = await mountWithDefaults(Component, {
      props: {
        vehicle,
        loadout: {
          ...loadout,
          items: [
            {
              slotPath: "hardpoint_shield_generator",
              itemType: "Component",
              itemId: "s2",
            },
          ],
        },
        editable: true,
      },
    });

    expect(
      wrapper.get("[data-test='vehicle-loadout-view-changes-shieldHp']").text(),
    ).toContain("+2");

    hullSlots.value = [];
    loadoutSlots.value = [];
    modelHardpoints.value = [];
  });

  it("marks the parts that differ from the stock ship", async () => {
    const wrapper = await mountWithDefaults(Component, {
      props: { vehicle, loadout },
    });

    const items = wrapper.findAll("[data-test='vehicle-loadout-view-item']");
    expect(items[0].attributes("data-changed")).toBeDefined();
  });

  it("holds the changes and the fitted parts open while they load", async () => {
    slotsLoading.value = true;

    const wrapper = await mountWithDefaults(Component, {
      props: { vehicle, loadout, editable: true },
    });

    expect(
      wrapper
        .find("[data-test='vehicle-loadout-view-changes-skeleton']")
        .exists(),
    ).toBe(true);
    expect(
      wrapper
        .find("[data-test='vehicle-loadout-view-fitted-skeleton']")
        .exists(),
    ).toBe(true);
    expect(
      wrapper.find("[data-test='vehicle-loadout-view-empty']").exists(),
    ).toBe(false);

    slotsLoading.value = false;
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

  it("offers the owner no way in on a ship that is not flight ready", async () => {
    const wrapper = await mountWithDefaults(Component, {
      props: {
        vehicle: {
          ...vehicle,
          model: {
            ...vehicle.model,
            productionStatus: ModelProductionStatusEnum.IN_CONCEPT,
          },
        },
        loadout,
        editable: true,
      },
    });

    expect(
      wrapper.find("[data-test='vehicle-loadout-view-edit']").exists(),
    ).toBe(false);
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

describe("VehicleLoadoutView components", () => {
  it("tells the owner which items a new build refuses, and marks the ones still listed in red", async () => {
    loadoutProblems.value = [
      {
        slotPath: "hardpoint_rear_module",
        itemType: "ModelModule",
        itemId: "m2",
        itemName: "Living Module",
        code: "module_not_in_slot",
      },
      {
        slotPath: "hardpoint_gone",
        itemType: "Component",
        itemId: "x1",
        itemName: "Gone Gun",
        code: "slot_unknown",
      },
    ];

    const wrapper = await mountWithDefaults(Component, {
      props: { vehicle, loadout, editable: true },
    });

    const notice = wrapper.get("[data-test='vehicle-loadout-view-refused']");
    expect(notice.text()).toContain("Living Module");
    expect(notice.text()).toContain("Gone Gun");
    const living = wrapper
      .findAll("[data-test='vehicle-loadout-view-item']")
      .find((row) => row.text().includes("Living Module"));
    expect(living?.attributes("data-refused")).toBe("true");

    loadoutProblems.value = [];
  });

  it("lists the parts swapped in, by category, for the owner", async () => {
    loadoutSlots.value = [
      {
        name: "hardpoint_gun_nose",
        hardpointId: "hull-nose",
        category: "weapon_mounts",
        types: ["Turret"],
        editable: true,
        stock: { id: "g1", name: "Stock Gimbal" },
        slots: [
          {
            name: "hardpoint_class_2",
            hardpointId: "port",
            category: "weapons",
            types: ["WeaponGun"],
            editable: true,
            stock: { id: "gun1", name: "Stock Gun" },
            fitted: { id: "gun2", name: "Other Gun", size: "3" },
            slots: [],
          },
        ],
      },
    ];

    const wrapper = await mountWithDefaults(Component, {
      props: { vehicle, loadout, editable: true },
    });

    const section = wrapper.get("[data-test='vehicle-loadout-view-weapons']");
    expect(section.text()).toContain("Other Gun");
    expect(section.text()).not.toContain("Stock Gimbal");

    loadoutSlots.value = [];
  });

  it("lists a part swapped in inside a fitted module under its category", async () => {
    loadoutSlots.value = [
      {
        name: "hardpoint_module",
        hardpointId: "hull-module",
        category: "module",
        types: ["Module"],
        editable: true,
        slots: [
          {
            name: "hardpoint_shield_generator_module",
            hardpointId: "module-shield",
            category: "shieldgenerator",
            types: ["Shield"],
            editable: true,
            stock: { id: "s1", name: "Module Shield" },
            fitted: { id: "s2", name: "Better Shield", size: "1" },
            slots: [],
          },
        ],
      },
    ];

    const wrapper = await mountWithDefaults(Component, {
      props: { vehicle, loadout, editable: true },
    });

    expect(
      wrapper.get("[data-test='vehicle-loadout-view-shields']").text(),
    ).toContain("Better Shield");

    loadoutSlots.value = [];
  });
});
