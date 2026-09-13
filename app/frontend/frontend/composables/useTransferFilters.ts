import { useFilters } from "@/shared/composables/useFilters";
import type { InventoryTransferQuery } from "@/services/fyApi";

export const useTransferFilters = (updateCallback?: () => Promise<void>) =>
  useFilters<InventoryTransferQuery>({
    updateCallback: async () => {
      await updateCallback?.();
    },
  });
