import { flushPromises } from "@vue/test-utils";
import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { beforeEach, describe, expect, it, vi } from "vitest";
import { ref } from "vue";
import type { ModelModule, Vehicle } from "@/services/fyApi";
import Component from "./index.vue";
import { categoryIcon } from "@/frontend/components/Models/Hardpoints/categoryIcon";

const modules = ref<{ items: ModelModule[] }>({
  items: [
    {
      id: "m1",
      name: "Cargo Module",
      slug: "cargo",
      slot: "hardpoint_module",
      metrics: { cargo: 32 },
    },
    {
      id: "m2",
      name: "Combat Module",
      slug: "combat",
      slot: "hardpoint_module",
    },
  ] as unknown as ModelModule[],
});

const loadouts = ref<unknown[]>([]);

const resolved = () => ({
  isPending: ref(false),
  isFetching: ref(false),
  isLoading: ref(false),
  isRefetching: ref(false),
  error: ref(undefined),
});

const createVehicleLoadout = vi.fn((..._args: unknown[]) =>
  Promise.resolve({ id: "new" }),
);
const updateVehicleLoadout = vi.fn((..._args: unknown[]) =>
  Promise.resolve({}),
);
const activateVehicleLoadout = vi.fn((..._args: unknown[]) =>
  Promise.resolve({}),
);

// Partial: the row and the contents summary reach for real enums from here.
vi.mock("@/services/fyApi", async (importOriginal) => ({
  ...(await importOriginal<Record<string, unknown>>()),
  useModelModules: () => ({ data: modules, ...resolved() }),
  useVehicleLoadouts: () => ({ data: loadouts, ...resolved() }),
  createVehicleLoadout: (...args: unknown[]) => createVehicleLoadout(...args),
  updateVehicleLoadout: (...args: unknown[]) => updateVehicleLoadout(...args),
  activateVehicleLoadout: (...args: unknown[]) =>
    activateVehicleLoadout(...args),
}));

vi.mock("@/frontend/composables/useVehicleMutations", () => ({
  useVehicleMutations: () => ({
    invalidateHangarQueries: () => Promise.resolve(),
  }),
}));

vi.mock("@/shared/composables/useComlink", () => ({
  useComlink: () => ({ emit: vi.fn(), on: vi.fn(), off: vi.fn() }),
}));

vi.mock("@/shared/composables/useI18n", () => ({
  useI18n: () => ({
    t: (key: string) => key,
    toNumber: (value: number) => String(value),
  }),
}));

const vehicle = (
  modelModuleIds: string[] = [],
  {
    fitted,
    productionStatus = "flight-ready",
    activeLoadout,
  }: {
    fitted?: Record<string, string>;
    productionStatus?: string;
    activeLoadout?: Record<string, unknown>;
  } = {},
): Vehicle =>
  ({
    id: "v1",
    modelModuleIds,
    modelUpgradeIds: [],
    activeLoadout: fitted
      ? {
          id: "l1",
          name: "Hauler",
          kind: "fleetyards",
          active: true,
          items: Object.entries(fitted).map(([slotPath, itemId]) => ({
            slotPath,
            itemType: "ModelModule",
            itemId,
          })),
        }
      : activeLoadout,
    model: {
      name: "Retaliator",
      slug: "retaliator",
      hasModules: true,
      productionStatus,
      media: {},
      metrics: { cargo: 100 },
    },
  }) as unknown as Vehicle;

const mountModal = (v: Vehicle, props: Record<string, unknown> = {}) =>
  mountWithDefaults(Component, {
    props: { vehicle: v, editable: true, ...props },
  });

type Wrapper = Awaited<ReturnType<typeof mountModal>>;

const slotPick = (wrapper: Wrapper, i: number) =>
  wrapper.findAll("[data-test='vehicle-loadout-slot-module-toggle']")[i];

const save = async (wrapper: Wrapper) => {
  await wrapper.find("form").trigger("submit");
  await flushPromises();
};

const cargo = (wrapper: Wrapper) =>
  wrapper
    .findAll("[data-test='vehicle-specs'] div")
    .find((spec) => spec.find("dt").text() === "labels.model.cargo")
    ?.find("dd")
    .text();

beforeEach(() => {
  loadouts.value = [];
  createVehicleLoadout.mockClear();
  updateVehicleLoadout.mockClear();
  activateVehicleLoadout.mockClear();
});

