import { computed, toValue, type MaybeRefOrGetter } from "vue";
import type { LocationQuery, LocationQueryRaw } from "vue-router";
import type { ActiveFilter } from "@/shared/components/ActiveFilters/types";
import { useI18n } from "@/shared/composables/useI18n";
import { summarizeShipFilters } from "@/frontend/composables/useShipFilterSummary";
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
  inactiveSince: "labels.filters.fleets.members.inactiveSince",
  verifiedEq: "labels.filters.fleets.members.verified",
  withoutRsiHandle: "labels.filters.fleets.members.withoutRsiHandle",
  withoutDiscord: "labels.filters.fleets.members.withoutDiscord",
  withoutSquadron: "labels.filters.fleets.members.withoutSquadron",
};

/*
 * The roster's filters as chips. Most of them live in the sidebar, which is
 * collapsed by default, so a filter that arrived with a link -- the health
 * page's "unverified" list, say -- otherwise narrowed the roster with nothing
 * on screen to say so, and picking a squadron afterwards read as members
 * missing from it.
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

  const label = (key: string) => (LABELS[key] ? t(LABELS[key]) : key);

  const formatValue = (value: string, key: string) =>
    valueLabels.value[key]?.[value] ?? value;

  const activeFilters = computed<ActiveFilter[]>(() => {
    const query = { ...toValue(applied) };

    SHOWN_ELSEWHERE.forEach((key) => delete query[key]);

    return summarizeShipFilters(query, label, formatValue).map((item) => ({
      id: item.id,
      label: TOGGLES.includes(item.id) ? label(item.id) : item.label,
      remove: async () => {
        const next: LocationQueryRaw = { ...route.query };

        item.keys.forEach((key) => delete next[key]);
        delete next.page;

        await router.push({ path: route.path, query: next, hash: route.hash });
      },
    }));
  });

  return { activeFilters };
};
