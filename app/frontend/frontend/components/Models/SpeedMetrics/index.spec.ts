import { describe, it, expect, vi } from "vitest";
import { mount } from "@vue/test-utils";

vi.mock("@/shared/composables/useI18n", () => ({
  useI18n: () => ({
    t: (key: string) => key,
    toNumber: (value: number, unit: string) => `${value} ${unit}`,
  }),
}));

import SpeedMetrics from "./index.vue";

const ship = (speeds: Record<string, number | null> = {}) =>
  ({
    speeds: {
      scmSpeed: 200,
      maxSpeed: 1000,
      pitch: 10,
      yaw: 10,
      roll: 17,
      mainAcceleration: 50,
      retroAcceleration: 20,
      secondsToScmSpeed: 4,
      secondsToStopFromScmSpeed: 10,
      ...speeds,
    },
    metrics: { isGroundVehicle: false },
  }) as never;

describe("SpeedMetrics", () => {
  it("shows what the thrusters give, and what it means in seconds", () => {
    const wrapper = mount(SpeedMetrics, { props: { model: ship() } });
    const text = wrapper.text();

    expect(text).toContain("50 acceleration");
    expect(text).toContain("20 acceleration");
    expect(text).toContain("4 seconds");
    expect(text).toContain("10 seconds");
  });

  // Null for a concept ship, and for a catalogue loaded before the export named a
  // thruster's type. Nothing to say beats a row of zeros.
  it("leaves the row out when the export described no thrusters", () => {
    const wrapper = mount(SpeedMetrics, {
      props: {
        model: ship({
          mainAcceleration: null,
          retroAcceleration: null,
          secondsToScmSpeed: null,
          secondsToStopFromScmSpeed: null,
        }),
      },
    });

    expect(wrapper.text()).not.toContain("model.mainAcceleration");
    expect(wrapper.text()).toContain("model.scmSpeed");
  });

  it("still shows the rotation figures either way", () => {
    const withAccel = mount(SpeedMetrics, { props: { model: ship() } });
    const without = mount(SpeedMetrics, {
      props: {
        model: ship({ mainAcceleration: null, retroAcceleration: null }),
      },
    });

    for (const wrapper of [withAccel, without]) {
      expect(wrapper.text()).toContain("model.pitch");
      expect(wrapper.text()).toContain("model.yaw");
      expect(wrapper.text()).toContain("model.roll");
    }
  });

  it("shows ground figures for a ground vehicle instead", () => {
    const wrapper = mount(SpeedMetrics, {
      props: {
        model: {
          speeds: {
            groundMaxSpeed: 60,
            groundReverseSpeed: 20,
            groundAcceleration: 5,
            groundDecceleration: 8,
          },
          metrics: { isGroundVehicle: true },
        } as never,
      },
    });

    expect(wrapper.text()).toContain("model.groundMaxSpeed");
    expect(wrapper.text()).not.toContain("model.mainAcceleration");
  });
});
