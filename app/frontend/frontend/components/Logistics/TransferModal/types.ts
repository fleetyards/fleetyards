import type { InventoryTransferCreateInput } from "@/services/fyApi";

export type TransferSource = {
  id: string;
  name: string;
};

// Where a transfer can go. `needsAnswer` comes from the API's own view of what
// the sender may write to, rather than from the client re-deriving the rule.
export type TransferTargetOption = {
  value: string;
  label: string;
  needsAnswer: boolean;
  payload: Pick<
    InventoryTransferCreateInput,
    | "inventoryId"
    | "fleetInventoryId"
    | "vehicleId"
    | "recipientUsername"
    | "recipientFleetSlug"
  >;
};
