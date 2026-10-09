import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { afterEach, describe, expect, it, vi } from "vitest";
import Component from "./index.vue";
import type { Tour } from "@/services/fyApi";

const tour = (overrides: Partial<Tour> = {}): Tour =>
  ({
    id: "tour-1",
    title: "Jumptown Run",
    slug: "abc-jumptown-run",
    status: "open",
    ...overrides,
  }) as Tour;

const wrappers: Array<{ unmount: () => void }> = [];

const mount = async (
  props: {
    tours: Tour[];
    loading?: boolean;
    withFleet?: boolean;
  },
  { mobile = false }: { mobile?: boolean } = {},
) => {
  vi.stubGlobal("matchMedia", () => ({ matches: mobile }));

  const wrapper = await mountWithDefaults<typeof Component>(Component, {
    props,
  });
  wrappers.push(wrapper);
  return wrapper;
};

afterEach(() => {
  vi.unstubAllGlobals();
  while (wrappers.length) {
    wrappers.pop()?.unmount();
  }
});

describe("ToursTable", () => {
  it("lists a tour by title", async () => {
    const wrapper = await mount({ tours: [tour()] });

    expect(wrapper.text()).toContain("Jumptown Run");
  });

  // The standalone list mixes fleet tours in with ad-hoc ones, and the column
  // is the only thing telling them apart.
  it("names the fleet only when asked to", async () => {
    const fleetTour = tour({
      fleet: { id: "fleet-1", name: "Blue Sun", slug: "blue-sun" },
    });

    const without = await mount({ tours: [fleetTour] });
    expect(without.text()).not.toContain("Blue Sun");

    const with_ = await mount({ tours: [fleetTour], withFleet: true });
    expect(with_.text()).toContain("Blue Sun");
  });

  // A fourth column pushed the status off the edge of a phone.
  it("puts the fleet under the title on a phone", async () => {
    const fleetTour = tour({
      fleet: { id: "fleet-1", name: "Blue Sun", slug: "blue-sun" },
    });

    const desktop = await mount({ tours: [fleetTour], withFleet: true });
    expect(desktop.find(".tours-table__fleet").exists()).toBe(false);

    const phone = await mount(
      { tours: [fleetTour], withFleet: true },
      { mobile: true },
    );
    expect(phone.find(".tours-table__fleet").text()).toBe("Blue Sun");
    expect(phone.text().match(/Blue Sun/g)).toHaveLength(1);
  });

  it("hands the clicked tour to its parent", async () => {
    const wrapper = await mount({ tours: [tour()] });

    await wrapper.find(".base-table-row.clickable").trigger("click");

    expect(wrapper.emitted("row-click")?.[0]).toEqual([
      expect.objectContaining({ slug: "abc-jumptown-run" }),
    ]);
  });

  it("says there is nothing yet when the list is empty", async () => {
    const wrapper = await mount({ tours: [] });

    expect(wrapper.text()).toContain("No tours yet");
  });

  // Neither page puts this table inside a FilteredList, so BaseTable has no
  // list geometry to take a row count from and reserved none of its own -
  // which left both pages spinning over an empty frame.
  it("holds the table open with placeholder rows while it loads", async () => {
    const wrapper = await mount({ tours: [], loading: true });

    expect(
      wrapper.findAll("[data-test='base-table-skeleton-row']").length,
    ).toBeGreaterThan(0);
    expect(wrapper.text()).not.toContain("No tours yet");
  });
});
