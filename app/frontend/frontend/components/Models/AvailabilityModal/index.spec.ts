import { mount } from "@vue/test-utils";
import { describe, expect, it, vi } from "vitest";
import type { ItemPrice } from "@/services/fyApi";
import Component from "./index.vue";

vi.mock("@/shared/composables/useI18n", () => ({
  useI18n: () => ({
    t: (key: string) => key,
    toUEC: (value: unknown) => String(value),
  }),
}));

const itemPrice = (attributes: Partial<ItemPrice>) =>
  ({
    id: "price-1",
    price: 100,
    location: "Astro Armada - Area 18",
    ...attributes,
  }) as ItemPrice;

const mountWith = (props: { soldAt?: ItemPrice[]; rentalAt?: ItemPrice[] }) =>
  mount(Component, {
    props,
    global: { stubs: { Modal: { template: "<div><slot /></div>" } } },
  });

describe("ModelAvailabilityModal", () => {
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
