import type { RouteRecordName } from "vue-router";

export type TransferDirection = "incoming" | "outgoing";

type Options = {
  incoming: RouteRecordName;
  outgoing: RouteRecordName;
};

// Which side of the transfers list is open, held as a route for the same reason
// the ledger is: a list you can link somebody to, and a reload that lands where
// it left off.
export const useTransferDirection = (routes: Options) => {
  const route = useRoute();
  const router = useRouter();

  const direction = computed<TransferDirection>({
    get: () => (route.name === routes.outgoing ? "outgoing" : "incoming"),
    set: (value) => {
      const name = value === "outgoing" ? routes.outgoing : routes.incoming;

      if (route.name === name) return;

      // The page number belongs to the list it was counted on.
      const query = { ...route.query };
      delete query.page;

      void router.push({ name, params: route.params, query });
    },
  });

  return { direction };
};
