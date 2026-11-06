import { describe, expect, it, vi } from "vitest";
import { mountWithDefaults } from "@/shared/utils/TestUtils";
import {
  HardpointCategoryEnum,
  HardpointGroupEnum,
  HardpointSourceEnum,
  type Hardpoint,
  type Model,
} from "@/services/fyApi";
import { useModelsStore } from "@/frontend/stores/models";
import Component from "./index.vue";

const queried = vi.fn();

vi.mock("@/services/fyApi", async (importOriginal) => ({
  ...(await importOriginal<Record<string, unknown>>()),
  useModelHardpoints: (
    _slug: unknown,
    _params: unknown,
    options: { query: { enabled: () => boolean } },
  ) => {
    queried(options.query.enabled());

    return {
      data: ref([]),
      isLoading: ref(false),
      isFetching: ref(false),
      refetch: () => Promise.resolve(),
    };
  },
}));

const model = {
  slug: "retaliator",
  inGame: true,
  metrics: {},
  speeds: {},
} as unknown as Model;

const moduleSlot = {
  id: "front",
  name: "hardpoint_front_module",
  group: HardpointGroupEnum.SYSTEM,
  category: HardpointCategoryEnum.MODULE,
  source: HardpointSourceEnum.GAME_FILES,
  component: { id: "m1", name: "Cargo Module" },
  hardpoints: [],
} as unknown as Hardpoint;

describe("Hardpoints with a loadout's fitting", () => {
  it("lists the fitting read-only and leaves the hull's own hardpoints unasked for", async () => {
    queried.mockClear();

    const wrapper = await mountWithDefaults(Component, {
      props: { model, fitting: [moduleSlot] },
    });

    expect(queried).toHaveBeenCalledWith(false);
    expect(wrapper.text()).toContain("Cargo Module");
    expect(wrapper.find(".module-select-btn").exists()).toBe(false);
    expect(wrapper.find(".hardpoints__source").exists()).toBe(false);
    expect(wrapper.find(".hardpoints__links").exists()).toBe(false);

    wrapper.unmount();
  });

  it("marks the rows the loadout fits differently from the stock ship", async () => {
    const swapped = {
      ...moduleSlot,
      id: "rear",
      name: "hardpoint_rear_module",
      component: { id: "m2", name: "Living Module" },
    } as unknown as Hardpoint;

    const wrapper = await mountWithDefaults(Component, {
      props: {
        model,
        fitting: [moduleSlot, swapped],
        changed: new Set([swapped.id]),
      },
    });

    const marked = wrapper.findAll("[data-changed]");
    expect(marked).toHaveLength(1);
    expect(marked[0].text()).toContain("Living Module");

    wrapper.unmount();
  });

  it("shows the fitting's figures whatever the model's in-game flag", async () => {
    const wrapper = await mountWithDefaults(Component, {
      props: {
        model: { ...model, inGame: false, metrics: { hullHealth: 1000 } },
        fitting: [moduleSlot],
      },
    });

    expect(
      wrapper.find("[data-test='hardpoints-summary-figures']").exists(),
    ).toBe(true);

    wrapper.unmount();
  });

  describe("cards", () => {
    const cooler = {
      id: "cooler",
      name: "hardpoint_cooler",
      group: HardpointGroupEnum.SYSTEM,
      category: HardpointCategoryEnum.COOLER,
      source: HardpointSourceEnum.GAME_FILES,
      component: { id: "c1", name: "Bracer" },
      hardpoints: [],
    } as unknown as Hardpoint;

    const gun = {
      ...cooler,
      id: "gun",
      name: "hardpoint_gun",
      group: HardpointGroupEnum.WEAPON,
      category: HardpointCategoryEnum.WEAPONS,
      component: { id: "g1", name: "Repeater" },
    } as unknown as Hardpoint;

    const mountFitting = (models: Record<string, unknown> = {}) =>
      mountWithDefaults(Component, {
        props: {
          model,
          fitting: [cooler, gun],
          changed: new Set(["gun"]),
          loadoutId: "loadout-1",
        },
        initialState: { models },
      });

    const summaryRows = (wrapper: Awaited<ReturnType<typeof mountFitting>>) =>
      wrapper.findAll("[data-test='hardpoints-summary-row']");

    it("opens the card holding a change in full and the others on a summary", async () => {
      const wrapper = await mountFitting();

      expect(summaryRows(wrapper)).toHaveLength(1);
      expect(summaryRows(wrapper)[0].text()).toContain("Bracer");
      expect(wrapper.findAll(".hardpoint-item")).toHaveLength(1);
      expect(wrapper.find(".hardpoint-item").text()).toContain("Repeater");

      wrapper.unmount();
    });

    it("remembers collapsing a card that opened in full, per loadout", async () => {
      const flipped = await mountFitting({
        flippedHardpointGroups: { "loadout-1": [HardpointGroupEnum.WEAPON] },
      });

      expect(summaryRows(flipped)).toHaveLength(2);
      flipped.unmount();

      const other = await mountFitting({
        flippedHardpointGroups: { "loadout-2": [HardpointGroupEnum.WEAPON] },
      });

      expect(summaryRows(other)).toHaveLength(1);
      other.unmount();
    });

    it("flips only what expand all has to", async () => {
      const wrapper = await mountFitting({
        flippedHardpointGroups: { "loadout-1": [HardpointGroupEnum.WEAPON] },
      });
      const store = useModelsStore();
      const set = vi.spyOn(store, "setFlippedHardpointGroups");

      await wrapper.find("[data-test='hardpoints-fold-all']").trigger("click");

      expect(set).toHaveBeenCalledWith("loadout-1", [
        HardpointGroupEnum.SYSTEM,
      ]);

      wrapper.unmount();
    });

    it("marks a changed part on its summary row", async () => {
      const wrapper = await mountFitting({
        flippedHardpointGroups: { "loadout-1": [HardpointGroupEnum.WEAPON] },
      });

      const marked = wrapper.findAll(
        "[data-test='hardpoints-summary-row'][data-changed]",
      );

      expect(marked).toHaveLength(1);
      expect(marked[0].text()).toContain("Repeater");

      wrapper.unmount();
    });
  });
});

describe("Hardpoints on the ship page", () => {
  const ship = {
    ...model,
    metrics: { hullHealth: 1000, hullParts: [], hullDoors: [] },
  } as unknown as Model;

  const mountShip = (models: Record<string, unknown> = {}) =>
    mountWithDefaults(Component, {
      props: { model: ship },
      initialState: { models },
    });

  it("opens on the key figures rather than the cards", async () => {
    const wrapper = await mountShip();

    expect(
      wrapper.find("[data-test='hardpoints-summary-figures']").exists(),
    ).toBe(true);
    expect(wrapper.find(".metrics-grid").exists()).toBe(false);
    expect(wrapper.find(".hardpoints__credit").exists()).toBe(false);

    wrapper.unmount();
  });

  it("shows the foldable cards in advanced mode", async () => {
    const wrapper = await mountShip({ shipMetricsAdvanced: true });

    expect(
      wrapper
        .find(".metrics-grid [data-test='metrics-card-collapse']")
        .exists(),
    ).toBe(true);
    expect(
      wrapper.find("[data-test='hardpoints-summary-figures']").exists(),
    ).toBe(false);

    wrapper.unmount();
  });
});
