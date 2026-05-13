import type { FleetEventShip } from "@/services/fyApi";

// Vehicle model shape varies between API endpoints: the hangar response
// nests size/cargo/crew under metrics/crew sub-objects, while the signup
// vehicle (compact form) inlines them flat. The helper accepts both.
type VehicleModel = {
  id?: string;
  classification?: string | null;
  focus?: string | null;
  size?: string | null;
  minCrew?: number | null;
  maxCrew?: number | null;
  cargo?: number | null;
  metrics?: { size?: string | null; cargo?: number | null } | null;
  crew?: { min?: number | null; max?: number | null } | null;
};

type VehicleLike = {
  model?: VehicleModel | null;
};

const sizeOf = (m: VehicleModel) => m.metrics?.size ?? m.size ?? undefined;
const cargoOf = (m: VehicleModel) => m.metrics?.cargo ?? m.cargo ?? null;
const minCrewOf = (m: VehicleModel) => m.crew?.min ?? m.minCrew ?? null;
const maxCrewOf = (m: VehicleModel) => m.crew?.max ?? m.maxCrew ?? null;

const SIZE_ORDER = [
  "snub",
  "small",
  "medium",
  "large",
  "extra_large",
  "capital",
];

const sizeAtLeast = (size: string | null | undefined, min: string) =>
  !!size && SIZE_ORDER.indexOf(size) >= SIZE_ORDER.indexOf(min);

const sizeAtMost = (size: string | null | undefined, max: string) =>
  !!size && SIZE_ORDER.indexOf(size) <= SIZE_ORDER.indexOf(max);

export const vehicleMatchesShip = (
  vehicle: VehicleLike | null | undefined,
  ship: FleetEventShip | null | undefined,
): boolean => {
  if (!ship) return true;
  const m = vehicle?.model;
  if (!m) return false;

  if (ship.model?.id) {
    return m.id === ship.model.id;
  }

  const f = ship.filters;
  if (!f) return true;

  if (f.classification && m.classification !== f.classification) return false;
  if (f.focus && m.focus !== f.focus) return false;

  const size = sizeOf(m);
  if (f.minSize && !sizeAtLeast(size, f.minSize)) return false;
  if (f.maxSize && !sizeAtMost(size, f.maxSize)) return false;

  if (f.minCrew != null) {
    const crewCap = maxCrewOf(m) ?? minCrewOf(m) ?? 0;
    if (crewCap < f.minCrew) return false;
  }
  if (f.minCargo != null) {
    const cargo = Number(cargoOf(m) ?? 0);
    if (cargo < f.minCargo) return false;
  }

  return true;
};
