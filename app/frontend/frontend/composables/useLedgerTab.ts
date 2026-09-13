import type { RouteRecordName } from "vue-router";

export type LedgerTab = "stock" | "log";

type Options = {
  stock: RouteRecordName;
  log: RouteRecordName;
};

// Which view of an inventory is open, held as a route rather than as view state
// in the query.
//
// It was `?tab=log` first, and that had two faults. `useFilters#getQuery`
// spreads the whole route query into `q`, and the query schemas are
// `additionalProperties: false`, so the key reached the API as an unknown
// filter and came back a 400 that read as a server error. And a tab is a place
// you can link someone to, which is what a route is for.
export const useLedgerTab = (routes: Options) => {
  const route = useRoute();
  const router = useRouter();

  const activeTab = computed<LedgerTab>({
    get: () => (route.name === routes.log ? "log" : "stock"),
    set: (tab) => {
      const name = tab === "log" ? routes.log : routes.stock;

      if (route.name === name) return;

      // The page number belongs to the list it was counted on: page three of
      // the log is not page three of the stock.
      const query = { ...route.query };
      delete query.page;

      void router.push({ name, params: route.params, query });
    },
  });

  return { activeTab };
};
