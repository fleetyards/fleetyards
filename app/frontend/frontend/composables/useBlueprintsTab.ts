import type { LocationQuery } from "vue-router";

export const BLUEPRINTS_TABS = ["owned", "wanted", "missions"] as const;

export type BlueprintsTab = (typeof BLUEPRINTS_TABS)[number];

export const DEFAULT_BLUEPRINTS_TABS: readonly BlueprintsTab[] = [
  "owned",
  "wanted",
];

/*
 * Which of a person's -- or a fleet's -- blueprint lists is open, held in the
 * query the way `useLedgerTab` holds an inventory's view: a route of its own
 * would rebuild the page on every switch. `tab` is one of `useFilters`'
 * view-state keys, so it never reaches the API as a filter.
 *
 * `tabs` is what the page offers; anything else in the URL opens the first.
 */
export const useBlueprintsTab = (
  tabs: readonly BlueprintsTab[] = DEFAULT_BLUEPRINTS_TABS,
) => {
  const route = useRoute();
  const router = useRouter();

  const activeTab = computed<BlueprintsTab>({
    get: () => {
      const tab = route.query.tab as BlueprintsTab;

      return tabs.includes(tab) ? tab : tabs[0];
    },
    set: (tab) => {
      if (activeTab.value === tab) return;

      // The missions list takes the mission catalogue's filters and the other
      // two the blueprint catalogue's. Each query schema refuses the other's
      // keys, so crossing between them keeps only the page size; owned and
      // wanted share theirs, and only the page number is dropped.
      const crossing = [activeTab.value, tab].includes("missions");
      const { perPage } = route.query;
      const query: LocationQuery = crossing
        ? { ...(perPage ? { perPage } : {}) }
        : { ...route.query };
      delete query.page;

      if (tab === tabs[0]) {
        delete query.tab;
      } else {
        query.tab = tab;
      }

      void router.push({ query });
    },
  });

  return { activeTab };
};
