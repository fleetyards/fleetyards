import { type MaybeRefOrGetter } from "vue";
import { liveQuery } from "@/frontend/components/Fleets/Dashboard/liveQuery";
import { FleetActivityCategoryEnum, useFleetActivity } from "@/services/fyApi";

// Each category's page: enough for the inventory panel's mine/fleet split,
// and two pages of the feed before it has to ask for more.
const LIMIT = 30;
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

  const feed = computed(() => feedAll.value.slice(0, feedShown.value));

  // More is there when the answer holds more than is shown, or when a
  // category came back full and the limit can still grow.
  const hasMore = computed(() => {
    if (feedAll.value.length > feedShown.value) return true;
    if (limit.value >= MAX_LIMIT) return false;

    const counts = new Map<string, number>();
    feedAll.value.forEach(({ category }) =>
      counts.set(category, (counts.get(category) ?? 0) + 1),
    );

    return [...counts.values()].some((count) => count >= limit.value);
  });

  const showMore = () => {
    feedShown.value += FEED_PAGE;
    if (feedShown.value > feedAll.value.length) limit.value = MAX_LIMIT;
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
