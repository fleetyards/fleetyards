import { describe, expect, it } from "vitest";
import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { type Model } from "@/services/fyApi";
import Component from "./index.vue";

const model = {
  slug: "gladius",
  metrics: { hullHealth: 6110, cargo: 0 },
  speeds: { scmSpeed: 226, scmSpeedBoosted: 520, maxSpeed: 1193 },
} as unknown as Model;

const figure = (key: string) =>
  `[data-test='hardpoints-summary-figure-${key}']`;

describe("HardpointsSummaryFigures", () => {
  it("leaves out a figure the ship does not have", async () => {
    const wrapper = await mountWithDefaults(Component, {
      props: { model, dps: 1945 },
    });

    expect(wrapper.find(figure("dps")).text()).toContain("DPS");
    expect(wrapper.find(figure("scm")).text()).toContain("226");
    expect(wrapper.find(figure("cargo")).exists()).toBe(false);
    expect(wrapper.find(figure("missiles")).exists()).toBe(false);
  });

  it("holds the derived figures open until the hardpoints arrive", async () => {
    const wrapper = await mountWithDefaults(Component, {
      props: { model, pending: true },
    });

    expect(wrapper.find(figure("dps")).text()).toContain("–");
    expect(wrapper.find(figure("shield")).text()).toContain("–");
  });

  it("uses a loadout's own holds", async () => {
    const wrapper = await mountWithDefaults(Component, {
      props: {
        model: { ...model, metrics: { maxCargo: 696, cargo: 100 } } as Model,
        cargoHolds: [{ capacity: 480 }] as never,
        fittedHolds: true,
      },
    });

    expect(wrapper.find(figure("cargo")).text()).toContain("480");
  });

  it("uses the base metrics' cargo until a module changes the holds", async () => {
    const wrapper = await mountWithDefaults(Component, {
      props: {
        model: { ...model, metrics: { maxCargo: 696, cargo: 100 } } as Model,
        cargoHolds: [{ capacity: 480 }] as never,
      },
    });

    expect(wrapper.find(figure("cargo")).text()).toContain("696");
  });
});
