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

const resolved = () => ({
  isPending: ref(false),
  isFetching: ref(false),
  isLoading: ref(false),
  isRefetching: ref(false),
  error: ref(undefined),
});

// Partial: the row and the contents summary reach for real enums from here.
vi.mock("@/services/fyApi", async (importOriginal) => ({
  ...(await importOriginal<Record<string, unknown>>()),
  useModelPaints: () => ({ data: ref([]), ...resolved() }),
  useModelModulePackages: () => ({ data: ref(undefined), ...resolved() }),
  useModelModules: () => ({ data: modules, ...resolved() }),
  useModelUpgrades: () => ({ data: ref([]), ...resolved() }),
  createVehicleLoadout: (...args: unknown[]) => createVehicleLoadout(...args),
  updateVehicleLoadout: (...args: unknown[]) => updateVehicleLoadout(...args),
  activateVehicleLoadout: (...args: unknown[]) =>
    activateVehicleLoadout(...args),
}));

const mutateAsync = vi.fn(() => Promise.resolve());
const createVehicleLoadout = vi.fn((..._args: unknown[]) =>
  Promise.resolve({ id: "new" }),
);
const updateVehicleLoadout = vi.fn((..._args: unknown[]) =>
  Promise.resolve({}),
);
const activateVehicleLoadout = vi.fn((..._args: unknown[]) =>
  Promise.resolve({}),
);

