import { describe, it, expect, vi } from "vitest";
import { ref, computed, nextTick } from "vue";
import { mount } from "@vue/test-utils";

vi.mock("@/shared/composables/useI18n", () => ({
  useI18n: () => ({
    t: (key: string) => key,
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

function mountFlight(ratio: number) {
  const enginePowerRatio = ref(ratio);
  const wrapper = mount(FlightMetrics, {
    props: { model: model() },
    global: {
      provide: { enginePowerRatio },
      stubs: { MetricsCard: { template: "<div><slot /></div>" } },
    },
  });
  return { wrapper, enginePowerRatio };
}

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
    // engine floor there's simply no afterburner boost to show.
    const { wrapper, enginePowerRatio } = mountFlight(1);
    enginePowerRatio.value = 0;
    await nextTick();
    expect(wrapper.findAll(".flight-rot__value").map((n) => n.text())).toEqual([
      "10",
      "10",
      "17",
    ]);
    expect(wrapper.findAll(".flight-rot__boost")).toHaveLength(0);
  });
});
