import { flushPromises } from "@vue/test-utils";
import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { beforeEach, describe, expect, it, vi } from "vitest";
import { ref } from "vue";
import type { ModelModule, Vehicle } from "@/services/fyApi";
import Component from "./index.vue";
import { categoryIcon } from "@/frontend/components/Models/Hardpoints/categoryIcon";

const modules = ref<{ items: ModelModule[] }>({
  items: [
    { id: "m1", name: "Cargo Module", slug: "cargo" },
    { id: "m2", name: "Combat Module", slug: "combat" },
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
}));

const mutateAsync = vi.fn(() => Promise.resolve());

vi.mock("@/frontend/composables/useVehicleMutations", () => ({
  useVehicleMutations: () => ({
    useUpdateMutation: () => ({ mutateAsync, isPending: ref(false) }),
  }),
}));

vi.mock("@/shared/composables/useComlink", () => ({
  useComlink: () => ({ emit: vi.fn(), on: vi.fn(), off: vi.fn() }),
}));

vi.mock("@/shared/composables/useI18n", () => ({
  useI18n: () => ({ t: (key: string) => key }),
}));

const vehicle = (modelModuleIds: string[] = []): Vehicle =>
  ({
    id: "v1",
    modelModuleIds,
    modelUpgradeIds: [],
    model: {
      name: "Retaliator",
      slug: "retaliator",
      hasModules: true,
      media: {},
      metrics: {},
    },
  }) as unknown as Vehicle;

const mountModal = (v: Vehicle) =>
  mountWithDefaults(Component, { props: { vehicle: v, editable: true } });

const rowToggle = (
  wrapper: Awaited<ReturnType<typeof mountModal>>,
  i: number,
) => wrapper.findAll("[data-test='vehicle-addon-toggle']")[i];

beforeEach(() => mutateAsync.mockClear());

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

  // Reassigning the initial values never reached the form, so the modal kept
  // answering for whichever ship it was first opened for.
  it("re-seeds the fields when the ship it was opened for changes", async () => {
    const wrapper = await mountModal(vehicle(["m1"]));

    expect(wrapper.findAll(".addon-option--selected")).toHaveLength(1);

    await wrapper.setProps({ vehicle: vehicle(["m2"]) });
    await flushPromises();

    const selected = wrapper.findAll(".addon-option--selected");
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

    expect(wrapper.findAll(".addon-option--selected")).toHaveLength(2);
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
