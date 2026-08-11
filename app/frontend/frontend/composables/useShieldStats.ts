import { computed, toValue, type MaybeRefOrGetter } from "vue";
import {
  HardpointCategoryEnum,
  type Hardpoint,
  type ComponentShield,
} from "@/services/fyApi";

export type Resistance = {
  key: string;
  label: string;
  value: number;
};

export type Absorption = {
  key: string;
  label: string;
  min: number;
  max: number;
};

export type ShieldStats = {
  totalHp: number;
  totalRegen: number;
  shieldCount: number;
  resistances: Resistance[];
  // Share of each type the shield soaks. Anything below 100% bleeds through to
  // the hull while the shield is still up — that is what ballistics exploit.
  absorptions: Absorption[];
  resistanceByType: Record<string, number>;
  resistanceMinByType: Record<string, number>;
  absorptionByType: Record<string, number>;
  absorptionMinByType: Record<string, number>;
  hasData: boolean;
};

type ComponentShieldResistanceMap = NonNullable<ComponentShield["resistance"]>;

const DAMAGE_TYPES: {
  key: keyof ComponentShieldResistanceMap;
  label: string;
}[] = [
  { key: "physical", label: "labels.defense.damageType.physical" },
  { key: "energy", label: "labels.defense.damageType.energy" },
  { key: "distortion", label: "labels.defense.damageType.distortion" },
  { key: "thermal", label: "labels.defense.damageType.thermal" },
];

function collectShieldHardpoints(
  hardpoints: Hardpoint[] | undefined,
  collected: Hardpoint[] = [],
): Hardpoint[] {
  for (const hardpoint of hardpoints || []) {
    if (
      hardpoint.category === HardpointCategoryEnum.SHIELDGENERATOR &&
      hardpoint.component?.typeData
    ) {
      collected.push(hardpoint);
    }

    if (hardpoint.hardpoints?.length) {
      collectShieldHardpoints(hardpoint.hardpoints, collected);
    }
  }

  return collected;
}

// Percentages don't sum — average them, weighted by each shield's HP (a bigger
// shield contributes more to the effective profile). `fallback` is the value
// used when no shield reports the stat at all.
function weightedByHp(
  shields: ComponentShield[],
  pick: (shield: ComponentShield) => number | undefined,
  fallback: number,
): number {
  let weighted = 0;
  let weight = 0;

  for (const shield of shields) {
    const hp = shield.maxHealth || 0;
    const value = pick(shield);
    if (value != null && hp > 0) {
      weighted += value * hp;
      weight += hp;
    }
  }

  return weight > 0 ? weighted / weight : fallback;
}

export function computeShieldStats(
  hardpoints: Hardpoint[] | undefined,
  shieldPoolRatio = 1,
): ShieldStats {
  const shields = collectShieldHardpoints(hardpoints).map(
    (hardpoint) => hardpoint.component!.typeData as ComponentShield,
  );

  // Regen scales with the shield power allocation; an unpowered shield (0 pips)
  // offers no protection, so its HP drops to 0 as well.
  const powered = shieldPoolRatio > 0 ? 1 : 0;

  let rawHp = 0;
  let rawRegen = 0;

  for (const shield of shields) {
    rawHp += shield.maxHealth || 0;
    rawRegen += shield.maxRegen || 0;
  }

  // Displayed values reflect the current power; hasData stays true whenever the
  // ship structurally has shields, so an unpowered shield shows 0 (not hidden).
  const totalHp = rawHp * powered;
  const totalRegen = rawRegen * shieldPoolRatio;

  const resistanceByType: Record<string, number> = {};
  const resistanceMinByType: Record<string, number> = {};
  const absorptionByType: Record<string, number> = {};
  const absorptionMinByType: Record<string, number> = {};

  for (const { key } of DAMAGE_TYPES) {
    resistanceByType[key] = weightedByHp(
      shields,
      (shield) => shield.resistance?.[key]?.max,
      0,
    );
    resistanceMinByType[key] = weightedByHp(
      shields,
      (shield) => shield.resistance?.[key]?.min,
      0,
    );
    // Absent absorption data means the shield soaks the type completely.
    absorptionByType[key] = weightedByHp(
      shields,
      (shield) => shield.absorption?.[key]?.max,
      1,
    );
    absorptionMinByType[key] = weightedByHp(
      shields,
      (shield) => shield.absorption?.[key]?.min,
      1,
    );
  }

  const resistances = DAMAGE_TYPES.map(({ key, label }) => ({
    key,
    label,
    value: resistanceByType[key],
  })).filter((entry) => entry.value > 0);

  const absorptions = shields.length
    ? DAMAGE_TYPES.map(({ key, label }) => ({
        key,
        label,
        min: absorptionMinByType[key],
        max: absorptionByType[key],
      }))
    : [];

  return {
    totalHp,
    totalRegen,
    shieldCount: shields.length,
    resistances,
    absorptions,
    resistanceByType,
    resistanceMinByType,
    absorptionByType,
    absorptionMinByType,
    hasData: shields.length > 0 && rawHp > 0,
  };
}

export function useShieldStats(
  hardpoints: MaybeRefOrGetter<Hardpoint[] | undefined>,
  shieldPoolRatio?: MaybeRefOrGetter<number | undefined>,
) {
  return computed(() =>
    computeShieldStats(toValue(hardpoints), toValue(shieldPoolRatio) ?? 1),
  );
}
