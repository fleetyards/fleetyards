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

const SERIAL_SOURCE = "[0-9a-z]{2}-[0-9a-z]{4}-[0-9a-z]{2}";

const UUID_SOURCE =
  "[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}";

// Mirrors `Vehicle::SERIAL_FORMAT`.
const SERIAL_FORMAT = new RegExp(`^${SERIAL_SOURCE}$`, "i");

const LEADING_SERIAL = new RegExp(`^(${SERIAL_SOURCE})(?:-|$)`, "i");

const LEADING_UUID = new RegExp(`^(${UUID_SOURCE})(?:-|$)`, "i");

// For the route record. vue-router rejects groups inside a param's pattern, so
// the tail is left loose; the page canonicalises whatever follows the serial or
// the id.
export const VEHICLE_SEGMENT_PATTERN = `${SERIAL_SOURCE}[^/]*|${UUID_SOURCE}[^/]*`;

// The serial as the record holds it, when that is already in the game format.
// The address has to read back to the stored value exactly: a serial saved
// before the format -- free text, or `L84261HA` without its dashes -- would
// look up as something the record does not hold, so it is left out.
function addressSerial(serial?: string | null): string | undefined {
  return serial && SERIAL_FORMAT.test(serial) ? serial : undefined;
}

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
    .replace(/[\u0300-\u036f]/g, "")
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-+|-+$/g, "");
}

export function vehicleSegment(vehicle: SegmentVehicle): string {
  const serial = addressSerial(vehicle.serial)?.toLowerCase();
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