describe("VehicleLoadoutModal", () => {
  it("counts only the fitted module's cargo in the ship's stats", async () => {
    const wrapper = await mountModal(vehicle(["m1", "m2"]));

    expect(cargo(wrapper)).toBe("100");

    await slotPick(wrapper, 0).trigger("click");

    expect(cargo(wrapper)).toBe("132");
  });

  it("shows what each option and the whole fitting change", async () => {
    const wrapper = await mountModal(
      vehicle(["m1", "m2"], { fitted: { hardpoint_module: "m2" } }),
    );

    const cargoOption = wrapper.findAll(
      "[data-test='vehicle-loadout-slot-module']",
    )[0];
    expect(cargoOption.text()).toContain("+32");

    await slotPick(wrapper, 0).trigger("click");

    expect(
      wrapper.get("[data-test='vehicle-loadout-changes']").text(),
    ).toContain("+32");
  });

  it("fits one module per slot, swapping rather than adding", async () => {
    const wrapper = await mountModal(vehicle(["m1", "m2"]));

    await slotPick(wrapper, 0).trigger("click");
    await slotPick(wrapper, 1).trigger("click");

    expect(
      wrapper.findAll(
        "[data-test='vehicle-loadout-slot-module'].addon-option--selected",
      ),
    ).toHaveLength(1);
  });

  it("saves a new loadout and switches it on when nothing else is", async () => {
    const wrapper = await mountModal(vehicle(["m1"]));

    await slotPick(wrapper, 0).trigger("click");
    await save(wrapper);

    expect(createVehicleLoadout).toHaveBeenCalledWith("v1", {
      kind: "fleetyards",
      name: "",
      items: [
        { slotPath: "hardpoint_module", itemType: "ModelModule", itemId: "m1" },
      ],
    });
    expect(activateVehicleLoadout).toHaveBeenCalledWith("v1", "new");
  });

  it("leaves an active linked build switched on when saving a new loadout", async () => {
    const wrapper = await mountModal(
      vehicle(["m1"], { activeLoadout: { id: "link", kind: "link" } }),
    );

    await slotPick(wrapper, 0).trigger("click");
    await save(wrapper);

    expect(createVehicleLoadout).toHaveBeenCalled();
    expect(activateVehicleLoadout).not.toHaveBeenCalled();
  });

  it("edits the ship's own loadout while a linked build is active", async () => {
    loadouts.value = [
      {
        id: "l3",
        name: "Hauler",
        kind: "fleetyards",
        active: false,
        updatedAt: "2026-10-01T00:00:00Z",
        items: [],
      },
    ];
    const wrapper = await mountModal(
      vehicle(["m1"], { activeLoadout: { id: "link", kind: "link" } }),
    );
    await flushPromises();

    await slotPick(wrapper, 0).trigger("click");
    await save(wrapper);

    expect(createVehicleLoadout).not.toHaveBeenCalled();
    expect(updateVehicleLoadout).toHaveBeenCalledWith(
      "v1",
      "l3",
      expect.objectContaining({ name: "Hauler" }),
    );
  });

  it("keeps what it does not show yet, inside a slot that stays fitted", async () => {
    loadouts.value = [
      {
        id: "l2",
        name: "Gunship",
        kind: "fleetyards",
        active: false,
        updatedAt: "2026-10-01T00:00:00Z",
        items: [
          {
            slotPath: "hardpoint_module",
            itemType: "ModelModule",
            itemId: "m1",
          },
          {
            slotPath: "hardpoint_module/hardpoint_turret",
            itemType: "Component",
            itemId: "c1",
          },
        ],
      },
    ];
    const wrapper = await mountModal(vehicle(["m1"]), { loadoutId: "l2" });
    await flushPromises();

    await save(wrapper);

    expect(updateVehicleLoadout).toHaveBeenCalledWith("v1", "l2", {
      name: "Gunship",
      items: [
        { slotPath: "hardpoint_module", itemType: "ModelModule", itemId: "m1" },
        {
          slotPath: "hardpoint_module/hardpoint_turret",
          itemType: "Component",
          itemId: "c1",
        },
      ],
    });
  });

  it("edits the active fleetyards loadout in place", async () => {
    const wrapper = await mountModal(
      vehicle(["m1", "m2"], { fitted: { hardpoint_module: "m1" } }),
    );

    await slotPick(wrapper, 1).trigger("click");
    await save(wrapper);

    expect(createVehicleLoadout).not.toHaveBeenCalled();
    expect(updateVehicleLoadout).toHaveBeenCalledWith("v1", "l1", {
      name: "Hauler",
      items: [
        { slotPath: "hardpoint_module", itemType: "ModelModule", itemId: "m2" },
      ],
    });
  });

  it("edits the saved loadout it was opened for, without activating it", async () => {
    loadouts.value = [
      {
        id: "l2",
        name: "Medical run",
        kind: "fleetyards",
        active: false,
        updatedAt: "2026-10-01T00:00:00Z",
        items: [
          {
            slotPath: "hardpoint_module",
            itemType: "ModelModule",
            itemId: "m1",
          },
        ],
      },
    ];
    const wrapper = await mountModal(vehicle(["m1", "m2"]), {
      loadoutId: "l2",
    });
    await flushPromises();

    await slotPick(wrapper, 1).trigger("click");
    await save(wrapper);

    expect(updateVehicleLoadout).toHaveBeenCalledWith("v1", "l2", {
      name: "Medical run",
      items: [
        { slotPath: "hardpoint_module", itemType: "ModelModule", itemId: "m2" },
      ],
    });
    expect(activateVehicleLoadout).not.toHaveBeenCalled();
  });

  it("starts a new loadout beside the active one when asked to", async () => {
    const wrapper = await mountModal(
      vehicle(["m1"], { fitted: { hardpoint_module: "m1" } }),
      { newLoadout: true },
    );

    expect(
      wrapper.findAll(
        "[data-test='vehicle-loadout-slot-module'].addon-option--selected",
      ),
    ).toHaveLength(0);

    await save(wrapper);

    expect(createVehicleLoadout).toHaveBeenCalled();
    expect(updateVehicleLoadout).not.toHaveBeenCalled();
  });

  it("does not let a visitor save", async () => {
    const wrapper = await mountModal(vehicle(["m1"]), { editable: false });

    expect(wrapper.find('[data-test="vehicle-loadout-save"]').exists()).toBe(
      false,
    );
    await save(wrapper);

    expect(createVehicleLoadout).not.toHaveBeenCalled();
  });

  it("offers no fitting on a ship that is not flight-ready", async () => {
    const wrapper = await mountModal(
      vehicle(["m1"], { productionStatus: "in-concept" }),
    );

    expect(
      wrapper.find("[data-test='vehicle-loadout-not-flight-ready']").exists(),
    ).toBe(true);
    expect(wrapper.find("[data-test='vehicle-loadout-fitting']").exists()).toBe(
      false,
    );
    expect(
      wrapper.get('[data-test="vehicle-loadout-save"]').attributes("disabled"),
    ).toBeDefined();
  });

  it("re-seeds the fitting when the ship it was opened for changes", async () => {
    const wrapper = await mountModal(
      vehicle(["m1", "m2"], { fitted: { hardpoint_module: "m1" } }),
    );

    await wrapper.setProps({
      vehicle: vehicle(["m1", "m2"], { fitted: { hardpoint_module: "m2" } }),
    });
    await flushPromises();

    const selected = wrapper.findAll(
      "[data-test='vehicle-loadout-slot-module'].addon-option--selected",
    );
    expect(selected).toHaveLength(1);
    expect(selected[0].text()).toContain("Combat Module");
  });
});

