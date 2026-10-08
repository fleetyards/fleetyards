import { type Fleet } from "@/services/fyApi";
import { shortUrl } from "@/frontend/utils/shortUrl";

export const fleetShipsShortPath = (fleet: Pick<Fleet, "fid">) =>
  `/f/${encodeURIComponent(fleet.fid)}/ships`;

export const fleetShipsShareUrl = (fleet: Pick<Fleet, "fid" | "slug">) =>
  shortUrl(fleetShipsShortPath(fleet)) ??
  `${window.location.origin}/fleets/${fleet.slug}/ships`;
