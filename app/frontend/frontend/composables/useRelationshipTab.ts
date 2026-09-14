import type { RouteRecordName } from "vue-router";
import type {
  RelationshipTab,
  RelationshipTabRoutes,
} from "@/frontend/components/Relationships/types";

const TABS: RelationshipTab[] = ["accepted", "incoming", "outgoing", "ignored"];

// Which list is open, held as a route rather than as local state, for the same
// reason the transfers list holds its direction there: a page somebody can be
// linked to, and a reload that lands where it left off.
//
// The tab is also the query: `accepted` asks for accepted rows in either
// direction, the two request tabs ask for pending rows on one side, and
// `ignored` asks for the rows this party turned away -- which is why it is a
// tab you have to choose rather than anything the default view shows.
export const useRelationshipTab = (routes: RelationshipTabRoutes) => {
  const route = useRoute();
  const router = useRouter();

  const tab = computed<RelationshipTab>({
    get: () =>
      TABS.find((name) => routes[name] === (route.name as RouteRecordName)) ??
      "accepted",
    set: (value) => {
      const name = routes[value];

      if (route.name === name) return;

      // The page number belongs to the list it was counted on.
      const query = { ...route.query };
      delete query.page;

      void router.push({ name, params: route.params, query });
    },
  });

  const state = computed(() =>
    tab.value === "accepted"
      ? "accepted"
      : tab.value === "ignored"
        ? "ignored"
        : "pending",
  );

  const direction = computed(() =>
    tab.value === "incoming"
      ? "incoming"
      : tab.value === "outgoing"
        ? "outgoing"
        : undefined,
  );

  return { tab, tabs: TABS, state, direction };
};
