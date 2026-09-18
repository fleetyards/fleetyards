import {
  byStat,
  segmentsOf,
  valueAt,
  withUnit,
} from "@/frontend/composables/useQualityRamp";
import { type BlueprintCostSlot } from "@/services/fyApi";

export type CraftedStat = {
  key: string;
  name: string;
  /** The stat as it comes out, or the combined factor where we hold no base. */
  value: string;
  /** What it is at the neutral grade, where the catalogue holds the figure. */
  base?: string;
  factor: string;
  /** How many slots move this stat -- two, for 358 of the recipes. */
  slots: number;
};

/**
 * The crafted item's stats at the grades currently chosen.
 *
 * A slot's own panel can only speak for that slot, and 358 of the recipes in
 * the build move one stat from two different slots -- a shield's strength off
 * both its field array and its frequency controller. Neither panel is the
 * answer on its own, so the factors are composed here.
 *
 * They are composed by multiplying. The files state each slot's contribution
 * as an independent factor on the same stat and say nothing about how two of
 * them combine, and a product is what independent factors mean; no recipe in
 * the build stacks more than two.
 */
export const useCraftedStats = (
  slots: MaybeRefOrGetter<BlueprintCostSlot[]>,
  qualityFor: (position: number) => number,
) => {
  const stats = computed<CraftedStat[]>(() => {
    const combined = new Map<
      string,
      {
        name: string;
        unit?: string | null;
        base?: number | null;
        factor: number;
        slots: number;
      }
    >();

    toValue(slots).forEach((slot) => {
      const at = qualityFor(slot.position);

      byStat(slot.modifiers || []).forEach((group, key) => {
        const segments = segmentsOf(group);
        // 598 modifiers name a stat and carry no figures at all; there is
        // nothing to compose for those.
        if (!segments.length) return;

        const held = combined.get(key);
        const factor = valueAt(segments, at);

        combined.set(key, {
          name: held?.name || group[0].name || key,
          unit: held?.unit ?? group[0].unit,
          base: held?.base ?? group[0].baseValue,
          factor: (held?.factor ?? 1) * factor,
          slots: (held?.slots ?? 0) + 1,
        });
      });
    });

    return [...combined.entries()].map(([key, stat]) => {
      const base = stat.base ?? undefined;
      const factor = `${stat.factor.toFixed(3)}×`;

      return {
        key,
        name: stat.name,
        value:
          base === undefined ? factor : withUnit(base * stat.factor, stat.unit),
        base: base === undefined ? undefined : withUnit(base, stat.unit),
        factor,
        slots: stat.slots,
      };
    });
  });

  return { stats };
};