vi.mock("@/frontend/composables/useVehicleMutations", () => ({
  useVehicleMutations: () => ({
    useUpdateMutation: () => ({ mutateAsync, isPending: ref(false) }),
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
  }: { fitted?: Record<string, string>; productionStatus?: string } = {},
): Vehicle =>
  ({
    id: "v1",
    modelModuleIds,
    modelUpgradeIds: [],
    activeLoadout: fitted
      ? {
          id: "l1",
          kind: "fleetyards",
          items: Object.entries(fitted).map(([slot, modelModuleId]) => ({
            slot,
            modelModuleId,
          })),
        }
      : undefined,
    model: {
      name: "Retaliator",
      slug: "retaliator",
      hasModules: true,
      productionStatus,
      media: {},
      metrics: { cargo: 100 },
    },
  }) as unknown as Vehicle;

const mountModal = (v: Vehicle) =>
  mountWithDefaults(Component, { props: { vehicle: v, editable: true } });

const rowToggle = (
  wrapper: Awaited<ReturnType<typeof mountModal>>,
  i: number,
) => wrapper.findAll("[data-test='vehicle-addon-toggle']")[i];

const slotPick = (wrapper: Awaited<ReturnType<typeof mountModal>>, i: number) =>
  wrapper.findAll("[data-test='vehicle-loadout-slot-module-toggle']")[i];

beforeEach(() => {
  mutateAsync.mockClear();
  createVehicleLoadout.mockClear();
  updateVehicleLoadout.mockClear();
  activateVehicleLoadout.mockClear();
});

describe("VehicleLoadoutModal", () => {
  it("does not save an unchanged loadout", async () => {
    const wrapper = await mountModal(vehicle(["m1"]));
    await wrapper.find("form").trigger("submit");
    await flushPromises();

    expect(mutateAsync).not.toHaveBeenCalled();
  });

  it("does not allow a visitor to save", async () => {
    const wrapper = await mountWithDefaults(Component, {
      props: { vehicle: vehicle(["m1"]), editable: false },
    });

    expect(wrapper.find('[data-test="vehicle-loadout-save"]').exists()).toBe(
      false,
    );
    await wrapper.find("form").trigger("submit");
    await flushPromises();
    expect(mutateAsync).not.toHaveBeenCalled();
  });

  /**
   * The whole broken chain in one assertion: a row click has to reach the form
   * field and land in the payload. It used to stop at the row.
   */
  it("saves the selection a row click made", async () => {
    const wrapper = await mountModal(vehicle());

    await rowToggle(wrapper, 0).trigger("click");
    await wrapper.find("form").trigger("submit");
    await flushPromises();

    expect(mutateAsync).toHaveBeenCalledWith({
      id: "v1",
      data: { modelModuleIds: ["m1"] },
    });
  });

  it("counts only the fitted module's cargo in the ship's stats", async () => {
    const wrapper = await mountModal(vehicle(["m1", "m2"]));
    const cargo = () =>
      wrapper
        .findAll("[data-test='vehicle-specs'] div")
        .find((spec) => spec.find("dt").text() === "labels.model.cargo")
        ?.find("dd")
        .text();

    expect(cargo()).toBe("100");

    await slotPick(wrapper, 0).trigger("click");

    expect(cargo()).toBe("132");
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

  it("creates and activates a fleetyards loadout on the first fitting", async () => {
    const wrapper = await mountModal(vehicle(["m1"]));

    await slotPick(wrapper, 0).trigger("click");
    await wrapper.find("form").trigger("submit");
    await flushPromises();

    expect(mutateAsync).not.toHaveBeenCalled();
    expect(createVehicleLoadout).toHaveBeenCalledWith("v1", {
      kind: "fleetyards",
      items: [{ slot: "hardpoint_module", modelModuleId: "m1" }],
    });
    expect(activateVehicleLoadout).toHaveBeenCalledWith("v1", "new");
  });

  it("refits the active fleetyards loadout in place", async () => {
    const wrapper = await mountModal(
      vehicle(["m1", "m2"], { fitted: { hardpoint_module: "m1" } }),
    );

    await slotPick(wrapper, 1).trigger("click");
    await wrapper.find("form").trigger("submit");
    await flushPromises();

    expect(createVehicleLoadout).not.toHaveBeenCalled();
    expect(updateVehicleLoadout).toHaveBeenCalledWith("v1", "l1", {
      items: [{ slot: "hardpoint_module", modelModuleId: "m2" }],
    });
  });

  it("unfits a module that is given up", async () => {
    const wrapper = await mountModal(
      vehicle(["m1"], { fitted: { hardpoint_module: "m1" } }),
    );

    await rowToggle(wrapper, 0).trigger("click");
    await wrapper.find("form").trigger("submit");
    await flushPromises();

    expect(mutateAsync).toHaveBeenCalledWith({
      id: "v1",
      data: { modelModuleIds: [] },
    });
    expect(updateVehicleLoadout).toHaveBeenCalledWith("v1", "l1", {
      items: [],
    });
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
  });

  // Reassigning the initial values never reached the form, so the modal kept
  // answering for whichever ship it was first opened for.
  it("re-seeds the fields when the ship it was opened for changes", async () => {
    const wrapper = await mountModal(vehicle(["m1"]));

    expect(
      wrapper.findAll("[data-test='vehicle-addon'].addon-option--selected"),
    ).toHaveLength(1);

    await wrapper.setProps({ vehicle: vehicle(["m2"]) });
    await flushPromises();

    const selected = wrapper.findAll(
      "[data-test='vehicle-addon'].addon-option--selected",
    );
    expect(selected).toHaveLength(1);
    expect(selected[0].text()).toContain("Combat Module");
  });

  it("saves a preselected paint, even after the ship refreshes", async () => {
    const wrapper = await mountWithDefaults(Component, {
      props: { vehicle: vehicle(), editable: true, paintId: "p2" },
    });

    await wrapper.setProps({ vehicle: vehicle() });
    await flushPromises();
    await wrapper.find("form").trigger("submit");
    await flushPromises();

    expect(mutateAsync).toHaveBeenCalledWith({
      id: "v1",
      data: { modelPaintId: "p2" },
    });
  });

  // A background refetch of the hangar must not discard an unsaved choice.
  it("keeps a pending choice when the ship refreshes underneath it", async () => {
    const wrapper = await mountModal(vehicle(["m1"]));

    await rowToggle(wrapper, 1).trigger("click");
    await wrapper.setProps({ vehicle: vehicle(["m1"]) });
    await flushPromises();

    expect(
      wrapper.findAll("[data-test='vehicle-addon'].addon-option--selected"),
    ).toHaveLength(2);
  });
});

it("shows the additional component sections and unsupported add-on sections", async () => {
  const v = vehicle();
  v.model.hasModules = false;
  const wrapper = await mountModal(v);
  const tabs = wrapper.findAllComponents({ name: "FormTab" });
  const ids = tabs.map((tab) => tab.props("id"));
  expect(
    tabs.find((tab) => tab.props("id") === "modules")?.props("disabled"),
  ).toBe(true);
  expect(ids).toEqual(
    expect.arrayContaining([
      "radar",
      "lifeSupport",
      "flightBlades",
      "modules",
      "upgrades",
    ]),
  );
});

it("orders systems before propulsion and weapons, with paints last", async () => {
  const wrapper = await mountModal(vehicle());
  const tabs = wrapper.findAllComponents({ name: "FormTab" });
  expect(tabs.map((tab) => tab.props("id"))).toEqual([
    "radar",
    "coolers",
    "lifeSupport",
    "powerPlants",
    "shields",
    "modules",
    "upgrades",
    "quantumDrives",
    "flightBlades",
    "missiles",
    "weapons",
    "paints",
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
    ["paints", "paints"],
  ]) {
    const tab = tabs.find((tab) => tab.props("id") === id)!;
    const icon = categoryIcon(category)!;
    expect(tab.props(icon.kind === "svg" ? "iconSrc" : "icon")).toBe(
      icon.kind === "svg" ? icon.src : icon.className,
    );
  }
});

it("reserves saving a loadout while keeping current changes saveable", async () => {
  const wrapper = await mountModal(vehicle());
  expect(
    wrapper
      .get('[data-test="vehicle-loadout-save-preset"]')
      .attributes("disabled"),
  ).toBeDefined();
  expect(
    wrapper.get('[data-test="vehicle-loadout-save"]').attributes("disabled"),
  ).toBeUndefined();
});
