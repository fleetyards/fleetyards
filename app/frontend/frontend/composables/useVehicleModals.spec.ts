import { beforeEach, describe, expect, it, vi } from "vitest";
import type { Vehicle } from "@/services/fyApi";
import { VehicleEditTabsEnum } from "@/frontend/components/Vehicles/EditModal/types";
import { VehicleLoadoutTabsEnum } from "@/frontend/components/Vehicles/LoadoutModal/types";
import { useVehicleModals } from "./useVehicleModals";

const emit = vi.fn();

vi.mock("@/shared/composables/useComlink", () => ({
  useComlink: () => ({ emit }),
}));

const vehicle = { id: "vehicle-1", wanted: true } as Vehicle;

beforeEach(() => emit.mockClear());

describe("useVehicleModals", () => {
  it("preserves wishlist behavior when opening a specific editing tab", () => {
    useVehicleModals().openEditModal(vehicle, {
      tab: VehicleEditTabsEnum.IMAGE,
    });

    expect(emit).toHaveBeenCalledWith(
      "open-modal",
      expect.objectContaining({
        component: expect.any(Function),
        props: { vehicle, wishlist: true, tab: "image" },
      }),
    );
  });

  it("allows the caller to override the wishlist context", () => {
    useVehicleModals().openEditModal(vehicle, { wishlist: false });

    expect(emit).toHaveBeenCalledWith(
      "open-modal",
      expect.objectContaining({
        props: { vehicle, wishlist: false, tab: undefined },
      }),
    );
  });

  it("opens the requested loadout category with explicit editing access", () => {
    useVehicleModals().openLoadoutModal(vehicle, {
      tab: VehicleLoadoutTabsEnum.PAINTS,
      editable: true,
    });

    expect(emit).toHaveBeenCalledWith(
      "open-modal",
      expect.objectContaining({
        wide: true,
        props: { vehicle, tab: "paints", editable: true },
      }),
    );
  });

  it("opens a read-only loadout unless editing access was supplied", () => {
    useVehicleModals().openLoadoutModal(vehicle);

    expect(emit).toHaveBeenCalledWith(
      "open-modal",
      expect.objectContaining({
        props: { vehicle, tab: undefined, editable: false },
      }),
    );
  });
});
