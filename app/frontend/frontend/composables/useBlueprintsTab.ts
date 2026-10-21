export const BLUEPRINTS_TABS = ["owned", "wanted"] as const;

export type BlueprintsTab = (typeof BLUEPRINTS_TABS)[number];

/*
 * Which of a person's -- or a fleet's -- blueprint lists is open, held in the
 * query the way `useLedgerTab` holds an inventory's view: a route of its own
 * would rebuild the page on every switch. `tab` is one of `useFilters`'
 * view-state keys, so it never reaches the API as a filter.
 */
export const useBlueprintsTab = () => {
  const route = useRoute();
  const router = useRouter();

  const activeTab = computed<BlueprintsTab>({
    get: () => (route.query.tab === "wanted" ? "wanted" : "owned"),
    set: (tab) => {
      if (activeTab.value === tab) return;

      const query = { ...route.query };
      delete query.page;

      if (tab === "owned") {
        delete query.tab;
      } else {
        query.tab = tab;
      }

      void router.push({ query });
    },
  });

  return { activeTab };
};
