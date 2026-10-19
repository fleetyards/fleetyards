import { type FleetContractItemInput } from "@/services/fyApi";

/**
 * A line of a contract not saved yet: the API input, plus what the picked part
 * is beyond its id -- whether the game counts it in pieces, which keeps `units`
 * on offer when the draft is reopened. Stripped before the contract is posted,
 * since the input takes nothing it does not declare.
 */
export type ContractItemDraft = FleetContractItemInput & { counted?: boolean };

export const contractItemInput = ({
  counted: _counted,
  ...input
}: ContractItemDraft): FleetContractItemInput => input;
