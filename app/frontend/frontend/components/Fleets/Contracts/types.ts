import { type FleetContractItemInput } from "@/services/fyApi";

/**
 * What a line not saved yet holds beyond its ids: whether the game counts the
 * part in pieces, which keeps `units` on offer when the draft is reopened, and
 * the slug of the recipe it asks for, which the crafter loads the recipe by.
 */
export type ContractItemDraftExtras = {
  counted?: boolean;
  craftedBlueprintSlug?: string;
};

/**
 * A line of a contract not saved yet. The extras are stripped before the
 * contract is posted, since the input takes nothing it does not declare.
 */
export type ContractItemDraft = FleetContractItemInput &
  ContractItemDraftExtras;

export const contractItemInput = ({
  counted: _counted,
  craftedBlueprintSlug: _craftedBlueprintSlug,
  ...input
}: ContractItemDraft): FleetContractItemInput => input;
