import { craftedGrades } from "@/frontend/components/Logistics/crafted";
import {
  FleetContractQualityMatchEnum,
  type InventoryCraftedRef,
} from "@/services/fyApi";

type Translate = (key: string, options?: Record<string, unknown>) => string;

/**
 * What a crafted contract line asks for, in one phrase: the grades by the
 * line's own rule, or any grade where it names none.
 */
export const craftedLineLabel = (
  t: Translate,
  crafted: InventoryCraftedRef,
  qualityMatch?: string,
) => {
  const grades = craftedGrades(crafted.qualities, (position, grade) =>
    t("labels.logistics.crafted.slotGrade", { position, quality: grade }),
  );

  if (!grades.length) return t("labels.fleets.contracts.craftedAny");

  return t(
    qualityMatch === FleetContractQualityMatchEnum.EXACT
      ? "labels.fleets.contracts.craftedExact"
      : "labels.fleets.contracts.craftedAtLeast",
    { grades: grades.join(", ") },
  );
};
