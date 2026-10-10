import { type MaybeRefOrGetter } from "vue";
import { liveQuery } from "@/frontend/components/Fleets/Dashboard/liveQuery";
import {
  FleetActivityCategoryEnum,
  useFleetActivity,
  type FleetActivity,
} from "@/services/fyApi";

const occurredAt = (entry: FleetActivity) =>
  new Date(entry.occurredAt).getTime();

// Each category's page: enough for the inventory panel's mine/fleet split and
// a page of the feed. Every category counts towards it on its own, so the
// answer can be several times this.
const LIMIT = 20;
const MAX_LIMIT = 50;
const FEED_PAGE = 15;
const NEW_MEMBERS = 6;

/**
 * The dashboard's one activity request, split into the panels that read it.
 * Limited per category rather than overall, so a busy week of events cannot
 * push the inventory or the newcomers off the page.
 */
export const useDashboardActivity = (
  fleetSlug: MaybeRefOrGetter<string>,
  // What another panel already tells, so the feed does not say it twice.
  excludedFromFeed: MaybeRefOrGetter<FleetActivityCategoryEnum[]>,
) => {
  const limit = ref(LIMIT);

  const feedShown = ref(FEED_PAGE);

  const { data, isLoading } = useFleetActivity(
    computed(() => toValue(fleetSlug)),
    computed(() => ({ limit: limit.value, perCategory: true })),
    { query: { ...liveQuery, placeholderData: (previous) => previous } },
  );

  const items = computed(() => data.value?.items);

  const inCategory = (category: FleetActivityCategoryEnum) =>
    items.value?.filter((entry) => entry.category === category);

  const inventory = computed(() =>
    inCategory(FleetActivityCategoryEnum.INVENTORY),
  );

  const newMembers = computed(() =>
    inCategory(FleetActivityCategoryEnum.MEMBERS)?.slice(0, NEW_MEMBERS),
  );

  const feedAll = computed(() =>
    (items.value ?? []).filter(
      (entry) => !toValue(excludedFromFeed).includes(entry.category),
    ),
  );

  // A category that came back full may have more past its oldest entry, which
  // the answer does not hold. Past the newest such edge the merged feed would
  // skip that category's entries and show the others' older ones in their
  // place, so the feed stops there.
  const horizon = computed(() => {
    const byCategory = new Map<string, FleetActivity[]>();
    feedAll.value.forEach((entry) =>
      byCategory.set(entry.category, [
        ...(byCategory.get(entry.category) ?? []),
        entry,
      ]),
    );

    const edges = [...byCategory.values()]
      .filter((entries) => entries.length >= limit.value)
      .map((entries) => Math.min(...entries.map(occurredAt)));

    return edges.length ? Math.max(...edges) : undefined;
  });

  const complete = computed(() => {
    const edge = horizon.value;

    return edge === undefined
      ? feedAll.value
      : feedAll.value.filter((entry) => occurredAt(entry) >= edge);
  });

  const feed = computed(() => complete.value.slice(0, feedShown.value));

  // More is there when the complete part holds more than is shown, or when it
  // was cut short by a full category and the limit can still grow.
  const hasMore = computed(
    () =>
      complete.value.length > feedShown.value ||
      (horizon.value !== undefined && limit.value < MAX_LIMIT),
  );

  const showMore = () => {
    feedShown.value += FEED_PAGE;
    if (feedShown.value > complete.value.length) limit.value = MAX_LIMIT;
  };

  return {
    loading: isLoading,
    feed,
    hasMore,
    showMore,
    inventory,
    newMembers,
  };
};
