import { computed, toValue, type MaybeRefOrGetter } from "vue";
import type { WeaponIndexItem } from "@/services/fyApi";
import type { ArmorStats } from "@/frontend/composables/useArmorStats";
import type { ShieldStats } from "@/frontend/composables/useShieldStats";

export const DEFLECTION_DAMAGE_TYPES = [
  { key: "physical", label: "labels.defense.damageType.physical" },
  { key: "energy", label: "labels.defense.damageType.energy" },
  { key: "distortion", label: "labels.defense.damageType.distortion" },
  { key: "thermal", label: "labels.defense.damageType.thermal" },
] as const;

export type DeflectionTypeResult = {
  key: string;
  label: string;
  raw: number;
  // Damage left after the shield soaks its share and armor applies its
  // multiplier — what actually meets the deflection threshold.
  effective: number;
  deflection: number;
  // The shield soaks this type completely, so it never reaches the armor.
  absorbed: boolean;
  pierces: boolean;
};

// Three genuinely different fates, and conflating the first two is wrong: a
// shot the shield soaks never meets the armor at all, so armor deflection has
// no say in it. An S10 energy cannon against a 100%-energy-absorbing shield is
// stopped by the shield — not "deflected" by a 9-point armor threshold.
export type DeflectionOutcome = "absorbed" | "deflected" | "pierces";

export type DeflectionResult = {
  weapon: WeaponIndexItem;
  types: DeflectionTypeResult[];
  // The type that gets closest to (or furthest past) the threshold, among those
  // that actually reach the armor. Null when the shield soaks everything.
  best: DeflectionTypeResult | null;
  // Null when nothing reaches the armor — there is no threshold to measure against.
  margin: number | null;
  outcome: DeflectionOutcome;
};

export type DeflectionSummary = {
  results: DeflectionResult[];
  absorbedCount: number;
  deflectedCount: number;
  pierceCount: number;
};

// Absorption is published as a min-max range per damage type (the Gladius soaks
// `0 - 45%` of physical). erkul pairs that range with a shields-health slider,
// and the endpoints line up: at full health their numbers use the maximum, and
// with shields gone nothing is soaked at all. So we read shield health as the
// position within that range.
export function absorptionAtHealth(
  shield: ShieldStats,
  key: string,
  shieldHealth: number,
): number {
  if (shieldHealth <= 0) return 0;

  const max = shield.absorptionByType[key] ?? 1;
  const min = shield.absorptionMinByType[key] ?? max;

  return min + (max - min) * Math.min(shieldHealth, 1);
}

// Shield resistance follows the same range-by-health rule as absorption.
export function resistanceAtHealth(
  shield: ShieldStats,
  key: string,
  shieldHealth: number,
): number {
  if (shieldHealth <= 0) return 0;

  const max = shield.resistanceByType[key] ?? 0;
  const min = shield.resistanceMinByType[key] ?? 0;

  return min + (max - min) * Math.min(shieldHealth, 1);
}

// Deflection scales linearly with armor health. Verified against erkul: an
// Asgard at 51% armor reports 71 physical / 45 energy against 139 / 88 at full
// health. The game files carry an empty `<healthCurve useLUT="0" />` with no
// points, so the curve is not in the data — this is measured, not read.
export function deflectionAtHealth(
  armor: ArmorStats,
  key: string,
  armorHealth: number,
): number {
  const base = armor.deflections.find((entry) => entry.key === key)?.value ?? 0;
  const ratio = Math.min(Math.max(armorHealth, 0), 1);

  return base * ratio;
}

export function computeDeflectionCheck(
  weapons: WeaponIndexItem[] | undefined,
  armor: ArmorStats,
  shield: ShieldStats,
  shieldHealth: number,
  armorHealth: number,
): DeflectionSummary {
  const results: DeflectionResult[] = [];

  for (const weapon of weapons || []) {
    // erkul excludes laser beams: they deal continuous damage rather than
    // discrete shots, so there is no per-shot alpha to test against a threshold.
    if (weapon.beam) continue;

    const types: DeflectionTypeResult[] = [];
    // Alpha is compared per pellet — a scattergun's shot is split across its
    // pellets, and each pellet meets the deflection threshold on its own.
    const pellets = Math.max(weapon.pelletsPerShot ?? 1, 1);

    for (const { key, label } of DEFLECTION_DAMAGE_TYPES) {
      const perShot =
        (weapon.damagePerShot as Record<string, number | undefined>)?.[key] ??
        0;
      if (perShot <= 0) continue;

      const raw = perShot / pellets;

      // What survives the shield is what meets the armor's deflection
      // threshold. The armor's own damage reduction is deliberately absent:
      // measured against erkul, an Asgard at zero shields reports effective
      // damage equal to raw alpha, which its 30% physical reduction would rule
      // out. The Gladius made these indistinguishable — its armor reduction
      // (0.75) and shield resistance (1 - 0.25) happen to be the same number.
      const absorption = absorptionAtHealth(shield, key, shieldHealth);
      const resistance = resistanceAtHealth(shield, key, shieldHealth);
      const deflection = deflectionAtHealth(armor, key, armorHealth);

      const effective = raw * (1 - absorption) * (1 - resistance);

      types.push({
        key,
        label,
        raw,
        effective,
        deflection,
        absorbed: absorption >= 1,
        pierces: effective > deflection,
      });
    }

    if (!types.length) continue;

    const reaching = types.filter((entry) => !entry.absorbed);

    if (!reaching.length) {
      results.push({
        weapon,
        types,
        best: null,
        margin: null,
        outcome: "absorbed",
      });
      continue;
    }

    // Rank by how far past the threshold each type gets; the weapon as a whole
    // pierces if any single type that reaches the armor does.
    const best = reaching.reduce((leader, entry) =>
      entry.effective - entry.deflection > leader.effective - leader.deflection
        ? entry
        : leader,
    );

    results.push({
      weapon,
      types,
      best,
      margin: best.effective - best.deflection,
      outcome: reaching.some((entry) => entry.pierces)
        ? "pierces"
        : "deflected",
    });
  }

  // Fully absorbed weapons lead — nothing gets through at all — then the rest
  // ranked by how close they come to beating the armor threshold.
  results.sort((a, b) => {
    if (a.margin === null && b.margin === null) return 0;
    if (a.margin === null) return -1;
    if (b.margin === null) return 1;
    return a.margin - b.margin;
  });

  return {
    results,
    absorbedCount: results.filter((entry) => entry.outcome === "absorbed")
      .length,
    deflectedCount: results.filter((entry) => entry.outcome === "deflected")
      .length,
    pierceCount: results.filter((entry) => entry.outcome === "pierces").length,
  };
}

export function useDeflectionCheck(
  weapons: MaybeRefOrGetter<WeaponIndexItem[] | undefined>,
  armor: MaybeRefOrGetter<ArmorStats>,
  shield: MaybeRefOrGetter<ShieldStats>,
  shieldHealth: MaybeRefOrGetter<number>,
  armorHealth: MaybeRefOrGetter<number>,
) {
  return computed(() =>
    computeDeflectionCheck(
      toValue(weapons),
      toValue(armor),
      toValue(shield),
      toValue(shieldHealth),
      toValue(armorHealth),
    ),
  );
}
