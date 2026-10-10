import { type MaybeRefOrGetter } from "vue";
import { addDays, startOfWeek } from "date-fns";
import { liveQuery } from "@/frontend/components/Fleets/Dashboard/liveQuery";
import { useToday } from "@/frontend/components/Fleets/Dashboard/useToday";
import { useFleetCalendar } from "@/services/fyApi";

// How far the upcoming list looks ahead.
const UPCOMING_DAYS = 14;

type Week = { start: Date; end: Date };

const sameWeek = (a: Week, b: Week) =>
  a.start.getTime() === b.start.getTime() &&
  a.end.getTime() === b.end.getTime();

/**
 * The dashboard's calendar: one request for the upcoming list and this week
 * together, which is all a load or a refetch asks for. The calendar rather than
 * the event list, because it expands a recurring series into its dates.
 *
 * A week paged to is asked for on its own while it is on screen, so paging far
 * ahead fetches that week rather than every week in between.
 *
 * Each range reaches a day further back than it shows: the calendar answers by
 * start time, and an op that began the night before may still be running.
 */
export const useDashboardCalendar = (
  fleetSlug: MaybeRefOrGetter<string>,
  enabled: MaybeRefOrGetter<boolean>,
) => {
  const today = useToday();

  const thisWeek = computed<Week>(() => {
    const start = startOfWeek(today.value, { weekStartsOn: 1 });

    return { start, end: addDays(start, 7) };
  });

  const shownWeek = ref<Week | null>(null);

  const browsing = computed(
    () => !!shownWeek.value && !sameWeek(shownWeek.value, thisWeek.value),
  );

  const slug = computed(() => toValue(fleetSlug));

  const main = useFleetCalendar(
    slug,
    computed(() => {
      const upcomingEnd = addDays(today.value, UPCOMING_DAYS);
      const end =
        thisWeek.value.end > upcomingEnd ? thisWeek.value.end : upcomingEnd;

      return {
        from: addDays(thisWeek.value.start, -1).toISOString(),
        to: end.toISOString(),
      };
    }),
    {
      query: {
        ...liveQuery,
        enabled: computed(() => toValue(enabled)),
        placeholderData: (previous) => previous,
      },
    },
  );

  const browsed = useFleetCalendar(
    slug,
    computed(() => ({
      from: addDays(shownWeek.value?.start ?? today.value, -1).toISOString(),
      to: (shownWeek.value?.end ?? today.value).toISOString(),
    })),
    {
      query: {
        ...liveQuery,
        enabled: computed(() => toValue(enabled) && browsing.value),
        placeholderData: (previous) => previous,
      },
    },
  );

  const showWeek = (next: Week) => {
    if (shownWeek.value && sameWeek(next, shownWeek.value)) return;

    shownWeek.value = next;
  };

  return {
    // The upcoming list reads this week's answer whatever week is on screen.
    events: computed(() => main.data.value?.items),
    weekEvents: computed(() =>
      browsing.value ? browsed.data.value?.items : main.data.value?.items,
    ),
    loading: main.isLoading,
    showWeek,
  };
};
