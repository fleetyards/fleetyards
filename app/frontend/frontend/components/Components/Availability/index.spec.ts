import { mount } from "@vue/test-utils";
import { describe, expect, it, vi } from "vitest";
import type { Component as FyComponent, ItemPrice } from "@/services/fyApi";
import { useComlink } from "@/shared/composables/useComlink";
import Availability from "./index.vue";

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

const component = (attributes: Partial<FyComponent> = {}) =>
  ({
    id: "id",
    name: "A Part",
    slug: "a-part",
    hidden: false,
    retired: false,
    catalogued: true,
    availability: { boughtAt: [], soldAt: [] },
    media: {},
    createdAt: "2026-01-01",
    updatedAt: "2026-01-01",
    ...attributes,
  }) as FyComponent;

// The card frame is Panel's and says nothing this asserts on, so it is stubbed
// down to its slot rather than mounted.
const mountWith = (props: {
  component: FyComponent;
  craftable?: boolean;
  loading?: boolean;
}) =>
  mount(Availability, {
    props,
    global: {
      stubs: { MetricsCard: { template: "<div><slot /></div>" } },
    },
  });

const emptyText = (wrapper: ReturnType<typeof mountWith>) =>
  wrapper.find('[data-test="component-availability-empty"]').text();

describe("ComponentAvailability", () => {
  it("leads with the cheapest of the shops selling it", () => {
    const wrapper = mountWith({
      component: component({
        availability: {
          boughtAt: [],
          soldAt: [
            itemPrice({ id: "buy-1", price: 4390 }),
            itemPrice({ id: "buy-2", price: 3980 }),
          ],
        },
      }),
    });

    expect(wrapper.get(".metrics-card__tile__value").text()).toContain("3980");
    expect(wrapper.get(".metrics-card__tile__sub").text()).toBe(
      "labels.availability.locations:2",
    );
  });

  // UEX prices components in both directions, unlike ships, so the panel says
  // what a terminal pays for one as well as what it charges.
  it("names the best paid of the shops buying it back", () => {
    const wrapper = mountWith({
      component: component({
        availability: {
          boughtAt: [
            itemPrice({ id: "sell-1", price: 1800 }),
            itemPrice({ id: "sell-2", price: 2100 }),
          ],
          soldAt: [],
        },
      }),
    });

    const tiles = wrapper.findAll(".metrics-card__tile");

    expect(tiles).toHaveLength(1);
    expect(tiles[0].text()).toContain("labels.availability.bestSale");
    expect(tiles[0].text()).toContain("2100");
  });

  it("hands both directions to the modal", async () => {
    const soldAt = [itemPrice({ id: "buy-1", price: 4390 })];
    const boughtAt = [itemPrice({ id: "sell-1", price: 1800 })];
    const emit = vi.spyOn(useComlink(), "emit");

    const wrapper = mountWith({
      component: component({ availability: { boughtAt, soldAt } }),
    });

    await wrapper
      .get('[data-test="component-availability-all"]')
      .trigger("click");

    expect(emit).toHaveBeenCalledWith(
      "open-modal",
      expect.objectContaining({ props: { soldAt, boughtAt } }),
    );

    emit.mockRestore();
  });

  // The three answers an empty panel cannot tell apart.
  describe("with no prices at all", () => {
    it("says nothing trades it", () => {
      expect(emptyText(mountWith({ component: component() }))).toBe(
        "labels.component.availability.none",
      );
    });

    it("points at the recipe when there is one", () => {
      expect(
        emptyText(mountWith({ component: component(), craftable: true })),
      ).toBe("labels.component.availability.craftedOnly");
    });

    // The price sync only ever looks at the build the catalogue is on, so for
    // a part it has dropped an absent price is not evidence of anything.
    it("says prices are not tracked for a component the build has dropped", () => {
      expect(
        emptyText(
          mountWith({
            component: component({ retired: true }),
            craftable: true,
          }),
        ),
      ).toBe("labels.component.availability.retired");
    });

    it("says nothing while the recipe lookup is still out", () => {
      const wrapper = mountWith({ component: component(), loading: true });

      expect(
        wrapper.find('[data-test="component-availability-empty"]').exists(),
      ).toBe(false);
    });
  });
});
