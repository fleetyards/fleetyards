import { beforeEach, describe, expect, it, vi } from "vitest";
import { mountWithDefaults } from "@/shared/utils/TestUtils";
import type { Vehicle } from "@/services/fyApi";
import Component from "./index.vue";

const openEditModal = vi.fn();

vi.mock("@/frontend/composables/useVehicleModals", () => ({
  useVehicleModals: () => ({ openEditModal }),
}));

beforeEach(() => openEditModal.mockClear());

describe("VehicleOverviewVisibilityCard", () => {
  it("summarizes saved visibility and opens its editor tab", async () => {
    const vehicle = {
      id: "vehicle-1",
      public: true,
      nameVisible: false,
      wanted: false,
    } as Vehicle;
    const wrapper = await mountWithDefaults(Component, { props: { vehicle } });

    expect(wrapper.find('[data-test="vehicle-setting-public"]').text()).toBe(
      "Enabled",
    );
    expect(
      wrapper.find('[data-test="vehicle-setting-nameVisible"]').text(),
    ).toBe("Disabled");
    expect(wrapper.find('input[type="checkbox"]').exists()).toBe(false);
    await wrapper
      .find('[data-test="vehicle-visibility-edit"]')
      .trigger("click");

    expect(openEditModal).toHaveBeenCalledWith(vehicle, { tab: "visibility" });
  });

  it("shows the wishlist's sale alerts instead of public hangar settings", async () => {
    const wrapper = await mountWithDefaults(Component, {
      props: { vehicle: { wanted: true, saleNotify: true } as Vehicle },
    });

    expect(
      wrapper.find('[data-test="vehicle-setting-saleNotify"]').text(),
    ).toBe("Enabled");
    expect(wrapper.find('[data-test="vehicle-setting-public"]').exists()).toBe(
      false,
    );
  });
});
