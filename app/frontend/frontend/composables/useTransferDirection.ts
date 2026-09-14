export type TransferDirection = "incoming" | "outgoing";

// Which side of the transfers list is open. In the query rather than a route of
// its own, for the same reason the ledger tab is -- see `useLedgerTab`.
export const useTransferDirection = () => {
  const route = useRoute();
  const router = useRouter();

  const direction = computed<TransferDirection>({
    get: () => (route.query.direction === "outgoing" ? "outgoing" : "incoming"),
    set: (value) => {
      if (direction.value === value) return;

      const query = { ...route.query };
      // The page number belongs to the list it was counted on.
      delete query.page;

      if (value === "outgoing") {
        query.direction = "outgoing";
      } else {
        delete query.direction;
      }

      void router.replace({ query });
    },
  });

  return { direction };
};
