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
     * Any value here is a picture somebody chose, including one that names this
     * contract's own kind. Nothing writes a default into the column any more --
     * an unset preset is the absence of a choice, which is what lets the
     * fleet's own cover answer below.
     */
    const chosen = presetImageUrl("contracts", contract?.coverImagePreset);
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
