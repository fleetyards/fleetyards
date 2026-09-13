import type { MaybeRefOrGetter } from "vue";
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
  fleetSlug?: MaybeRefOrGetter<string | undefined>,
) => {
  const { t } = useI18n();
  const comlink = useComlink();
  const { displayAlert } = useAppNotifications();

  const actingFleet = computed(() => toValue(fleetSlug));
  const forFleet = computed(() => !!actingFleet.value);

  const direction = ref<"incoming" | "outgoing">("incoming");

  const params = computed(() => ({ direction: direction.value }));

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

  const refetch = () => (forFleet.value ? fleet.refetch() : hangar.refetch());

  const destinations = computed(() =>
    forFleet.value
      ? (fleetInventories.value?.items ?? [])
      : (hangarInventories.value?.items ?? []),
  );

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
    direction,
    transfers,
    isLoading,
    busy,
    onAccept,
    onDecline,
    onCancel,
    onReport,
  };
};
