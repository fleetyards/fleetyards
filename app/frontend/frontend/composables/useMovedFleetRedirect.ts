import { useQueryClient } from "@tanstack/vue-query";
import type { RouteLocationNormalizedLoaded, Router } from "vue-router";

type MovedFleetNotification = {
  notificationType?: string;
  link?: string;
};

const FLEET_LINK = /^\/fleets\/([^/]+)\//;

// A completed FID claim moves two fleets: the holder to `X-N` and the claimant
// to `X`. The notification links to the reader's fleet at its new address, and
// an open page on the old one would otherwise keep reading - and linking to -
// an address that now belongs to the other fleet.
//
// The old address is not in the notification, so it is recognised by the
// shape of the move: `x` became `x-n`, or `x-n` became `x`.
export const movedFleetSlug = (
  notification: MovedFleetNotification,
  currentSlug: unknown,
) => {
  if (notification.notificationType !== "fleet_fid_claim_completed") return;
  if (typeof currentSlug !== "string") return;

  const newSlug = notification.link?.match(FLEET_LINK)?.[1];
  if (!newSlug || newSlug === currentSlug) return;

  const moved =
    newSlug.startsWith(`${currentSlug}-`) ||
    currentSlug.startsWith(`${newSlug}-`);

  return moved ? newSlug : undefined;
};

export const useMovedFleetRedirect = (
  router: Router,
  route: RouteLocationNormalizedLoaded,
) => {
  const queryClient = useQueryClient();

  return async (notification: MovedFleetNotification) => {
    if (notification.notificationType !== "fleet_fid_claim_completed") return;

    const newSlug = movedFleetSlug(notification, route.params.slug);

    if (newSlug && route.name) {
      await router
        .replace({
          name: route.name,
          params: { ...route.params, slug: newSlug },
          query: route.query,
        })
        .catch(() => {});
    }

    // After the move, so a query still mounted on the old address is not
    // refetched into the other fleet's payload.
    void queryClient.invalidateQueries({ queryKey: ["fleets"] });
  };
};
