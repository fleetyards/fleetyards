import { type GameMissionQuery } from "@/services/fyApi";
import { useFilters } from "@/shared/composables/useFilters";

// The query params the API takes as arrays. `route.query` gives back a bare
// string when only one is set -- vue-router does no normalising -- and the
// schema rejects a string where it declared an array, so a lone org arrives as
// a 400 rather than as a filter.
const LIST_PARAMS = [
  "alignmentIn",
  "kindIn",
  "minStandingIn",
  "orgNameIn",
  "rewardingIn",
] as const;

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
  rewardingIn: "rewarding",
} as const;

export const useMissionFilters = (
  updateCallback?: (() => void) | (() => Promise<void>),
) => {
  const filters = useFilters<GameMissionQuery>({ updateCallback });

  const getQuery = () => {
    const query = { ...filters.getQuery() } as Record<string, unknown>;

    LIST_PARAMS.forEach((key) => {
      const value = query[key];
      if (value === undefined || value === null || Array.isArray(value)) return;

      query[key] = [value];
    });

    Object.entries(SUPERSEDED_PARAMS).forEach(([list, scalar]) => {
      if (query[list] === undefined || query[list] === null) return;

      delete query[scalar];
    });

    return query as GameMissionQuery;
  };

  return { ...filters, getQuery };
};
