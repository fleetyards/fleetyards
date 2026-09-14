import type { FleetMemberQuery } from "@/services/fyApi";
import type { LocationQuery } from "vue-router";

export const MEMBERS_VIEWS = ["members", "invites"] as const;

export type MembersView = (typeof MEMBERS_VIEWS)[number];

/*
 * What each list alone asks about. The other one offers no field for these and
 * holds no rows that could match them -- an invite has no accepted date, an
 * accepted member has no state left to choose -- so they have to be left behind
 * when the view changes. Carried over, they narrow the list from a filter its
 * form never renders and therefore cannot clear.
 *
 * The filter form reads the same map, so the two cannot drift.
 */
export const MEMBERS_VIEW_FILTER_KEYS: Record<
  MembersView,
  (keyof FleetMemberQuery)[]
> = {
  members: ["acceptedAtGteq", "acceptedAtLteq"],
  invites: [
    "stateIn",
    "invitedAtGteq",
    "invitedAtLteq",
    "requestedAtGteq",
    "requestedAtLteq",
    "declinedAtGteq",
    "declinedAtLteq",
  ],
};

const theOtherView = (view: MembersView): MembersView =>
  view === "invites" ? "members" : "invites";

/*
 * Which view of a fleet's membership is open -- the roster or the invites. The
 * two are one list asked two questions, so they are one page with the choice in
 * the query, for the same reason the ledger tab is: see `useLedgerTab`.
 */
export const useMembersView = (canReadInvites: MaybeRefOrGetter<boolean>) => {
  const route = useRoute();

  // A view somebody may not read falls back to the roster rather than to an
  // empty list or an error.
  const view = computed<MembersView>(() =>
    route.query.view === "invites" && toValue(canReadInvites)
      ? "invites"
      : "members",
  );

  const dropForeignFilters = <T extends object>(query: T, of: MembersView) => {
    const kept = { ...query } as Record<string, unknown>;

    MEMBERS_VIEW_FILTER_KEYS[theOtherView(of)].forEach((key) => {
      delete kept[key];
    });

    return kept as T;
  };

  // What the link to the other view carries: everything the two lists share --
  // the name searched for, the roles, the sort -- and nothing that was only
  // ever the departing list's business.
  const viewQuery = (value: MembersView) => {
    const query = dropForeignFilters(
      { ...route.query } as LocationQuery,
      value,
    );

    // The page number belongs to the list it was counted on.
    delete query.page;

    if (value === "invites") {
      query.view = "invites";
    } else {
      delete query.view;
    }

    return query;
  };

  // The same guard for a query nobody built here: an old link, or the 301 off
  // the invite list's former path, can still arrive carrying the roster's.
  const scopedFilters = <T extends object>(query: T) =>
    dropForeignFilters(query, view.value);

  return { view, views: MEMBERS_VIEWS, viewQuery, scopedFilters };
};
