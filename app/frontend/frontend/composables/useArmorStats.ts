import { computed, toValue, type MaybeRefOrGetter } from "vue";
import {
  HardpointCategoryEnum,
  type Hardpoint,
  type ComponentArmor,
} from "@/services/fyApi";

export type ArmorValue = {
  key: string;
  label: string;
  value: number;
};

export type ArmorStats = {
  health: number;
  // 1 - incoming damage multiplier. Negative when the armor amplifies a type
  // (a few hulls ship with damageEnergy > 1).
  reductions: ArmorValue[];
  // Per-shot damage threshold: a hit landing at or below this value is turned
  // away entirely rather than being reduced. Not a flat subtraction.
  deflections: ArmorValue[];
  // How well the armor plate resists damage to itself. Negative when a type is
  // amplified.
  selfResistances: ArmorValue[];
  // Signature multipliers the armor applies to the ship, as a delta (0.13 = +13%).
  signatures: ArmorValue[];
  damageMultiplierByType: Record<string, number>;
  hasData: boolean;
};

const DAMAGE_TYPES: {
  key: string;
  label: string;
  damage: keyof ComponentArmor;
  deflection: keyof ComponentArmor;
  selfResistance: keyof ComponentArmor;
}[] = [
  {
    key: "physical",
    label: "labels.defense.damageType.physical",
    damage: "damagePhysical",
    deflection: "deflectionPhysical",
    selfResistance: "selfResistancePhysical",
  },
  {
    key: "energy",
    label: "labels.defense.damageType.energy",
    damage: "damageEnergy",
    deflection: "deflectionEnergy",
    selfResistance: "selfResistanceEnergy",
  },
  {
    key: "distortion",
    label: "labels.defense.damageType.distortion",
    damage: "damageDistortion",
    deflection: "deflectionDistortion",
    selfResistance: "selfResistanceDistortion",
  },
  {
    key: "thermal",
    label: "labels.defense.damageType.thermal",
    damage: "damageThermal",
    deflection: "deflectionThermal",
    selfResistance: "selfResistanceThermal",
  },
];

const SIGNATURE_TYPES: {
  key: string;
  label: string;
  field: keyof ComponentArmor;
}[] = [
  {
    key: "electromagnetic",
    label: "labels.defense.signature.electromagnetic",
    field: "signalElectromagnetic",
  },
  {
    key: "infrared",
    label: "labels.defense.signature.infrared",
    field: "signalInfrared",
  },
  {
    key: "crossSection",
    label: "labels.defense.signature.crossSection",
    field: "signalCrossSection",
  },
];

function findArmor(
  hardpoints: Hardpoint[] | undefined,
): ComponentArmor | undefined {
  for (const hardpoint of hardpoints || []) {
    if (
      hardpoint.category === HardpointCategoryEnum.ARMOR &&
      hardpoint.component?.typeData
    ) {
      return hardpoint.component.typeData as ComponentArmor;
    }

    const nested = findArmor(hardpoint.hardpoints);
    if (nested) return nested;
  }

  return undefined;
}

export function computeArmorStats(
  hardpoints: Hardpoint[] | undefined,
): ArmorStats {
  const armor = findArmor(hardpoints);

  const damageMultiplierByType: Record<string, number> = {};
  const reductions: ArmorValue[] = [];
  const deflections: ArmorValue[] = [];
  const selfResistances: ArmorValue[] = [];

  for (const type of DAMAGE_TYPES) {
    const { key, label } = type;

    const multiplier = (armor?.[type.damage] as number | undefined) ?? 1;
    damageMultiplierByType[key] = multiplier > 0 ? multiplier : 1;

    // Thermal reduction is 1.0 on every hull in the game files, so rows with no
    // effect carry no information — drop them rather than show a wall of zeros.
    if (multiplier !== 1) {
      reductions.push({ key, label, value: 1 - multiplier });
    }

    const deflection = (armor?.[type.deflection] as number | undefined) ?? 0;
    if (deflection > 0) {
      deflections.push({ key, label, value: deflection });
    }

    const selfMultiplier = armor?.[type.selfResistance] as number | undefined;
    if (selfMultiplier != null && selfMultiplier !== 1) {
      selfResistances.push({ key, label, value: 1 - selfMultiplier });
    }
  }

  const signatures = SIGNATURE_TYPES.map(({ key, label, field }) => {
    const multiplier = armor?.[field] as number | undefined;
    return { key, label, value: multiplier == null ? 0 : multiplier - 1 };
  }).filter((entry) => entry.value !== 0);

  return {
    health: armor?.health || 0,
    reductions,
    deflections,
    selfResistances,
    signatures,
    damageMultiplierByType,
    hasData: !!armor,
  };
}

export function useArmorStats(
  hardpoints: MaybeRefOrGetter<Hardpoint[] | undefined>,
) {
  return computed(() => computeArmorStats(toValue(hardpoints)));
}
