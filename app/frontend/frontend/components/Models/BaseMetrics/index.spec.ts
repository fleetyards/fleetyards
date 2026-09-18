import { describe, it, expect, vi } from "vitest";
import { mount } from "@vue/test-utils";
import type { Model, ModelMetrics } from "@/services/fyApi";
import { ModelStateEnum } from "@/frontend/composables/useModelStates";

vi.mock("@/shared/composables/useI18n", () => ({
  useI18n: () => ({
    t: (key: string) => key,
    toNumber: (value: number | string) => String(value),
    toDollar: (value: number) => String(value),
    toUEC: (value: number) => String(value),
  }),
}));

vi.mock("@/shared/composables/useComlink", () => ({
  useComlink: () => ({ emit: vi.fn() }),
}));

import BaseMetrics from "./index.vue";

const model = (metrics: Partial<ModelMetrics> = {}): Model =>
  ({
    availability: {},
    metrics: { length: 23.58, beam: 19.62, height: 3.28, ...metrics },
  }) as Model;

const mountCard = (
  state: ModelStateEnum,
  metrics: Partial<ModelMetrics> = {},
) =>
  mount(BaseMetrics, {
    props: { model: model(metrics), state },
    global: {
      stubs: {
        MetricsCard: {
          template: "<div><slot name='head' /><slot /></div>",
        },
      },
      directives: { Tooltip: {} },
    },
  });

const tiles = (wrapper: ReturnType<typeof mountCard>) =>
  wrapper.findAll(".metrics-card__tile__value").map((tile) => tile.text());

describe("the dimensions the card shows", () => {
  it("shows the flight figures, and no state chip for them", () => {
    const wrapper = mountCard(ModelStateEnum.FLIGHT, { landedHeight: 4.24 });

    expect(tiles(wrapper).slice(0, 3)).toEqual(["23.58", "19.62", "3.28"]);
    expect(wrapper.find('[data-test="model-state-chip"]').exists()).toBe(false);
  });

  // One figure, never two: the chip is what says which state it is.
  it("swaps in the landed figure and names the state", () => {
    const wrapper = mountCard(ModelStateEnum.LANDED, { landedHeight: 4.24 });

    expect(tiles(wrapper).slice(0, 3)).toEqual(["23.58", "19.62", "4.24"]);
    expect(wrapper.find('[data-test="model-state-chip"]').text()).toBe(
      "labels.model.state.landed",
    );
  });
});
