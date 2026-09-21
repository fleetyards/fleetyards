import { mount } from "@vue/test-utils";
import { describe, expect, it, vi } from "vitest";
import type { ItemAvailability, ItemPrice } from "@/services/fyApi";
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

const availability = (attributes: Partial<ItemAvailability> = {}) =>
  ({ boughtAt: [], soldAt: [], ...attributes }) as ItemAvailability;

// The card frame is Panel's and says nothing this asserts on, so it is stubbed
// down to its slot rather than mounted.
const mountWith = (props: {
  availability?: ItemAvailability;
  scope?: "component" | "commodity";
  retired?: boolean;
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
  wrapper.find('[data-test="availability-empty"]').text();

describe("Availability", () => {
  it("leads with the cheapest of the shops selling it", () => {
    const wrapper = mountWith({
      availability: availability({
        soldAt: [
          itemPrice({ id: "buy-1", price: 4390 }),
          itemPrice({ id: "buy-2", price: 3980 }),
        ],
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
      availability: availability({
        boughtAt: [
          itemPrice({ id: "sell-1", price: 1800 }),
          itemPrice({ id: "sell-2", price: 2100 }),
        ],
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
      availability: availability({ boughtAt, soldAt }),
    });

    await wrapper.get('[data-test="availability-all"]').trigger("click");

    expect(emit).toHaveBeenCalledWith(
      "open-modal",
      expect.objectContaining({ props: { soldAt, boughtAt } }),
    );

    emit.mockRestore();
  });

  // The three answers an empty panel cannot tell apart.
  describe("with no prices at all", () => {
    it("says nothing trades it", () => {
      expect(emptyText(mountWith({ availability: availability() }))).toBe(
        "labels.component.availability.none",
      );
    });

    it("points at the recipe when there is one", () => {
      expect(
        emptyText(mountWith({ availability: availability(), craftable: true })),
      ).toBe("labels.component.availability.craftedOnly");
    });

    // The price sync only ever looks at the build the catalogue is on, so for
    // a part it has dropped an absent price is not evidence of anything.
    it("says prices are not tracked for a component the build has dropped", () => {
      expect(
        emptyText(
          mountWith({
            availability: availability(),
            retired: true,
            craftable: true,
          }),
        ),
      ).toBe("labels.component.availability.retired");
    });

    // What it means for nothing to sell a ship part and nothing to sell a
    // commodity are different sentences; everything else on the card is not.
    it("words the empty case for the catalogue asking", () => {
      expect(
        emptyText(
          mountWith({ availability: availability(), scope: "commodity" }),
        ),
      ).toBe("labels.commodity.availability.none");
    });

    it("says nothing while the recipe lookup is still out", () => {
      const wrapper = mountWith({
        availability: availability(),
        loading: true,
      });

      expect(wrapper.find('[data-test="availability-empty"]').exists()).toBe(
        false,
      );
    });
  });
});