it("keeps owned modules, upgrades and paint out of the loadout", async () => {
  const wrapper = await mountModal(vehicle());
  const ids = wrapper
    .findAllComponents({ name: "FormTab" })
    .map((tab) => tab.props("id"));

  expect(ids).not.toContain("upgrades");
  expect(ids).not.toContain("paints");
  expect(wrapper.find("[data-test='vehicle-addon']").exists()).toBe(false);
});

it("orders systems before propulsion and weapons", async () => {
  const wrapper = await mountModal(vehicle());
  const tabs = wrapper.findAllComponents({ name: "FormTab" });
  expect(tabs.map((tab) => tab.props("id"))).toEqual([
    "radar",
    "coolers",
    "lifeSupport",
    "powerPlants",
    "shields",
    "modules",
    "quantumDrives",
    "flightBlades",
    "missiles",
    "weapons",
  ]);
  for (const [id, category] of [
    ["radar", "radar"],
    ["coolers", "cooler"],
    ["lifeSupport", "lifesupport"],
    ["powerPlants", "powerplant"],
    ["shields", "shieldgenerator"],
    ["modules", "module"],
    ["quantumDrives", "quantumdrive"],
    ["flightBlades", "controller"],
    ["missiles", "missiles"],
    ["weapons", "weapons"],
  ]) {
    const tab = tabs.find((tab) => tab.props("id") === id)!;
    const icon = categoryIcon(category)!;
    expect(tab.props(icon.kind === "svg" ? "iconSrc" : "icon")).toBe(
      icon.kind === "svg" ? icon.src : icon.className,
    );
  }
});

it("disables the modules category on a ship without modules", async () => {
  const v = vehicle();
  v.model.hasModules = false;
  const wrapper = await mountModal(v);

  expect(
    wrapper
      .findAllComponents({ name: "FormTab" })
      .find((tab) => tab.props("id") === "modules")
      ?.props("disabled"),
  ).toBe(true);
});
