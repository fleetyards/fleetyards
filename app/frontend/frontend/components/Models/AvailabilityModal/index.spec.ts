import { mount } from "@vue/test-utils";
import { describe, expect, it, vi } from "vitest";
import type { ItemPrice } from "@/services/fyApi";
import Component from "./index.vue";

vi.mock("@/shared/composables/useI18n", () => ({
  useI18n: () => ({
    t: (key: string, options?: { count?: number }) =>
      options?.count === undefined ? key : `${key}:${options.count}`,
    toNumber: (value: unknown) => String(value),
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

const texts = (
  wrapper: ReturnType<typeof mountWith>,
  selector: string,
): string[] => wrapper.findAll(selector).map((node) => node.text());

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

  it("leads with the cheapest price per section and counts its locations", () => {
    const wrapper = mountWith({
      soldAt: [
        itemPrice({ id: "buy-1", price: 1358280 }),
        itemPrice({ id: "buy-2", price: 1290370 }),
      ],
      rentalAt: [itemPrice({ id: "rent-1", price: 27165 })],
    });

    expect(texts(wrapper, ".availability__tile__value")).toEqual([
      "1290370 number.units.uec",
      "27165 number.units.uec",
    ]);
    expect(texts(wrapper, ".availability__tile__sub")).toEqual([
      "labels.availability.locations:2",
      "labels.availability.locations:1",
    ]);
  });

  it("marks the cheapest row and prices the rest as a premium over it", () => {
    const wrapper = mountWith({
      soldAt: [
        itemPrice({ id: "buy-1", price: 1358280 }),
        itemPrice({ id: "buy-2", price: 1290370 }),
      ],
    });

    expect(texts(wrapper, ".availability__price")).toEqual([
      "1290370",
      "1358280",
    ]);
    expect(texts(wrapper, ".availability__price--best")).toEqual(["1290370"]);
    // 1,358,280 / 1,290,370 - 1 = 5.3%
    expect(texts(wrapper, ".availability__premium")).toEqual(["+5%"]);
  });

  it("gives rows a rental period only once the periods differ", () => {
    const oneDay = [
      itemPrice({ id: "rent-1", price: 27165, timeRange: "1-day" }),
      itemPrice({ id: "rent-2", price: 28350, timeRange: "1-day" }),
    ];

    expect(
      texts(mountWith({ rentalAt: oneDay }), ".availability__range"),
    ).toEqual([]);

    const mixed = [
      ...oneDay,
      itemPrice({ id: "rent-3", price: 509344, timeRange: "30-days" }),
    ];

    expect(
      texts(mountWith({ rentalAt: mixed }), ".availability__range"),
    ).toEqual([
      "labels.availability.timeRange.1-day",
      "labels.availability.timeRange.1-day",
      "labels.availability.timeRange.30-days",
    ]);
  });

  it("splits the terminal name into shop and place", () => {
    const wrapper = mountWith({
      soldAt: [
        itemPrice({
          location: "Traveler Rentals - Cargo Center - Terra Gateway",
        }),
      ],
    });

    expect(wrapper.get(".availability__shop").text()).toBe("Traveler Rentals");
    expect(wrapper.get(".availability__place").text()).toBe(
      "Cargo Center · Terra Gateway",
    );
  });
});
