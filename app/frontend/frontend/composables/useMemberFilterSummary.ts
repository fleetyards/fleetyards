import { computed, toValue, type MaybeRefOrGetter } from "vue";
import type { LocationQuery } from "vue-router";
import type { ActiveFilter } from "@/shared/components/ActiveFilters/types";
import { useI18n } from "@/shared/composables/useI18n";
import {
  summarizeShipFilters,
  withoutFilters,
} from "@/frontend/composables/useShipFilterSummary";
import { useFleetRoles } from "@/services/fyApi";

// Each has a control of its own on the page -- the search in the header, the
// squadrons in the toolbar -- so a chip would only say it twice.
const SHOWN_ELSEWHERE = ["searchCont", "squadronSlugIn"];

// A box that is ticked or not: its label is the whole of what it filters by.
const TOGGLES = ["withoutRsiHandle", "withoutDiscord", "withoutSquadron"];

const LABELS: Record<string, string> = {
  roleIn: "labels.filters.fleets.members.role",
  stateIn: "labels.filters.fleets.members.state",
  acceptedAt: "labels.fleet.members.joined",
  invitedAt: "labels.fleet.members.invited",
  requestedAt: "labels.fleet.members.requested",
  declinedAt: "labels.fleet.members.declined",
  squadronMembershipCreatedAt: "labels.fleet.squadrons.joinedAt",
  inactiveSince: "labels.filters.fleets.members.inactiveSince",
  verifiedEq: "labels.filters.fleets.members.verified",
  withoutRsiHandle: "labels.filters.fleets.members.withoutRsiHandle",
  withoutDiscord: "labels.filters.fleets.members.withoutDiscord",
  withoutSquadron: "labels.filters.fleets.members.withoutSquadron",
};

/*
 * The roster's filters as chips. Most of them live in the sidebar, which is
 * collapsed by default, and a link can set any of them -- the health page's
 * lists do -- so without the chips a narrowed roster looks like a whole one.
 *
 * `applied` is the query the list is actually asked: the open view leaves the
 * other view's filters out, and so do its chips.
 */
export const useMemberFilterSummary = (
  fleetSlug: MaybeRefOrGetter<string>,
  applied: MaybeRefOrGetter<LocationQuery>,
) => {
  const route = useRoute();
  const router = useRouter();
  const { t } = useI18n();

  const { data: fleetRoles } = useFleetRoles(
    computed(() => toValue(fleetSlug)),
  );

  const valueLabels = computed<Record<string, Record<string, string>>>(() => ({
    roleIn: Object.fromEntries(
      (fleetRoles.value ?? []).map((role) => [role.slug, role.name]),
    ),
    stateIn: {
      invited: t("labels.fleet.members.invited"),
      requested: t("labels.fleet.members.requested"),
      declined: t("labels.fleet.members.declined"),
    },
    verifiedEq: {
      true: t("labels.filters.fleets.members.verifiedYes"),
      false: t("labels.filters.fleets.members.verifiedNo"),
    },
  }));

  // A key the form has no field for can still arrive with a link.
  const label = (key: string) =>
    LABELS[key]
      ? t(LABELS[key])
      : key
          .replace(/(?:In|Eq|Cont)$/, "")
          .replace(/([A-Z])/g, " $1")
          .replace(/^./, (char) => char.toUpperCase());

  const formatValue = (value: string, key: string) => {
    const known = valueLabels.value[key]?.[value];
    if (known) return known;
    if (value === "true" || value === "false") return t(`labels.${value}`);
    return value;
  };

  const activeFilters = computed<ActiveFilter[]>(() => {
    const query = { ...toValue(applied) };

    SHOWN_ELSEWHERE.forEach((key) => delete query[key]);

    return summarizeShipFilters(query, label, formatValue).map((item) => ({
      id: item.id,
      label:
        TOGGLES.includes(item.id) && String(query[item.id]) === "true"
          ? label(item.id)
          : item.label,
      remove: async () => {
        await router.push({
          path: route.path,
          query: withoutFilters(route.query, item.keys),
          hash: route.hash,
        });
      },
    }));
  });

  return { activeFilters };
};
