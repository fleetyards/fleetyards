// A vehicle's address inside its owner's hangar. It always carries something
// unique -- the game serial or the id -- so the name can ride along for
// readability without two ships of the same name colliding, and a rename
// leaves old links resolvable.
//
//   serial + name  l8-4261-ha-uscs-tanngnjostr
//   name only      <uuid>-uscs-tanngnjostr
//   serial only    l8-4261-ha-<uuid>
//   neither        <uuid>

type SegmentVehicle = {
  id: string;
  name?: string | null;
  serial?: string | null;
};

// Mirrors `Vehicle::SERIAL_FORMAT`. Serials from before the format stay on the
// record but are left out of the address: free text cannot be told apart from
// the name that follows it.
const SERIAL_FORMAT = /^[A-Z0-9]{2}-[A-Z0-9]{4}-[A-Z0-9]{2}$/i;

const LEADING_SERIAL = /^([0-9a-z]{2}-[0-9a-z]{4}-[0-9a-z]{2})(?:-|$)/i;

const LEADING_UUID =
  /^([0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12})(?:-|$)/i;

// For the route record. vue-router rejects groups inside a param's pattern, so
// the tail is left loose; the page canonicalises whatever follows the serial or
// the id.
export const VEHICLE_SEGMENT_PATTERN =
  "[0-9a-z]{2}-[0-9a-z]{4}-[0-9a-z]{2}[^/]*|[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}[^/]*";

// Mirrors `Vehicle.game_serial`: a serial typed without its dashes still counts.
export function gameSerial(serial?: string | null): string | undefined {
  const value = (serial ?? "").trim().toUpperCase();
  const compact = value.replace(/[- ]/g, "");
  const normalized = /^[A-Z0-9]{8}$/.test(compact)
    ? `${compact.slice(0, 2)}-${compact.slice(2, 6)}-${compact.slice(6)}`
    : value;

  return SERIAL_FORMAT.test(normalized) ? normalized : undefined;
}

function parameterize(name?: string | null): string {
  return (name ?? "")
    .normalize("NFKD")
    .replace(/[̀-ͯ]/g, "")
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-+|-+$/g, "");
}

export function vehicleSegment(vehicle: SegmentVehicle): string {
  const serial = gameSerial(vehicle.serial)?.toLowerCase();
  const name = parameterize(vehicle.name);

  if (serial) {
    return name ? `${serial}-${name}` : `${serial}-${vehicle.id}`;
  }

  return name ? `${vehicle.id}-${name}` : vehicle.id;
}

// What the API looks the vehicle up by: the serial when the segment leads with
// one, otherwise the id. The name is never read back.
export function vehicleIdentifierFromSegment(
  segment: string,
): string | undefined {
  const serial = segment.match(LEADING_SERIAL)?.[1];
  if (serial) return serial.toUpperCase();

  return segment.match(LEADING_UUID)?.[1]?.toLowerCase();
}

export type VehicleRouteName =
  | "hangar-vehicle"
  | "hangar-vehicle-overview"
  | "hangar-vehicle-log"
  | "hangar-vehicle-loadouts"
  | "hangar-vehicle-cargo"
  | "hangar-vehicle-cargo-item";

export function vehicleRoute(
  name: VehicleRouteName,
  vehicle: SegmentVehicle,
  username: string,
  params: Record<string, string> = {},
) {
  return {
    name,
    params: { ...params, username, segment: vehicleSegment(vehicle) },
  };
}
