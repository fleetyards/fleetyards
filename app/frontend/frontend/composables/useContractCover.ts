import type {
  Fleet,
  FleetContract,
  FleetContractDetail,
} from "@/services/fyApi";
import fallback from "@/images/fallback/store_image.webp";
import { presetImageUrl } from "@/shared/composables/usePresetImages";

// Mission art that comes closest, until a kind has its own. Keyed rather than
// guessed so replacing it is one line, and so a missing file degrades to the
// generic placeholder instead of to whatever happens to sort first.
const STAND_IN_FOR_KIND: Record<string, string> = {
  transport: "cargo_hauling",
  procurement: "other",
  crafting: "mining",
};

const standInFor = (kind: string) =>
  presetImageUrl("missions", STAND_IN_FOR_KIND[kind]);

type ContractLike = FleetContract | FleetContractDetail;

export const useContractCover = () => {
  /*
   * The contract's own art wins -- somebody chose it for this job. Then the
   * preset they picked, then the fleet's cover for this kind from its settings,
   * then anything dropped into images/contracts/, then the mission art that
   * comes closest, then the generic placeholder.
   */
  const resolve = (contract?: ContractLike | null, fleet?: Fleet | null) => {
    const kind = contract?.kind;
    if (!kind) return fallback;

    const uploaded = contract?.coverImage;
    if (uploaded) {
      return (
        uploaded.mediumUrl || uploaded.smallUrl || uploaded.url || fallback
      );
    }

    /*
     * Only a preset naming something other than the kind is a choice. The model
     * writes the kind into `cover_image_preset` whenever the form left it
     * empty, so treating that as a choice put a default ahead of the cover a
     * fleet configured for this kind in its own settings -- which is the one
     * thing here somebody deliberately set up.
     */
    const chosen =
      contract?.coverImagePreset && contract.coverImagePreset !== kind
        ? presetImageUrl("contracts", contract.coverImagePreset)
        : undefined;
    if (chosen) return chosen;

    const own =
      fleet?.contractCovers?.[kind as keyof typeof fleet.contractCovers];

    return (
      own?.mediumUrl ??
      own?.url ??
      presetImageUrl("contracts", kind) ??
      standInFor(kind) ??
      fallback
    );
  };

  return { resolve };
};
