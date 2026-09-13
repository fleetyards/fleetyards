import type { MaybeRefOrGetter } from "vue";
import { useComlink } from "@/shared/composables/useComlink";
import {
  type InventoryTransferCreateInput,
  useCreateFleetInventoryTransfer,
  useCreateHangarInventoryTransfer,
} from "@/services/fyApi";
import { useTransferTargets } from "@/frontend/composables/useTransferTargets";
import type { InventoryStockRecord } from "@/frontend/types/logistics";

type Options = {
  // The inventory being emptied. Null on a ship until something is put in it.
  source: MaybeRefOrGetter<{ id?: string | null; name?: string } | undefined>;
  // Every stock row the list is showing, so a bulk selection of ids can be
  // resolved back to the rows it named.
  records: MaybeRefOrGetter<InventoryStockRecord[]>;
  // Present when acting for a fleet; absent for a user's own inventory.
  fleetSlug?: MaybeRefOrGetter<string | undefined>;
  onSent: () => Promise<unknown>;
};

// Opening the transfer modal from a stock list. Shared by the three pages that
// have one -- a hangar inventory, a ship's hold, and a fleet inventory -- which
// differ only in which endpoint the send goes to.
export const useTransferModal = (options: Options) => {
  const comlink = useComlink();

  const { targets } = useTransferTargets({
    source: options.source,
    fleetSlug: options.fleetSlug,
  });

  const { mutateAsync: createHangarTransfer } =
    useCreateHangarInventoryTransfer();
  const { mutateAsync: createFleetTransfer } =
    useCreateFleetInventoryTransfer();

  const send = async (data: InventoryTransferCreateInput) => {
    const fleetSlug = toValue(options.fleetSlug);

    if (fleetSlug) {
      await createFleetTransfer({ fleetSlug, data });
    } else {
      await createHangarTransfer({ data });
    }

    await options.onSent();
  };

  // Starts from the rows the reader chose -- one, or a ticked set -- rather
  // than from the whole inventory: a hold with fifty positions made a modal
  // nobody could use.
  const openTransferModal = (positions: InventoryStockRecord[]) => {
    const source = toValue(options.source);

    if (!source?.id || positions.length === 0) return;

    comlink.emit("open-modal", {
      component: () =>
        import("@/frontend/components/Logistics/TransferModal/index.vue"),
      props: {
        source: { id: source.id, name: source.name },
        positions,
        targets: targets.value,
        onSend: send,
      },
    });
  };

  const openTransferForSelection = (selected: string[]) => {
    openTransferModal(
      toValue(options.records).filter((record) => selected.includes(record.id)),
    );
  };

  return { targets, openTransferModal, openTransferForSelection };
};
