import { type Fleet } from "@/services/fyApi";
import { shortUrl } from "@/frontend/utils/shortUrl";

export const fleetShipsShareUrl = (fleet: Pick<Fleet, "fid" | "slug">) =>
  shortUrl(`/f/${encodeURIComponent(fleet.fid)}/ships`) ??
  `${window.location.origin}/fleets/${fleet.slug}/ships`;
