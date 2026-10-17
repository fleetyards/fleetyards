import { flushPromises } from "@vue/test-utils";
import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
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

// The tab strip scrolls its active tab into view after a render, which jsdom
// cannot; on Element, so a spec that stubs and restores HTMLElement's own does
// not take it away from a scroll still pending.
Element.prototype.scrollTo = vi.fn();

const hullSlots = ref<unknown[]>([]);
const savedSlots = ref<unknown[]>([]);
const componentOptions = ref<unknown[]>([]);
const optionsStale = ref(false);
const modelHardpoints = ref<unknown[]>([]);

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
  useModelLoadoutSlots: () => ({ data: hullSlots, ...resolved() }),
  useVehicleLoadoutSlots: () => ({ data: savedSlots, ...resolved() }),
  useModelHardpoints: () => ({ data: modelHardpoints, ...resolved() }),
  useHardpointLoadoutOptions: () => ({
    data: componentOptions,
    ...resolved(),
    isPlaceholderData: optionsStale,
  }),
  createVehicleLoadout: (...args: unknown[]) => createVehicleLoadout(...args),
  updateVehicleLoadout: (...args: unknown[]) => updateVehicleLoadout(...args),
  activateVehicleLoadout: (...args: unknown[]) =>
    activateVehicleLoadout(...args),
}));

