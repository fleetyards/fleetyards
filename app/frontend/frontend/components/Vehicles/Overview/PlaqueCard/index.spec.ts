import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { describe, expect, it } from "vitest";
import Component from "./index.vue";
import { type Vehicle } from "@/services/fyApi";

const NOW = "2026-10-12T12:00:00Z";

const vehicle = (overrides: Partial<Vehicle> = {}): Vehicle =>
  ({
    id: "vehicle-1",
    alternativeNames: [],
    hangarGroupIds: [],
    hangarGroups: [],
    modelModuleIds: [],
    modelUpgradeIds: [],
    model: {
      id: "model-1",
      name: "Carrack",
      slug: "carrack",
      media: {},
      manufacturer: {
        name: "Anvil",
        slug: "anvil",
        createdAt: NOW,
        updatedAt: NOW,
      },
    },
    createdAt: NOW,
    updatedAt: NOW,
    ...overrides,
  }) as Vehicle;

describe("VehicleOverviewPlaqueCard", () => {
  it("invites a dedication while there is none", async () => {
    const wrapper = await mountWithDefaults<typeof Component>(Component, {
      props: { vehicle: vehicle() },
    });

    expect(wrapper.find('[data-test="vehicle-plaque-empty"]').exists()).toBe(
      true,
    );
    expect(wrapper.find('[data-test="vehicle-plaque"]').exists()).toBe(false);
    expect(wrapper.find('[data-test="vehicle-plaque-edit"]').exists()).toBe(
      true,
    );
  });

  it("shows the plaque once the ship is dedicated", async () => {
    const wrapper = await mountWithDefaults<typeof Component>(Component, {
      props: { vehicle: vehicle({ dedication: "To boldly go" }) },
    });

    expect(wrapper.find('[data-test="vehicle-plaque"]').exists()).toBe(true);
    expect(wrapper.find('[data-test="vehicle-plaque-empty"]').exists()).toBe(
      false,
    );
  });
});
