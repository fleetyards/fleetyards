import { type Fleet } from "@/services/fyApi";
import { shortUrl } from "@/frontend/utils/shortUrl";

export const fleetShipsShareUrl = (
  fleet: Pick<Fleet, "fid" | "slug">,
  { fleetchart = false } = {},
) =>
  shortUrl(
    `/f/${encodeURIComponent(fleet.fid)}/ships`,
    fleetchart ? "?fleetchart=true" : "",
  ) ??
  `${window.location.origin}/fleets/${fleet.slug}/${fleetchart ? "fleetchart" : "ships"}`;