vi.mock("@/frontend/composables/useVehicleMutations", () => ({
  useVehicleMutations: () => ({
    invalidateHangarQueries: () => Promise.resolve(),
    invalidateVehiclePage: () => Promise.resolve(),
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
    modelPaintIds: [],
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

const mountClosed = (v: Vehicle, props: Record<string, unknown> = {}) =>
  mountWithDefaults(Component, {
    props: { vehicle: v, editable: true, ...props },
  });

type Wrapper = Awaited<ReturnType<typeof mountClosed>>;

// Opens the picker on the first socket, as a click on it does.
const openPicker = async (wrapper: Wrapper) => {
  if (wrapper.find("[data-test='loadout-picker']").exists()) return;

  const socketButton = wrapper.find("[data-loadout-socket][role='button']");
  if (socketButton.exists()) await socketButton.trigger("click");
};

// Open, for the specs about what happens inside the picker.
const mountModal = async (v: Vehicle, props: Record<string, unknown> = {}) => {
  const wrapper = await mountClosed(v, props);
  await openPicker(wrapper);

  return wrapper;
};

// A pick closes the picker, so each one opens it again first.
const pick = async (wrapper: Wrapper, i: number) => {
  await openPicker(wrapper);
  await wrapper
    .findAll("[data-test='loadout-picker-option']")
    [i].trigger("click");
};

const save = async (wrapper: Wrapper) => {
  await wrapper.find("form").trigger("submit");
  await flushPromises();
};

const cargo = (wrapper: Wrapper) => {
  const tile = "[data-test='vehicle-loadout-metric-cargo']";
  const delta = wrapper.find(
    `${tile} [data-test='vehicle-loadout-metric-delta']`,
  );

  return [
    wrapper.get(`${tile} .metrics-card__tile__value`).text(),
    delta.exists() ? delta.text() : undefined,
  ]
    .filter(Boolean)
    .join(" ");
};

beforeEach(() => {
  loadouts.value = [];
  hullSlots.value = [];
  savedSlots.value = [];
  componentOptions.value = [];
  optionsStale.value = false;
  modelHardpoints.value = [];
  createVehicleLoadout.mockClear();
  updateVehicleLoadout.mockClear();
  activateVehicleLoadout.mockClear();
});

describe("VehicleLoadoutModal", () => {
  it("shows the ship's cargo with its change against the saved loadout", async () => {
    const wrapper = await mountModal(vehicle(["m1", "m2"]));

    expect(cargo(wrapper)).toBe("100");

    await pick(wrapper, 0);

    expect(cargo(wrapper)).toContain("132");
    expect(cargo(wrapper)).toContain("+32");
  });

  it("previews the option under the pointer, then returns to what is picked", async () => {
    const wrapper = await mountModal(
      vehicle(["m1", "m2"], { fitted: { hardpoint_module: "m2" } }),
    );
    const cargoRow = () =>
      wrapper.find("[data-test='vehicle-loadout-comparison-cargo']");

    // The slot's own fitting, before anything is pointed at: no swap to show.
    expect(
      wrapper.get("[data-test='vehicle-loadout-comparison-swap']").text(),
    ).toBe("Combat Module");
    expect(cargoRow().exists()).toBe(false);

    await wrapper
      .findAll("[data-test='loadout-picker-option']")[0]
      .trigger("mouseenter");

    expect(cargoRow().text()).toContain("+32");

    await wrapper
      .get("[data-test='loadout-picker-options']")
      .trigger("mouseleave");

    expect(cargoRow().exists()).toBe(false);
  });

  it("compares against what is picked, not what was last saved", async () => {
    const wrapper = await mountModal(
      vehicle(["m1", "m2"], { fitted: { hardpoint_module: "m2" } }),
    );

    // Picked, not saved: the combat module gives way to the cargo module.
    await pick(wrapper, 0);
    await openPicker(wrapper);
    await wrapper
      .findAll("[data-test='loadout-picker-option']")[0]
      .trigger("mouseenter");

    expect(
      wrapper.get("[data-test='vehicle-loadout-comparison-swap']").text(),
    ).toBe("Cargo Module");
    expect(
      wrapper.find("[data-test='vehicle-loadout-comparison-cargo']").exists(),
    ).toBe(false);
  });

  it("shows only what a swap changes, and says when it changes nothing", async () => {
    const wrapper = await mountModal(vehicle(["m1", "m2"]));

    // The combat module carries no cargo: the hull's own stays as it is.
    await wrapper
      .findAll("[data-test='loadout-picker-option']")[1]
      .trigger("mouseenter");

    expect(
      wrapper.find("[data-test='vehicle-loadout-comparison-cargo']").exists(),
    ).toBe(false);
    expect(
      wrapper.find("[data-test='vehicle-loadout-comparison-none']").exists(),
    ).toBe(true);
  });

  it("says so when the hull has no slot to fit", async () => {
    const empty = modules.value;
    modules.value = { items: [] };
    const wrapper = await mountModal(vehicle());

    expect(
      wrapper.find("[data-test='vehicle-loadout-no-slots']").exists(),
    ).toBe(true);
    modules.value = empty;
  });

  it("fits one module per slot, swapping rather than adding", async () => {
    const wrapper = await mountModal(vehicle(["m1", "m2"]));

    await pick(wrapper, 0);
    await pick(wrapper, 1);
    await openPicker(wrapper);

    expect(
      wrapper.findAll(
        "[data-test='loadout-picker-option'].loadout-picker__option--selected",
      ),
    ).toHaveLength(1);
  });

  it("saves a new loadout and switches it on when nothing else is", async () => {
    const wrapper = await mountModal(vehicle(["m1"]));

    await pick(wrapper, 0);
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

  it("finishes the loadout it created when switching it on failed, rather than creating another", async () => {
    activateVehicleLoadout.mockImplementationOnce(() =>
      Promise.reject(new Error("timeout")),
    );
    const wrapper = await mountModal(vehicle(["m1"]));

    await pick(wrapper, 0);
    await save(wrapper);
    await save(wrapper);

    expect(createVehicleLoadout).toHaveBeenCalledTimes(1);
    expect(updateVehicleLoadout).toHaveBeenCalledWith(
      "v1",
      "new",
      expect.objectContaining({ items: [expect.anything()] }),
    );
    expect(activateVehicleLoadout).toHaveBeenCalledTimes(2);
  });

  it("leaves an active linked build switched on when saving a new loadout", async () => {
    const wrapper = await mountModal(
      vehicle(["m1"], { activeLoadout: { id: "link", kind: "link" } }),
    );

    await pick(wrapper, 0);
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

    await pick(wrapper, 0);
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

    await pick(wrapper, 1);
    await save(wrapper);

    expect(createVehicleLoadout).not.toHaveBeenCalled();
    expect(updateVehicleLoadout).toHaveBeenCalledWith("v1", "l1", {
      name: "Hauler",
      items: [
        { slotPath: "hardpoint_module", itemType: "ModelModule", itemId: "m2" },
      ],
    });
  });

  it("saves the fitting as a new loadout beside the one opened", async () => {
    loadouts.value = [
      {
        id: "l2",
        name: "Gunship",
        kind: "fleetyards",
        active: false,
        updatedAt: "2026-10-01T00:00:00Z",
        items: [],
      },
    ];
    const wrapper = await mountModal(vehicle(["m1", "m2"]), {
      loadoutId: "l2",
    });
    await flushPromises();

    await pick(wrapper, 1);
    await wrapper
      .get("[data-test='vehicle-loadout-save-as-new']")
      .trigger("click");
    await flushPromises();

    expect(updateVehicleLoadout).not.toHaveBeenCalled();
    expect(createVehicleLoadout).toHaveBeenCalledWith("v1", {
      kind: "fleetyards",
      name: "",
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

    await pick(wrapper, 1);
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
        "[data-test='loadout-picker-option'].loadout-picker__option--selected",
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
    expect(wrapper.find("[data-test='loadout-picker-options']").exists()).toBe(
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
      "[data-test='loadout-picker-option'].loadout-picker__option--selected",
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
    ["missiles", "missile_racks"],
    ["weapons", "weapons"],
  ]) {
    const tab = tabs.find((tab) => tab.props("id") === id)!;
    expect(tab.props("icon")).toBe(categoryIcon(category));
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

it("disables the modules category on a ship that is not flight-ready", async () => {
  const wrapper = await mountModal(
    vehicle(["m1"], { productionStatus: "in-concept" }),
  );

  expect(
    wrapper
      .findAllComponents({ name: "FormTab" })
      .find((tab) => tab.props("id") === "modules")
      ?.props("disabled"),
  ).toBe(true);
});

describe("VehicleLoadoutModal with several sockets", () => {
  const TWO_SLOTS = [
    {
      id: "f1",
      name: "Front Cargo Module",
      slug: "front-cargo",
      slot: "hardpoint_front_module",
      metrics: { cargo: 36 },
    },
    {
      id: "f2",
      name: "Front Torpedo Bay",
      slug: "front-torpedo",
      slot: "hardpoint_front_module",
    },
    {
      id: "r1",
      name: "Rear Cargo Module",
      slug: "rear-cargo",
      slot: "hardpoint_rear_module",
      metrics: { cargo: 38 },
    },
  ] as unknown as ModelModule[];

  let saved: { items: ModelModule[] };

  beforeEach(() => {
    saved = modules.value;
    modules.value = { items: TWO_SLOTS };
  });

  afterEach(() => {
    modules.value = saved;
    vi.unstubAllGlobals();
    delete (HTMLElement.prototype as Partial<HTMLElement>).scrollTo;
  });

  const socket = (wrapper: Wrapper, slot: string) =>
    wrapper.get(`[data-test='loadout-socket-${slot}']`);

  const pickerNames = (wrapper: Wrapper) =>
    wrapper
      .findAll("[data-test='loadout-picker-option'] .loadout-picker__name")
      .map((name) => name.text());

  it("opens with no socket picked and no picker", async () => {
    const wrapper = await mountClosed(vehicle());

    expect(wrapper.find(".loadout-socket--active").exists()).toBe(false);
    expect(wrapper.find("[data-test='loadout-picker']").exists()).toBe(false);
  });

  it("fills the socket it was picked for and closes", async () => {
    const wrapper = await mountClosed(vehicle());

    await socket(wrapper, "hardpoint_front_module").trigger("click");
    expect(pickerNames(wrapper)).toEqual([
      "Front Cargo Module",
      "Front Torpedo Bay",
    ]);

    await wrapper
      .findAll("[data-test='loadout-picker-option']")[1]
      .trigger("click");

    expect(wrapper.find("[data-test='loadout-picker']").exists()).toBe(false);
    expect(wrapper.find(".loadout-socket--active").exists()).toBe(false);
    expect(
      socket(wrapper, "hardpoint_front_module")
        .get("[data-test='loadout-socket-name']")
        .text(),
    ).toBe("Front Torpedo Bay");
  });

  it("empties a socket from the picker", async () => {
    const wrapper = await mountClosed(
      vehicle([], {
        fitted: {
          hardpoint_front_module: "f1",
          hardpoint_rear_module: "r1",
        },
      }),
    );

    await socket(wrapper, "hardpoint_rear_module").trigger("click");
    await wrapper.get("[data-test='loadout-picker-empty']").trigger("click");

    expect(socket(wrapper, "hardpoint_rear_module").classes()).toContain(
      "loadout-socket--empty",
    );
    expect(wrapper.find("[data-test='loadout-picker']").exists()).toBe(false);
  });

  it("closes from the active socket, its close button and a press outside", async () => {
    const host = document.createElement("div");
    document.body.appendChild(host);
    const wrapper = await mountWithDefaults(Component, {
      props: { vehicle: vehicle(), editable: true },
      attachTo: host,
    });
    const picker = () => wrapper.find("[data-test='loadout-picker']");

    await socket(wrapper, "hardpoint_front_module").trigger("click");
    expect(picker().exists()).toBe(true);
    await socket(wrapper, "hardpoint_front_module").trigger("click");
    expect(picker().exists()).toBe(false);

    await socket(wrapper, "hardpoint_rear_module").trigger("click");
    await wrapper.get("[data-test='loadout-picker-close']").trigger("click");
    expect(picker().exists()).toBe(false);

    await socket(wrapper, "hardpoint_rear_module").trigger("click");
    document.body.dispatchEvent(new Event("pointerdown", { bubbles: true }));
    await nextTick();
    expect(picker().exists()).toBe(false);

    wrapper.unmount();
    host.remove();
  });

  it("switches sockets without closing on the way", async () => {
    const wrapper = await mountClosed(vehicle());

    await socket(wrapper, "hardpoint_front_module").trigger("click");
    socket(wrapper, "hardpoint_rear_module").element.dispatchEvent(
      new Event("pointerdown", { bubbles: true }),
    );
    await socket(wrapper, "hardpoint_rear_module").trigger("click");

    expect(
      socket(wrapper, "hardpoint_rear_module").attributes("aria-pressed"),
    ).toBe("true");
    expect(pickerNames(wrapper)).toEqual(["Rear Cargo Module"]);
  });

  it("opens the picker under the active socket on a phone", async () => {
    const wrapper = await mountModal(vehicle());

    expect(
      wrapper
        .get("[data-test='loadout-socket-board-active']")
        .find("[data-test='loadout-picker']")
        .exists(),
    ).toBe(true);
  });

  it("puts the picker beside the sockets where there is room", async () => {
    vi.stubGlobal(
      "matchMedia",
      vi.fn(() => ({ matches: false })),
    );
    // At desktop width the tab strip scrolls its active tab into view, which
    // jsdom has no implementation of.
    HTMLElement.prototype.scrollTo = vi.fn();
    const wrapper = await mountModal(vehicle());

    expect(
      wrapper.find("[data-test='loadout-socket-board-active']").exists(),
    ).toBe(false);
    expect(
      wrapper
        .find(".vehicle-loadout__picker[data-test='loadout-picker']")
        .exists(),
    ).toBe(true);
  });

  it("says nothing is fitted to a visitor rather than showing a blank tab", async () => {
    const wrapper = await mountClosed(vehicle(), { editable: false });

    expect(
      wrapper.find("[data-test='vehicle-loadout-nothing-fitted']").exists(),
    ).toBe(true);
  });

  it("hands focus into the picker and back to its socket", async () => {
    const host = document.createElement("div");
    document.body.appendChild(host);
    const wrapper = await mountWithDefaults(Component, {
      props: { vehicle: vehicle(), editable: true },
      attachTo: host,
    });

    await socket(wrapper, "hardpoint_front_module").trigger("click");
    await flushPromises();
    expect(
      wrapper
        .get("[data-test='loadout-picker']")
        .element.contains(document.activeElement),
    ).toBe(true);

    await wrapper.get("[data-test='loadout-picker-close']").trigger("click");
    await flushPromises();
    expect(document.activeElement?.getAttribute("data-test")).toBe(
      "loadout-socket-hardpoint_front_module",
    );

    wrapper.unmount();
    host.remove();
  });

  it("shows a visitor only the filled sockets, and no picker", async () => {
    const wrapper = await mountModal(
      vehicle([], { fitted: { hardpoint_rear_module: "r1" } }),
      { editable: false },
    );

    expect(wrapper.findAll(".loadout-socket")).toHaveLength(1);
    expect(socket(wrapper, "hardpoint_rear_module").element.tagName).toBe(
      "DIV",
    );
    expect(wrapper.find("[data-test='loadout-picker']").exists()).toBe(false);
  });
});

describe("VehicleLoadoutModal component tabs", () => {
  const STOCK_GIMBAL = { id: "g1", name: "Stock Gimbal", size: "3" };
  const STOCK_GUN = { id: "gun1", name: "Stock Gun", size: "3" };
  const OTHER_GUN = { id: "gun2", name: "Other Gun", size: "2" };
  const OTHER_GIMBAL = { id: "g2", name: "Other Gimbal", size: "3" };

  const gunPort = (name: string, stock?: unknown) => ({
    name,
    hardpointId: `port-${name}`,
    category: "weapons",
    minSize: 2,
    maxSize: 3,
    types: ["WeaponGun"],
    editable: true,
    stock,
    slots: [],
  });

  beforeEach(() => {
    hullSlots.value = [
      {
        name: "hardpoint_gun_nose",
        hardpointId: "hull-nose",
        category: "weapon_mounts",
        minSize: 3,
        maxSize: 3,
        types: ["Turret"],
        editable: true,
        stock: STOCK_GIMBAL,
        slots: [gunPort("hardpoint_class_2", STOCK_GUN)],
      },
    ];
  });

  const socket = (wrapper: Wrapper, path: string) =>
    wrapper.get(`[data-test='loadout-socket-${path}']`);

  const choose = async (wrapper: Wrapper, path: string, name: string) => {
    await socket(wrapper, path).trigger("click");
    await flushPromises();

    const option = wrapper
      .findAll("[data-test='loadout-picker-option']")
      .find((entry) => entry.text().includes(name));
    await option!.trigger("click");
    await flushPromises();
  };

  const savedItems = () =>
    (updateVehicleLoadout.mock.calls.at(-1)?.[2] as { items: unknown[] })
      ?.items ??
    (createVehicleLoadout.mock.calls.at(-1)?.[1] as { items: unknown[] })
      ?.items;

  it("lists a mount and the gun inside it with their stock parts", async () => {
    const wrapper = await mountClosed(vehicle(), { tab: "weapons" });
    await flushPromises();

    expect(socket(wrapper, "hardpoint_gun_nose").text()).toContain(
      "Stock Gimbal",
    );
    expect(
      socket(wrapper, "hardpoint_gun_nose/hardpoint_class_2").text(),
    ).toContain("Stock Gun");
  });

  it("saves a gun fitted into the stock mount by its slot path", async () => {
    componentOptions.value = [
      { component: STOCK_GUN, slots: [] },
      { component: OTHER_GUN, slots: [] },
    ];
    const wrapper = await mountClosed(vehicle(), { tab: "weapons" });
    await flushPromises();

    await choose(wrapper, "hardpoint_gun_nose/hardpoint_class_2", "Other Gun");
    await save(wrapper);

    expect(savedItems()).toEqual([
      {
        slotPath: "hardpoint_gun_nose/hardpoint_class_2",
        itemType: "Component",
        itemId: "gun2",
      },
    ]);
  });

  it("a swapped mount brings its own empty ports and drops the old gun", async () => {
    componentOptions.value = [
      { component: OTHER_GUN, slots: [] },
      { component: OTHER_GIMBAL, slots: [gunPort("hardpoint_gun")] },
    ];
    const wrapper = await mountClosed(vehicle(), { tab: "weapons" });
    await flushPromises();

    await choose(wrapper, "hardpoint_gun_nose/hardpoint_class_2", "Other Gun");
    await choose(wrapper, "hardpoint_gun_nose", "Other Gimbal");

    expect(
      wrapper
        .find(
          "[data-test='loadout-socket-hardpoint_gun_nose/hardpoint_class_2']",
        )
        .exists(),
    ).toBe(false);
    expect(
      socket(wrapper, "hardpoint_gun_nose/hardpoint_gun").text(),
    ).toContain("labels.loadoutPicker.emptySocket");

    await save(wrapper);

    expect(savedItems()).toEqual([
      { slotPath: "hardpoint_gun_nose", itemType: "Component", itemId: "g2" },
    ]);
  });

  it("marks a slot that differs from the saved loadout as changed", async () => {
    componentOptions.value = [
      { component: STOCK_GUN, slots: [] },
      { component: OTHER_GUN, slots: [] },
    ];
    const wrapper = await mountClosed(vehicle(), { tab: "weapons" });
    await flushPromises();

    const gun = "hardpoint_gun_nose/hardpoint_class_2";
    expect(socket(wrapper, gun).classes()).toContain(
      "loadout-socket--occupied",
    );
    expect(socket(wrapper, gun).classes()).not.toContain(
      "loadout-socket--changed",
    );

    await choose(wrapper, gun, "Other Gun");

    expect(socket(wrapper, gun).classes()).toContain("loadout-socket--changed");
  });

  it("empties a slot that came with a part, and what sat inside it goes", async () => {
    componentOptions.value = [{ component: STOCK_GIMBAL, slots: [] }];
    const wrapper = await mountClosed(vehicle(), { tab: "weapons" });
    await flushPromises();

    await socket(wrapper, "hardpoint_gun_nose").trigger("click");
    await flushPromises();
    await wrapper.get("[data-test='loadout-picker-empty']").trigger("click");
    await flushPromises();

    expect(socket(wrapper, "hardpoint_gun_nose").text()).toContain(
      "labels.loadoutPicker.emptySocket",
    );
    expect(
      wrapper
        .find(
          "[data-test='loadout-socket-hardpoint_gun_nose/hardpoint_class_2']",
        )
        .exists(),
    ).toBe(false);

    await save(wrapper);

    expect(savedItems()).toEqual([
      { slotPath: "hardpoint_gun_nose", itemType: "Empty" },
    ]);
  });

  it("picking the stock part again clears the slot", async () => {
    componentOptions.value = [
      { component: STOCK_GUN, slots: [] },
      { component: OTHER_GUN, slots: [] },
    ];
    const wrapper = await mountClosed(vehicle(), { tab: "weapons" });
    await flushPromises();

    await choose(wrapper, "hardpoint_gun_nose/hardpoint_class_2", "Other Gun");
    await choose(wrapper, "hardpoint_gun_nose/hardpoint_class_2", "Stock Gun");
    await save(wrapper);

    expect(savedItems()).toEqual([]);
  });

  it("lists a slot's parts best first by the figure that ranks them", async () => {
    const shield = (id: string, name: string, maxHealth: number) => ({
      id,
      name,
      size: "1",
      category: "shieldgenerator",
      type: "Shield",
      typeData: { maxHealth, maxRegen: 100 },
    });
    hullSlots.value = [
      {
        name: "hardpoint_shield_generator",
        hardpointId: "hull-shield",
        category: "shieldgenerator",
        minSize: 1,
        maxSize: 1,
        types: ["Shield"],
        editable: true,
        swappable: true,
        stock: shield("s1", "Weak Shield", 1000),
        slots: [],
      },
    ];
    componentOptions.value = [
      { component: shield("s1", "Weak Shield", 1000), slots: [] },
      { component: shield("s2", "Strong Shield", 3000), slots: [] },
    ];
    const wrapper = await mountClosed(vehicle(), { tab: "shields" });
    await flushPromises();

    await socket(wrapper, "hardpoint_shield_generator").trigger("click");
    await flushPromises();

    const names = wrapper
      .findAll("[data-test='loadout-picker-option'] .loadout-picker__name")
      .map((name) => name.text());
    expect(names).toEqual(["Strong Shield", "Weak Shield"]);
    expect(wrapper.get("[data-test='loadout-picker-option']").text()).toContain(
      "+200%",
    );
  });

  it("leads the ship's figures with the open tab's card, cut down", async () => {
    modelHardpoints.value = [
      {
        id: "hp-power",
        name: "hardpoint_power_plant",
        category: "powerplant",
        component: {
          id: "pp",
          name: "Plant",
          size: "1",
          type: "PowerPlant",
          typeData: { powerBase: 12 },
        },
        hardpoints: [],
      },
    ];
    const weapons = await mountClosed(vehicle(), { tab: "weapons" });
    await flushPromises();

    expect(
      weapons.find("[data-test='vehicle-loadout-metric-dps']").exists(),
    ).toBe(true);

    const modules = await mountClosed(vehicle(["m1"]), { tab: "modules" });
    await flushPromises();

    expect(
      modules.find("[data-test='vehicle-loadout-metric-dps']").exists(),
    ).toBe(false);
    expect(
      modules.find("[data-test='vehicle-loadout-metric-cargo']").exists(),
    ).toBe(true);
  });

  it("lists the slots a fitted module brings in their category's tab", async () => {
    const saved = modules.value;
    modules.value = {
      items: [
        {
          id: "m1",
          name: "Combat Module",
          slug: "combat",
          slot: "hardpoint_module",
          hardpoints: [
            {
              id: "module-shield",
              name: "hardpoint_shield_generator_module",
              category: "shieldgenerator",
              minSize: 1,
              maxSize: 1,
              types: ["Shield"],
              component: { id: "ms", name: "Module Shield", size: "1" },
              hardpoints: [],
            },
          ],
        },
      ] as unknown as ModelModule[],
    };
    hullSlots.value = [
      {
        name: "hardpoint_module",
        hardpointId: "hull-module",
        category: "module",
        types: ["Module"],
        editable: true,
        slots: [],
      },
    ];
    const wrapper = await mountClosed(
      vehicle(["m1"], { fitted: { hardpoint_module: "m1" } }),
      { tab: "shields" },
    );
    await flushPromises();

    expect(
      socket(
        wrapper,
        "hardpoint_module/hardpoint_shield_generator_module",
      ).text(),
    ).toContain("Module Shield");

    modules.value = saved;
  });

  const shieldSlot = (name: string, stock: unknown) => ({
    name,
    hardpointId: `hull-${name}`,
    category: "shieldgenerator",
    minSize: 1,
    maxSize: 1,
    types: ["Shield"],
    editable: true,
    swappable: true,
    stock,
    slots: [],
  });

  it("stacks identical slots with a count, and a pick fills every one", async () => {
    const allStop = { id: "as", name: "AllStop", size: "1" };
    const better = { id: "fr", name: "FR-66", size: "1" };
    hullSlots.value = [
      "hardpoint_shield_generator_left",
      "hardpoint_shield_generator_right",
      "hardpoint_shield_generator_top",
      "hardpoint_shield_generator_bottom",
      "hardpoint_shield_generator_rear",
    ].map((name) => shieldSlot(name, allStop));
    componentOptions.value = [
      { component: allStop, slots: [] },
      { component: better, slots: [] },
    ];
    const wrapper = await mountClosed(vehicle(), { tab: "shields" });
    await flushPromises();

    const row = socket(wrapper, "hardpoint_shield_generator_left#stack");
    expect(row.text()).toContain("5");
    expect(
      wrapper
        .find("[data-test='loadout-socket-hardpoint_shield_generator_right']")
        .exists(),
    ).toBe(false);

    await row.trigger("click");
    await flushPromises();

    // Open, the stack stays one row rather than splitting around its first slot.
    expect(
      wrapper
        .find("[data-test='loadout-socket-hardpoint_shield_generator_left']")
        .exists(),
    ).toBe(false);

    await wrapper
      .findAll("[data-test='loadout-picker-option']")
      .find((option) => option.text().includes("FR-66"))!
      .trigger("click");
    await flushPromises();
    await save(wrapper);

    expect(savedItems()).toEqual(
      [
        "hardpoint_shield_generator_left",
        "hardpoint_shield_generator_right",
        "hardpoint_shield_generator_top",
        "hardpoint_shield_generator_bottom",
        "hardpoint_shield_generator_rear",
      ].map((slotPath) => ({ slotPath, itemType: "Component", itemId: "fr" })),
    );
  });

  it("keeps apart slots with the same parts under different names inside", async () => {
    const turret = (name: string, inner: string) => ({
      name,
      hardpointId: `hull-${name}`,
      category: "turret",
      minSize: 3,
      maxSize: 3,
      types: ["Turret"],
      editable: true,
      swappable: true,
      stock: STOCK_GIMBAL,
      slots: [gunPort(inner, STOCK_GUN)],
    });
    hullSlots.value = [
      turret("hardpoint_turret_left", "turret_left"),
      turret("hardpoint_turret_right", "duel_turret_left"),
    ];
    const wrapper = await mountClosed(vehicle(), { tab: "weapons" });
    await flushPromises();

    expect(socket(wrapper, "hardpoint_turret_left").text()).toContain(
      "Stock Gimbal",
    );
    expect(socket(wrapper, "hardpoint_turret_right").text()).toContain(
      "Stock Gimbal",
    );
  });

  it("stacks inside a stack, and a pick there fills it under every member", async () => {
    const gimbal = (name: string) => ({
      name,
      hardpointId: `port-${name}`,
      category: "weapon_mounts",
      minSize: 3,
      maxSize: 3,
      types: ["Turret"],
      editable: false,
      stock: STOCK_GIMBAL,
      slots: [gunPort("hardpoint_class_2", STOCK_GUN)],
    });
    const turret = (name: string) => ({
      name,
      hardpointId: `hull-${name}`,
      category: "turret",
      minSize: 3,
      maxSize: 3,
      types: ["Turret"],
      editable: false,
      stock: { id: "rt", name: "Remote Turret", size: "3" },
      slots: [gimbal("turret_left"), gimbal("turret_right")],
    });
    hullSlots.value = [
      turret("hardpoint_remote_turret_left"),
      turret("hardpoint_remote_turret_right"),
    ];
    componentOptions.value = [
      { component: STOCK_GUN, slots: [] },
      { component: OTHER_GUN, slots: [] },
    ];
    const wrapper = await mountClosed(vehicle(), { tab: "weapons" });
    await flushPromises();

    expect(
      socket(wrapper, "hardpoint_remote_turret_left#stack").text(),
    ).toContain("2");

    await choose(
      wrapper,
      "hardpoint_remote_turret_left/turret_left/hardpoint_class_2",
      "Other Gun",
    );
    await save(wrapper);

    expect(
      (savedItems() as { slotPath: string }[]).map((item) => item.slotPath),
    ).toEqual([
      "hardpoint_remote_turret_left/turret_left/hardpoint_class_2",
      "hardpoint_remote_turret_left/turret_right/hardpoint_class_2",
      "hardpoint_remote_turret_right/turret_left/hardpoint_class_2",
      "hardpoint_remote_turret_right/turret_right/hardpoint_class_2",
    ]);
  });

  it("stacks even two identical slots", async () => {
    const allStop = { id: "as", name: "AllStop", size: "1" };
    hullSlots.value = [
      shieldSlot("hardpoint_shield_generator_left", allStop),
      shieldSlot("hardpoint_shield_generator_right", allStop),
    ];
    const wrapper = await mountClosed(vehicle(), { tab: "shields" });
    await flushPromises();

    expect(
      socket(wrapper, "hardpoint_shield_generator_left#stack").text(),
    ).toContain("2");
  });

  it("shows a spinner, not the last slot's parts, while a slot's parts load", async () => {
    componentOptions.value = [{ component: OTHER_GUN, slots: [] }];
    optionsStale.value = true;
    const wrapper = await mountClosed(vehicle(), { tab: "weapons" });
    await flushPromises();

    await socket(wrapper, "hardpoint_gun_nose/hardpoint_class_2").trigger(
      "click",
    );
    await flushPromises();

    expect(wrapper.find("[data-test='loadout-picker-loading']").exists()).toBe(
      true,
    );
    expect(wrapper.findAll("[data-test='loadout-picker-option']")).toHaveLength(
      0,
    );
  });

  it("lists under a module what it brings, a rack's missile slots included", async () => {
    const saved = modules.value;
    modules.value = {
      items: [
        {
          id: "m1",
          name: "Combat Module",
          slug: "combat",
          slot: "hardpoint_module",
          hardpoints: [
            {
              id: "module-rack",
              name: "hardpoint_missile_rack",
              category: "missile_racks",
              minSize: 2,
              maxSize: 2,
              types: ["MissileLauncher"],
              component: {
                id: "rack",
                name: "Module Rack",
                size: "2",
                hardpoints: [
                  {
                    id: "rack-port",
                    name: "missile_01_attach",
                    category: "weapons",
                    minSize: 1,
                    maxSize: 1,
                    types: ["Missile"],
                    component: { id: "ms", name: "Spark I", size: "1" },
                    hardpoints: [],
                  },
                ],
              },
              hardpoints: [],
            },
          ],
        },
      ] as unknown as ModelModule[],
    };
    hullSlots.value = [
      {
        name: "hardpoint_module",
        hardpointId: "hull-module",
        category: "module",
        types: ["Module"],
        editable: true,
        slots: [],
      },
    ];
    const fitted = vehicle(["m1"], { fitted: { hardpoint_module: "m1" } });

    const modulesTab = await mountClosed(fitted, { tab: "modules" });
    await flushPromises();
    expect(socket(modulesTab, "hardpoint_module").text()).toContain(
      "Module Rack",
    );

    const missiles = await mountClosed(fitted, { tab: "missiles" });
    await flushPromises();
    expect(
      socket(
        missiles,
        "hardpoint_module/hardpoint_missile_rack/missile_01_attach",
      ).text(),
    ).toContain("Spark I");

    modules.value = saved;
  });

  it("leaves out ports for parts no loadout fits, but keeps a drive's jump drive", async () => {
    hullSlots.value = [
      {
        name: "hardpoint_radar",
        hardpointId: "hull-radar",
        category: "radar",
        types: ["Radar"],
        editable: true,
        stock: { id: "r1", name: "Capston", size: "1" },
        slots: [
          {
            name: "batteryport",
            hardpointId: "battery",
            types: ["Battery"],
            editable: true,
            slots: [],
          },
        ],
      },
      {
        name: "hardpoint_quantum_drive",
        hardpointId: "hull-qd",
        category: "quantumdrive",
        types: ["QuantumDrive"],
        editable: true,
        stock: { id: "q1", name: "Atlas", size: "1" },
        slots: [
          {
            name: "hardpoint_jump_drive",
            hardpointId: "jump",
            types: ["JumpDrive"],
            editable: true,
            stock: { id: "j1", name: "Explorer", size: "1" },
            slots: [],
          },
        ],
      },
    ];
    const radar = await mountClosed(vehicle(), { tab: "radar" });
    await flushPromises();
    expect(
      radar
        .find("[data-test='loadout-socket-hardpoint_radar/batteryport']")
        .exists(),
    ).toBe(false);

    const quantum = await mountClosed(vehicle(), { tab: "quantumDrives" });
    await flushPromises();
    expect(
      socket(quantum, "hardpoint_quantum_drive/hardpoint_jump_drive").text(),
    ).toContain("Explorer");
  });

  it("keeps a tab open on a slot the game locks, and disables the slot", async () => {
    hullSlots.value = [
      {
        ...shieldSlot("hardpoint_lifesupport", {
          id: "ls",
          name: "ComfortAir",
          size: "1",
        }),
        category: "lifesupport",
        types: ["LifeSupportGenerator"],
        editable: false,
      },
    ];
    const wrapper = await mountClosed(vehicle(), { tab: "lifeSupport" });
    await flushPromises();

    expect(
      wrapper
        .findAllComponents({ name: "FormTab" })
        .find((tab) => tab.props("id") === "lifeSupport")
        ?.props("disabled"),
    ).toBe(false);
    expect(
      socket(wrapper, "hardpoint_lifesupport").attributes("role"),
    ).toBeUndefined();
    expect(socket(wrapper, "hardpoint_lifesupport").text()).toContain(
      "labels.loadoutPicker.fixedByShip",
    );
  });

  it("says on a slot that nothing but its stock part fits", async () => {
    hullSlots.value = [
      {
        ...shieldSlot("hardpoint_lifesupport", {
          id: "ls",
          name: "ComfortAir",
          size: "1",
        }),
        category: "lifesupport",
        types: ["LifeSupportGenerator"],
        swappable: false,
      },
    ];
    const wrapper = await mountClosed(vehicle(), { tab: "lifeSupport" });
    await flushPromises();

    expect(socket(wrapper, "hardpoint_lifesupport").text()).toContain(
      "labels.loadoutPicker.noOtherPart",
    );
  });

  it("counts a gun whose port names no category in the weapon figures", async () => {
    const gun = {
      id: "gun-dps",
      name: "Damage Gun",
      size: "3",
      category: "weapons",
      type: "WeaponGun",
      typeData: { fireRate: 600, damagePerShot: { energy: 10 } },
    };
    hullSlots.value = [
      {
        name: "hardpoint_gun_nose",
        hardpointId: "hull-nose",
        category: "weapon_mounts",
        minSize: 3,
        maxSize: 3,
        types: ["Turret"],
        editable: true,
        stock: STOCK_GIMBAL,
        slots: [{ ...gunPort("hardpoint_class_2", gun), category: "unknown" }],
      },
    ];
    modelHardpoints.value = [
      {
        id: "hp-nose",
        name: "hardpoint_gun_nose",
        category: "weapon_mounts",
        component: STOCK_GIMBAL,
        hardpoints: [],
      },
    ];
    const wrapper = await mountClosed(vehicle(), { tab: "weapons" });
    await flushPromises();

    expect(
      wrapper.get("[data-test='vehicle-loadout-metric-dps']").text(),
    ).toContain("100");
  });

  it("disables a category the ship has no slots for", async () => {
    const wrapper = await mountClosed(vehicle(), { tab: "weapons" });
    await flushPromises();

    expect(
      wrapper
        .findAllComponents({ name: "FormTab" })
        .find((tab) => tab.props("id") === "shields")
        ?.props("disabled"),
    ).toBe(true);
  });
});
