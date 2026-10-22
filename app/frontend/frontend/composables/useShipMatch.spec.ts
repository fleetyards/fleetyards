import { describe, expect, it } from "vitest";
import type { FleetEventShip } from "@/services/fyApi";
import { vehicleMatchesShip } from "./useShipMatch";

const slot = (foci: string[]) =>
  ({ id: "slot", filters: { foci } }) as unknown as FleetEventShip;

const vehicle = (foci: string[]) => ({ model: { id: "model", foci } });

describe("vehicleMatchesShip", () => {
  it("takes a ship that has any of the slot's foci among its own", () => {
    expect(
      vehicleMatchesShip(
        vehicle(["heavy_fighter", "fighter", "bomber"]),
        slot(["bomber"]),
      ),
    ).toBe(true);
  });

  it("turns away a ship with none of them", () => {
    expect(vehicleMatchesShip(vehicle(["freight"]), slot(["fighter"]))).toBe(
      false,
    );
  });

  it("asks nothing of the foci when the slot names none", () => {
    expect(vehicleMatchesShip(vehicle([]), slot([]))).toBe(true);
  });
});
