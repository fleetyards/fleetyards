import { describe, it, expect, vi } from "vitest";
import { ref, computed, nextTick } from "vue";
import { mount } from "@vue/test-utils";

vi.mock("@/shared/composables/useI18n", () => ({
  useI18n: () => ({
    t: (key: string) => (key === "number.format.separator" ? "," : key),
    toNumber: (value: number) => String(value),
  }),
}));

// Passthrough useTransition so we assert the target value without waiting on the
// animation clock — the point of the test is the reactivity, not the tween.
vi.mock("@vueuse/core", async (importOriginal) => {
  const actual = await importOriginal<typeof import("@vueuse/core")>();
  return {
    ...actual,
    useTransition: (source: unknown) =>
      computed(() =>
        typeof source === "function"
          ? (source as () => number)()
          : (source as { value: number }).value,
      ),
    TransitionPresets: { easeOutCubic: [] },
  };
});

import FlightMetrics from "./index.vue";

const model = () =>
  ({
    speeds: {
      scmSpeed: 110,
      scmSpeedBoosted: 290,
      maxSpeed: 1000,
      pitch: 10,
      pitchBoosted: 12,
      yaw: 10,
      yawBoosted: 12,
      roll: 17,
      rollBoosted: 20,
    },
    metrics: { isGroundVehicle: false },
  }) as never;

function mountFlight(
  ratio: number,
  powered = true,
  boostCapacitor?: Record<string, number>,
) {
  const enginePowerRatio = ref(ratio);
  const enginePowered = ref(powered);
  const wrapper = mount(FlightMetrics, {
    props: { model: model(), boostCapacitor } as never,
    global: {
      provide: { enginePowerRatio, enginePowered },
      stubs: { MetricsCard: { template: "<div><slot /></div>" } },
    },
  });
  return { wrapper, enginePowerRatio, enginePowered };
}

const values = (wrapper: ReturnType<typeof mountFlight>["wrapper"]) =>
  wrapper.findAll(".flight-rot__value").map((n) => n.text());

const boosts = (wrapper: ReturnType<typeof mountFlight>["wrapper"]) =>
  wrapper.findAll(".flight-rot__boost").map((n) => n.text());

describe("FlightMetrics engine reactivity", () => {
  it("shows the rated boosted handling at full engine power", () => {
    const { wrapper } = mountFlight(1);
    expect(boosts(wrapper)).toEqual(["→ 12", "→ 12", "→ 20"]);
  });

  it("interpolates boosted handling down as engine pips drop", async () => {
    const { wrapper, enginePowerRatio } = mountFlight(1);
    enginePowerRatio.value = 0.5;
    await nextTick();
    // pitch 10 + (12-10)*0.5 = 11, yaw 11, roll 17 + (20-17)*0.5 = 18.5 → 19
    expect(boosts(wrapper)).toEqual(["→ 11", "→ 11", "→ 19"]);
  });

  it("keeps base handling and hides the boost at the engine floor (ratio 0)", async () => {
    // The IFCS speeds/base handling are constant game figures; at the mandatory
    // engine floor (still powered) there's simply no afterburner boost to show.
    const { wrapper, enginePowerRatio } = mountFlight(1);
    enginePowerRatio.value = 0;
    await nextTick();
    expect(values(wrapper)).toEqual(["10", "10", "17"]);
    expect(wrapper.findAll(".flight-rot__boost")).toHaveLength(0);
  });

  it("zeroes every flight figure when the engine is fully unpowered", async () => {
    // Last pip pulled → no power to the engine → dead in the water.
    const { wrapper, enginePowered } = mountFlight(1);
    enginePowered.value = false;
    await nextTick();
    expect(values(wrapper)).toEqual(["0", "0", "0"]);
    expect(wrapper.findAll(".flight-rot__boost")).toHaveLength(0);
    // SCM / Boost / Max hero tiles all read 0 as well.
    expect(
      wrapper.findAll(".metrics-card__tile__value").map((n) => n.text()),
    ).toEqual(["0", "0", "0"]);
  });
});

describe("FlightMetrics boost capacitor", () => {
  it("lists the installed controller's boost pool", () => {
    const { wrapper } = mountFlight(1, true, {
      capacity: 25,
      regenPerSecond: 0.75,
      regenDelay: 1.1,
      rampUpTime: 0.4,
      rampDownTime: 0,
    });

    const rows = wrapper
      .findAll(".metrics-card__row")
      .map((row) => [
        row.find(".metrics-card__row__label").text(),
        row.find(".metrics-card__row__value").text(),
      ]);

    expect(rows).toEqual([
      ["labels.flight.boostCapacity", "25"],
      ["labels.flight.boostRegen", "0,75/s"],
      ["labels.flight.boostRegenDelay", "1,1 s"],
      ["labels.flight.boostRamp", "0,4 / 0 s"],
    ]);
  });

  it("shows no boost section without a controller", () => {
    const { wrapper } = mountFlight(1);

    expect(wrapper.text()).not.toContain("labels.flight.boostCapacitor");
  });
});
