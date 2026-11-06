import { beforeEach, describe, expect, it, vi } from "vitest";
import { createMemoryHistory, createRouter } from "vue-router";
import { mountWithDefaults } from "@/shared/utils/TestUtils";
import {
  HardpointCategoryEnum,
  HardpointGroupEnum,
  HardpointSourceEnum,
  type Hardpoint,
  type Model,
} from "@/services/fyApi";
import Component from "./index.vue";

const hardpoints = ref<Hardpoint[]>([]);
const queriedSource = vi.fn();

vi.mock("@/services/fyApi", async (importOriginal) => ({
  ...(await importOriginal<Record<string, unknown>>()),
  useModelHardpoints: (_slug: unknown, params: Ref<{ source: string }>) => {
    queriedSource(params.value.source);

    return {
      data: hardpoints,
      isLoading: ref(false),
      isFetching: ref(false),
    };
  },
}));

const router = createRouter({
  history: createMemoryHistory(),
  routes: [
    { path: "/", component: { template: "<div />" } },
    {
      path: "/components/:slug",
      name: "component",
      component: { template: "<div />" },
    },
  ],
});

const model = {
  slug: "gladius",
  name: "Gladius",
  inGame: true,
  metrics: { hullHealth: 6110, cargo: 0 },
  speeds: { scmSpeed: 226, scmSpeedBoosted: 520, maxSpeed: 1193 },
} as unknown as Model;

const shieldGenerator = (id: string) =>
  ({
    id,
    name: `hardpoint_shield_${id}`,
    source: HardpointSourceEnum.GAME_FILES,
    group: HardpointGroupEnum.SYSTEM,
    category: HardpointCategoryEnum.SHIELDGENERATOR,
    maxSize: 1,
    component: {
      id: "allstop",
      name: "AllStop",
      slug: "allstop",
      catalogued: true,
      itemClass: "military",
      itemClassLabel: "Military",
      gradeLabel: "C",
      typeData: { maxShieldHealth: 3168, maxShieldRegen: 600 },
    },
  }) as unknown as Hardpoint;

describe("ModelHardpointsMinimal", () => {
  beforeEach(() => {
    hardpoints.value = [shieldGenerator("a"), shieldGenerator("b")];
    queriedSource.mockClear();
  });

  it("leaves out a figure the ship does not have", async () => {
    const wrapper = await mountWithDefaults(Component, {
      props: { model },
      plugins: [router],
    });

    expect(
      wrapper.find("[data-test='hardpoints-minimal-figure-scm']").text(),
    ).toContain("226");
    expect(
      wrapper.find("[data-test='hardpoints-minimal-figure-cargo']").exists(),
    ).toBe(false);
    expect(
      wrapper.find("[data-test='hardpoints-minimal-figure-missiles']").exists(),
    ).toBe(false);

    wrapper.unmount();
  });

  it("keeps a component's tooltip and catalogue link on a stacked row", async () => {
    const wrapper = await mountWithDefaults(Component, {
      props: { model },
      plugins: [router],
    });

    const rows = wrapper.findAll("[data-test='hardpoints-minimal-row']");

    expect(rows).toHaveLength(1);
    expect(rows[0].text()).toContain("×2");
    expect(rows[0].text()).toContain("Military");
    expect(rows[0].find("[data-test='popover-trigger']").exists()).toBe(true);
    expect(rows[0].find("a").exists()).toBe(true);

    wrapper.unmount();
  });

  it("shows a ship without game files as a list, with no figures", async () => {
    hardpoints.value = [
      {
        id: "matrix",
        name: "Size 3 Gun",
        source: HardpointSourceEnum.SHIP_MATRIX,
        group: HardpointGroupEnum.WEAPON,
        category: HardpointCategoryEnum.WEAPONS,
        maxSize: 3,
      } as unknown as Hardpoint,
    ];

    const wrapper = await mountWithDefaults(Component, {
      props: { model: { ...model, inGame: false } },
      plugins: [router],
    });

    expect(queriedSource).toHaveBeenCalledWith(HardpointSourceEnum.SHIP_MATRIX);
    expect(wrapper.find(".metrics-card__hero").exists()).toBe(false);
    expect(wrapper.text()).toContain("Size 3 Gun");

    wrapper.unmount();
  });
});
