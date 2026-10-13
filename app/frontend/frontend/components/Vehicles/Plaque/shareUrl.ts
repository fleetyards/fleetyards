import { vehicleSegment } from "@/frontend/utils/vehicleSegment";

type PlaqueVehicle = {
  id: string;
  name?: string | null;
  serial?: string | null;
};

// A shared plaque is the public hangar with the plaque open; the server reads
// the same `plaque` parameter to give the link the plaque as its preview. It
// names the ship by the address its pages use -- so pass only the name and
// serial the public may see, and the address falls back to the id.
export const plaqueShareUrl = (
  username: string,
  vehicle: PlaqueVehicle,
  share?: string,
) => {
  const url = new URL(
    `/hangar/${encodeURIComponent(username)}/`,
    window.location.origin,
  );
  url.searchParams.set("plaque", vehicleSegment(vehicle));
  if (share) {
    url.searchParams.set("share", share);
  }

  return url.toString();
};
