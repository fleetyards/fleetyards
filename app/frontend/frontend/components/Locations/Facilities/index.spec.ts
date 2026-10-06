import { describe, expect, it } from "vitest";
import { mountWithDefaults } from "@/shared/utils/TestUtils";
import {
  type LocationFacilities,
  LocationFacilitySizeEnum,
} from "@/services/fyApi";
import Component from "./index.vue";

const hangar = (
  size: LocationFacilitySizeEnum,
  count: number,
  door = "front",
) => ({
  size,
  door,
  count,
  length: 128,
  beam: 72,
  height: 48,
});

const pad = (
  size: LocationFacilitySizeEnum,
  count: number,
  atcAssigned = false,
) => ({ size, count, atcAssigned, length: 88, beam: 58, height: 32 });

const facilities: LocationFacilities = {
  hangars: [
    hangar(LocationFacilitySizeEnum.MEDIUM, 4),
    hangar(LocationFacilitySizeEnum.LARGE, 6, "top"),
    hangar(LocationFacilitySizeEnum.LARGE, 4),
  ],
  landingPads: [pad(LocationFacilitySizeEnum.SMALL, 2)],
  vehiclePads: [],
  dockingTubes: 5,
};

describe("LocationFacilities", () => {
  it("sums hangars per size, largest first, under their total", async () => {
    const wrapper = await mountWithDefaults(Component, {
      props: { facilities },
    });

    const hangars = wrapper.find('[data-test="facilities-hangars"]');
    const rows = hangars
      .findAll(".metrics-card__row__value")
      .map((row) => row.text());

    expect(hangars.find(".location-facilities__total").text()).toBe("14");
    expect(rows).toEqual(["10", "4"]);
  });

  it("lists pads a pilot lands on without ATC as free, and the docking tubes", async () => {
    const wrapper = await mountWithDefaults(Component, {
      props: { facilities },
    });

    expect(
      wrapper.find('[data-test="facilities-free-landing-pads"]').exists(),
    ).toBe(true);
    expect(wrapper.find('[data-test="facilities-landing-pads"]').exists()).toBe(
      false,
    );
    expect(wrapper.find('[data-test="facilities-vehicle-pads"]').exists()).toBe(
      false,
    );
    expect(
      wrapper.find('[data-test="facilities-docking-tubes"]').text(),
    ).toContain("5");
  });
});
