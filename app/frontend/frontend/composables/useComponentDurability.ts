import type { ComponentDurability } from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";
import type { HardpointStat } from "@/frontend/composables/useHardpointStats";

export type DurabilityGroupKey =
  "physical" | "damageTaken" | "selfRepair" | "distortion";

export interface DurabilityGroup {
  key: DurabilityGroupKey;
  stats: HardpointStat[];
}

const DAMAGE_TYPES = [
  "physical",
  "energy",
  "distortion",
  "thermal",
  "biochemical",
  "stun",
] as const;

// What it takes to break a component and bring it back, one group per block
// the game files describe. A group with nothing in it is left out, so a
// component the game cannot distort shows no distortion block at all rather
// than a row of zeros.
export const useComponentDurability = (
  durability: MaybeRefOrGetter<ComponentDurability | undefined | null>,
) => {
  const { t, toNumber } = useI18n();

  const stat = (key: string, value: string): HardpointStat => ({
    label: t(`labels.component.durability.${key}`),
    value,
  });

  const percent = (ratio: number) => `${Math.round(ratio * 100)}%`;

  return computed<DurabilityGroup[]>(() => {
    const value = toValue(durability);
    if (!value) return [];

    const physical: HardpointStat[] = [];
    if (value.health) {
      physical.push(stat("health", `${toNumber(value.health, "integer")} HP`));
    }
    if (value.mass) {
      physical.push(stat("mass", `${toNumber(value.mass, "integer")} kg`));
    }

    // A multiplier of 1 is the full hit, which is what every type does unless
    // the item says otherwise -- so only the ones that differ are worth a row.
    const damageTaken = DAMAGE_TYPES.flatMap((type) => {
      const multiplier = value.resistances?.[type];
      if (typeof multiplier !== "number" || multiplier === 1) return [];

      return [stat(type, percent(multiplier))];
    });

    const selfRepair: HardpointStat[] = [];
    const repair = value.selfRepair;
    if (repair?.maxRepairs) {
      if (repair.time) {
        selfRepair.push(
          stat("repairTime", String(toNumber(repair.time, "seconds"))),
        );
      }
      if (typeof repair.healthRatio === "number") {
        selfRepair.push(stat("repairsTo", percent(repair.healthRatio)));
      }
      selfRepair.push(
        stat("maxRepairs", String(toNumber(repair.maxRepairs, "integer"))),
      );
    }

    const distortion: HardpointStat[] = [];
    const limits = value.distortion;
    if (limits?.maximum) {
      const threshold = (ratio: number) =>
        String(toNumber(Math.round(limits.maximum! * ratio), "integer"));

      distortion.push(stat("disableAt", threshold(1)));
      if (limits.warningRatio) {
        distortion.push(stat("warningAt", threshold(limits.warningRatio)));
      }
      // Zero means it comes back the moment it drops under the maximum,
      // which the "disabled at" row already says.
      if (limits.recoveryRatio) {
        distortion.push(stat("recoversBelow", threshold(limits.recoveryRatio)));
      }
      if (limits.decayRate) {
        distortion.push(
          stat(
            "decayRate",
            `${toNumber(Math.round(limits.decayRate), "integer")}/s`,
          ),
        );
      }
      if (limits.decayDelay) {
        distortion.push(
          stat("decayDelay", String(toNumber(limits.decayDelay, "seconds"))),
        );
      }
    }

    const groups: DurabilityGroup[] = [
      { key: "physical", stats: physical },
      { key: "damageTaken", stats: damageTaken },
      { key: "selfRepair", stats: selfRepair },
      { key: "distortion", stats: distortion },
    ];

    return groups.filter((group) => group.stats.length);
  });
};
