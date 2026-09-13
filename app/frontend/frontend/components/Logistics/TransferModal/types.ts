import type { InventoryTransferCreateInput } from "@/services/fyApi";

export type TransferSource = {
  id: string;
  name: string;
};

// Where a transfer can go. `needsAnswer` comes from the API's own view of what
// the sender may write to, rather than from the client re-deriving the rule.
// Which picker an option belongs to. Users and fleets are separate choices, not
// one mixed list -- they are different kinds of address and read as such.
export type TransferTargetKind = "inventory" | "mine" | "fleet" | "user";

export type TransferTargetOption = {
  kind: TransferTargetKind;
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
