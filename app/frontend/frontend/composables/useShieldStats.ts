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

export type ShieldStats = {
  totalHp: number;
  totalRegen: number;
  shieldCount: number;
  resistances: Resistance[];
  hasData: boolean;
};

type ComponentShieldResistanceMap = NonNullable<ComponentShield["resistance"]>;

const RESISTANCE_TYPES: {
  key: keyof ComponentShieldResistanceMap;
  label: string;
}[] = [
  { key: "physical", label: "labels.survivability.resistancePhysical" },
  { key: "energy", label: "labels.survivability.resistanceEnergy" },
  { key: "distortion", label: "labels.survivability.resistanceDistortion" },
  { key: "thermal", label: "labels.survivability.resistanceThermal" },
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

export function computeShieldStats(
  hardpoints: Hardpoint[] | undefined,
): ShieldStats {
  const shields = collectShieldHardpoints(hardpoints).map(
    (hardpoint) => hardpoint.component!.typeData as ComponentShield,
  );

  let totalHp = 0;
  let totalRegen = 0;

  for (const shield of shields) {
    totalHp += shield.maxHealth || 0;
    totalRegen += shield.maxRegen || 0;
  }

  // Resistances are percentages, so they don't sum — average them, weighted
  // by each shield's HP (a bigger shield contributes more to the effective
  // resistance profile).
  const resistances = RESISTANCE_TYPES.map(({ key, label }) => {
    let weighted = 0;
    let weight = 0;

    for (const shield of shields) {
      const hp = shield.maxHealth || 0;
      const resistance = shield.resistance?.[key]?.max;
      if (resistance != null && hp > 0) {
        weighted += resistance * hp;
        weight += hp;
      }
    }

    return { key, label, value: weight > 0 ? weighted / weight : 0 };
  }).filter((entry) => entry.value > 0);

  return {
    totalHp,
    totalRegen,
    shieldCount: shields.length,
    resistances,
    hasData: shields.length > 0 && totalHp > 0,
  };
}

export function useShieldStats(
  hardpoints: MaybeRefOrGetter<Hardpoint[] | undefined>,
) {
  return computed(() => computeShieldStats(toValue(hardpoints)));
}
