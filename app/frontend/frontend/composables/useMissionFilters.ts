import { type GameMissionQuery } from "@/services/fyApi";
import { useFilters } from "@/shared/composables/useFilters";

// The scalar spellings the API also accepts. `FilterForm` reads each as a
// fallback for its list form, so a URL carrying one prefills the select -- but
// `useFilters` builds its query from `route.query` first, so the scalar would
// then survive beside the list the form writes. Ransack ANDs the two, and
// `orgNameEq=Foxwell` beside `orgNameIn=[Headhunters]` is a guaranteed empty
// list.
const SUPERSEDED_PARAMS = {
  orgNameIn: "orgNameEq",
  minStandingIn: "minStandingEq",
  kindIn: "kindEq",
  locationKindIn: "locationKindEq",
  rewardingIn: "rewarding",
} as const;

export const useMissionFilters = (
  updateCallback?: (() => void) | (() => Promise<void>),
) => {
  // `ship` marks the list rather than narrowing it, so it lives in the URL and
  // never reaches the API, which would reject it as an unknown filter.
  const filters = useFilters<GameMissionQuery>({
    updateCallback,
    viewKeys: ["ship"],
  });

  const getQuery = () => {
    const query = { ...filters.getQuery() } as Record<string, unknown>;

    Object.entries(SUPERSEDED_PARAMS).forEach(([list, scalar]) => {
      if (query[list] === undefined || query[list] === null) return;

      delete query[scalar];
    });

    return query as GameMissionQuery;
  };

  return { ...filters, getQuery };
};
