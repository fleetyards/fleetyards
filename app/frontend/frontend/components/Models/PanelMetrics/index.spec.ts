import { describe, it, expect, vi } from "vitest";
import { mount } from "@vue/test-utils";

vi.mock("@/shared/composables/useI18n", () => ({
  useI18n: () => ({
    t: (key: string) => key,
    toNumber: (value: unknown) => String(value),
    toUEC: (value: unknown) => String(value),
  }),
}));

import PanelMetrics from "./index.vue";

/*
 * The expanded card's details. What is worth pinning is which figures reach it:
 * ship-matrix speeds are not meaningful, so speed is shown only for models whose
 * numbers come from the game files, and both figures share one row.
 */
const model = (overrides: Record<string, unknown> = {}) =>
  ({
    focus: "Modular",
    crew: { min: 1, max: 6 },
    inGame: true,
    speeds: { scmSpeed: 210, maxSpeed: 1125, groundMaxSpeed: 90 },
    metrics: {
      isGroundVehicle: false,
      length: 110,
      beam: 60,
      height: 22,
      mass: null,
      cargo: 64,
    },
    ...overrides,
  }) as never;

const labels = (wrapper: ReturnType<typeof mount>) =>
  wrapper
    .findAll(".metrics-card__row__label")
    .map((node) => node.text().trim());

const valueFor = (wrapper: ReturnType<typeof mount>, label: string) =>
  wrapper
    .findAll(".metrics-card__row")
    .find(
      (row) => row.find(".metrics-card__row__label").text().trim() === label,
    )
    ?.find(".metrics-card__row__value")
    .text()
    .trim();

describe("PanelMetrics", () => {
  it("puts both speeds of an in-game ship in one row", () => {
    const wrapper = mount(PanelMetrics, { props: { model: model() } });

    expect(labels(wrapper)).toContain("model.speed");
    expect(labels(wrapper).filter((l) => l === "model.speed")).toHaveLength(1);

    const speed = valueFor(wrapper, "model.speed");
    expect(speed).toContain("210");
    expect(speed).toContain("1125");
  });

  it("shows one figure for an in-game ground vehicle", () => {
    const wrapper = mount(PanelMetrics, {
      props: {
        model: model({
          metrics: {
            isGroundVehicle: true,
            length: 5,
            beam: 2,
            height: 2,
            mass: null,
            cargo: 0,
          },
        }),
      },
    });

    expect(valueFor(wrapper, "model.speed")).toBe("90");
  });

  it("shows no speed for a ship-matrix model", () => {
    // inGame false means the figures come from the ship matrix, where they are
    // not meaningful - the case that took the rows out in the first place.
    const wrapper = mount(PanelMetrics, {
      props: { model: model({ inGame: false }) },
    });

    expect(labels(wrapper)).not.toContain("model.speed");
  });

  it("always shows the dimensions", () => {
    const wrapper = mount(PanelMetrics, {
      props: { model: model({ inGame: false }) },
    });

    for (const key of [
      "model.length",
      "model.beam",
      "model.height",
      "model.mass",
      "model.cargo",
    ]) {
      expect(labels(wrapper)).toContain(key);
    }
  });

  it("uses the metrics-card primitives rather than its own markup", () => {
    // The old block was .metrics-label / .metrics-value pairs in nested
    // Bootstrap rows; it shares the ship page's row primitives now.
    const wrapper = mount(PanelMetrics, { props: { model: model() } });

    expect(wrapper.find(".metrics-card__rows").exists()).toBe(true);
    expect(wrapper.find(".metrics-card__divider").exists()).toBe(true);
    expect(wrapper.find(".metrics-label").exists()).toBe(false);
    expect(wrapper.find(".metrics-value").exists()).toBe(false);
  });
});
