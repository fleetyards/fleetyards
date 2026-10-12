import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { beforeEach, describe, expect, it, vi } from "vitest";
import Component from "./index.vue";
import { type Vehicle } from "@/services/fyApi";

const emit = vi.fn();

vi.mock("@/shared/composables/useComlink", () => ({
  useComlink: () => ({ emit, on: () => () => undefined }),
}));

const openedModal = () =>
  emit.mock.calls.find(([event]) => event === "open-modal")?.[1];

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
  beforeEach(() => {
    emit.mockClear();
  });

  it("offers a non-supporter the supporter modal instead of the editor", async () => {
    const wrapper = await mountWithDefaults<typeof Component>(Component, {
      props: { vehicle: vehicle() },
      initialState: { session: { currentUser: { supporter: false } } },
    });

    await wrapper.find('[data-test="vehicle-plaque-edit"]').trigger("click");

    expect(openedModal()?.props).toBeUndefined();
    expect(String(openedModal()?.component)).toContain("PlaqueSupporterModal");
  });

  it("opens the editor for a supporter", async () => {
    const wrapper = await mountWithDefaults<typeof Component>(Component, {
      props: { vehicle: vehicle() },
      initialState: { session: { currentUser: { supporter: true } } },
    });

    await wrapper.find('[data-test="vehicle-plaque-edit"]').trigger("click");

    expect(openedModal()?.props).toEqual({ vehicle: vehicle() });
    expect(String(openedModal()?.component)).toContain("PlaqueEditModal");
  });

  it("invites a dedication while there is none", async () => {
    const wrapper = await mountWithDefaults<typeof Component>(Component, {
      props: { vehicle: vehicle() },
    });

    expect(wrapper.find('[data-test="vehicle-plaque-empty"]').exists()).toBe(
      true,
    );
    expect(wrapper.find('[data-test="vehicle-plaque"]').exists()).toBe(false);
    expect(wrapper.find('[data-test="vehicle-plaque-download"]').exists()).toBe(
      false,
    );
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
    expect(wrapper.find('[data-test="vehicle-plaque-download"]').exists()).toBe(
      true,
    );
  });
});
