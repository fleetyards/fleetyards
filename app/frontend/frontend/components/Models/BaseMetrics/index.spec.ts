import { mount } from "@vue/test-utils";
import { describe, expect, it, vi } from "vitest";
import type { Model, ItemPrice } from "@/services/fyApi";
import Component from "./index.vue";

vi.mock("@/shared/composables/useI18n", () => ({
  useI18n: () => ({
    t: (key: string) => key,
    toNumber: (value: unknown) => String(value),
    toDollar: (value: unknown) => String(value),
    toUEC: (value: unknown) => String(value),
  }),
}));

const itemPrice = (attributes: Partial<ItemPrice>) =>
  ({
    id: "price-1",
    location: "Astro Armada - Area 18",
    ...attributes,
  }) as ItemPrice;

const model = (availability: Partial<Model["availability"]>) =>
  ({
    availability: { boughtAt: [], soldAt: [], rentalAt: [], ...availability },
    classificationLabel: "Multi-Role",
    metrics: {},
  }) as unknown as Model;

const mountWith = (availability: Partial<Model["availability"]>) =>
  mount(Component, {
    props: { model: model(availability) },
    global: { directives: { tooltip: () => {} } },
  });

describe("ModelBaseMetrics", () => {
  it("credits UEX when a sale location is shown", () => {
    const link = mountWith({ soldAt: [itemPrice({})] }).get(
      'a[href="https://uexcorp.space"]',
    );

    expect(link.text()).toContain("model.poweredByUex");
  });

  it("credits UEX when only a rental location is shown", () => {
    const wrapper = mountWith({
      rentalAt: [itemPrice({ id: "price-2", timeRange: "1-day" })],
    });

    expect(wrapper.find('a[href="https://uexcorp.space"]').exists()).toBe(true);
  });

  it("omits the credit when the ship has no availability", () => {
    const wrapper = mountWith({});

    expect(wrapper.find('a[href="https://uexcorp.space"]').exists()).toBe(
      false,
    );
  });
});
