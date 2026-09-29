import { useQueryClient } from "@tanstack/vue-query";
import type { RouteLocationNormalizedLoaded, Router } from "vue-router";
import { type Fleet, getMyFleetsQueryKey, myFleets } from "@/services/fyApi";

type MovedFleetNotification = {
  notificationType?: string;
  link?: string;
};

const FLEET_LINK = /^\/fleets\/([^/]+)\//;

// A completed FID claim moves two fleets to new addresses, and the notification
// links to the reader's fleet at its new one. A page still open on the old one
// would keep reading - and linking to - an address that now belongs to the
// other fleet.
//
// The old address is not in the notification, and the claimant may have
// started from any FID, so the move is read off the reader's own fleets: the
// open address was one of theirs before and is not any more, and the new one
// is. A page showing somebody else's fleet is never moved.
export const movedFleetSlug = (
  notification: MovedFleetNotification,
  currentSlug: unknown,
  slugsBefore: string[],
  slugsAfter: string[],
) => {
  if (notification.notificationType !== "fleet_fid_claim_completed") return;
  if (typeof currentSlug !== "string") return;

  const newSlug = notification.link?.match(FLEET_LINK)?.[1];
  if (!newSlug || newSlug === currentSlug) return;

  const moved =
    slugsBefore.includes(currentSlug) &&
    !slugsAfter.includes(currentSlug) &&
    slugsAfter.includes(newSlug);

  return moved ? newSlug : undefined;
};

const slugsOf = (fleets?: Fleet[]) => (fleets ?? []).map((fleet) => fleet.slug);

export const useMovedFleetRedirect = (
  router: Router,
  route: RouteLocationNormalizedLoaded,
) => {
  const queryClient = useQueryClient();

  return async (notification: MovedFleetNotification) => {
    if (notification.notificationType !== "fleet_fid_claim_completed") return;

    const slugsBefore = slugsOf(
      queryClient.getQueryData<Fleet[]>(getMyFleetsQueryKey()),
    );

    const fleetsAfter = await queryClient
      .fetchQuery({
        queryKey: getMyFleetsQueryKey(),
        queryFn: () => myFleets(),
        staleTime: 0,
      })
      .catch(() => undefined);

    const newSlug = movedFleetSlug(
      notification,
      route.params.slug,
      slugsBefore,
      slugsOf(fleetsAfter),
    );

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
