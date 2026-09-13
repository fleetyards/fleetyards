import type { MaybeRefOrGetter } from "vue";
import type { AsyncStatus } from "@/shared/components/AsyncData.types";
import { useI18n } from "@/shared/composables/useI18n";
import { useComlink } from "@/shared/composables/useComlink";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import {
  type InventoryTransfer,
  useAcceptFleetInventoryTransfer,
  useAcceptHangarInventoryTransfer,
  useCancelFleetInventoryTransfer,
  useCancelHangarInventoryTransfer,
  useDeclineFleetInventoryTransfer,
  useDeclineHangarInventoryTransfer,
  useFleetInventories,
  useFleetInventoryTransfers,
  useHangarInventories,
  useHangarInventoryTransfers,
  useReportFleetInventoryTransfer,
  useReportHangarInventoryTransfer,
} from "@/services/fyApi";

// The transfers list and everything you can do to a row, for either side. One
// composable rather than one per mount: the two differ only in which endpoints
// they call, which is the same reason the backend serves both from a single
// controller concern.
export const useInventoryTransfers = (
  fleetSlug: MaybeRefOrGetter<string | undefined>,
  direction: MaybeRefOrGetter<"incoming" | "outgoing">,
  getQuery?: () => Record<string, unknown>,
) => {
  const { t } = useI18n();
  const comlink = useComlink();
  const { displayAlert } = useAppNotifications();

  const actingFleet = computed(() => toValue(fleetSlug));
  const forFleet = computed(() => !!actingFleet.value);

  const params = computed(() => ({
    direction: toValue(direction),
    q: getQuery?.() ?? {},
  }));

  const hangar = useHangarInventoryTransfers(params, {
    query: { enabled: computed(() => !forFleet.value) },
  });

  const fleet = useFleetInventoryTransfers(
    computed(() => actingFleet.value ?? ""),
    params,
    { query: { enabled: forFleet } },
  );

  const { data: hangarInventories } = useHangarInventories(undefined, {
    query: { enabled: computed(() => !forFleet.value) },
  });

  const { data: fleetInventories } = useFleetInventories(
    computed(() => actingFleet.value ?? ""),
    undefined,
    { query: { enabled: forFleet } },
  );

  const transfers = computed<InventoryTransfer[]>(
    () => (forFleet.value ? fleet.data.value : hangar.data.value)?.items ?? [],
  );

  const isLoading = computed(() =>
    forFleet.value ? fleet.isLoading.value : hangar.isLoading.value,
  );

  const refetch = async () => {
    await (forFleet.value ? fleet.refetch() : hangar.refetch());
  };

  // Where an accepted transfer can land: whichever side this list acts for.
  const destinations = computed(() =>
    forFleet.value
      ? (fleetInventories.value?.items ?? [])
      : (hangarInventories.value?.items ?? []),
  );

  // What `FilteredList` draws its loading and empty states from. `AsyncStatus`
  // holds refs rather than values, so each field is a computed that follows
  // whichever of the two queries is live.
  const active = computed(() => (forFleet.value ? fleet : hangar));

  const asyncStatus: AsyncStatus = {
    fetchStatus: computed(() => active.value.fetchStatus.value),
    isError: computed(() => active.value.isError.value),
    isPending: computed(() => active.value.isPending.value),
    isLoading: computed(() => active.value.isLoading.value),
    isFetching: computed(() => active.value.isFetching.value),
    isRefetching: computed(() => active.value.isRefetching.value),
    error: computed(() => active.value.error.value),
  };

  const mutations = {
    hangar: {
      accept: useAcceptHangarInventoryTransfer(),
      decline: useDeclineHangarInventoryTransfer(),
      cancel: useCancelHangarInventoryTransfer(),
      report: useReportHangarInventoryTransfer(),
    },
    fleet: {
      accept: useAcceptFleetInventoryTransfer(),
      decline: useDeclineFleetInventoryTransfer(),
      cancel: useCancelFleetInventoryTransfer(),
      report: useReportFleetInventoryTransfer(),
    },
  };

  const busy = ref(false);

  const run = async (action: () => Promise<unknown>) => {
    busy.value = true;

    try {
      await action();
      await refetch();
    } catch {
      displayAlert({ text: t("messages.logistics.transfer.resolve.failure") });
    } finally {
      busy.value = false;
    }
  };

  // The fleet endpoints take the slug in the path and name the inventory with a
  // different key; nothing above this has to know that.
  const call = (
    name: "accept" | "decline" | "cancel" | "report",
    id: string,
    data?: Record<string, unknown>,
  ) => {
    const slug = actingFleet.value;

    if (slug) {
      return mutations.fleet[name].mutateAsync({
        fleetSlug: slug,
        id,
        // eslint-disable-next-line @typescript-eslint/no-explicit-any
        data: data as any,
      });
    }

    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    return mutations.hangar[name].mutateAsync({ id, data: data as any });
  };

  // Where it lands is the receiving side's choice -- the sender never named an
  // inventory -- so it is always asked, even when only one could take it.
  const onAccept = (transfer: InventoryTransfer) => {
    comlink.emit("open-modal", {
      component: () =>
        import("@/frontend/components/Logistics/TransferAcceptModal/index.vue"),
      props: {
        transfer,
        inventories: destinations.value,
        onAccept: (inventoryId: string) =>
          run(() =>
            call("accept", transfer.id, {
              [actingFleet.value ? "fleetInventoryId" : "inventoryId"]:
                inventoryId,
            }),
          ),
      },
    });
  };

  const onDecline = (transfer: InventoryTransfer) =>
    run(() => call("decline", transfer.id));

  const onCancel = (transfer: InventoryTransfer) =>
    run(() => call("cancel", transfer.id));

  const onReport = (transfer: InventoryTransfer) => {
    comlink.emit("open-modal", {
      component: () =>
        import("@/frontend/components/Logistics/TransferReportModal/index.vue"),
      props: {
        transfer,
        onReport: (payload: { reason: string; note?: string }) =>
          run(() => call("report", transfer.id, payload)),
      },
    });
  };

  return {
    transfers,
    refetch,
    asyncStatus,
    isLoading,
    busy,
    onAccept,
    onDecline,
    onCancel,
    onReport,
  };
};
