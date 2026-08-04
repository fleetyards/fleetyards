import { computed, toValue, type MaybeRefOrGetter } from "vue";
import {
  HardpointCategoryEnum,
  type Hardpoint,
  type ComponentWeapon,
} from "@/services/fyApi";

export type DamageBreakdown = {
  total: number;
  physical: number;
  energy: number;
  distortion: number;
  thermal: number;
};

export type DamageType = "physical" | "energy" | "distortion" | "thermal";

export type WeaponStat = {
  id: string;
  name: string;
  size?: string;
  dps: number;
  sustainedDps: number;
  type: DamageType;
};

export type LoadoutStats = {
  dps: DamageBreakdown;
  sustainedDps: DamageBreakdown;
  alpha: DamageBreakdown;
  weapons: WeaponStat[];
  weaponCount: number;
  hasData: boolean;
};

const DAMAGE_TYPES: DamageType[] = [
  "physical",
  "energy",
  "distortion",
  "thermal",
];

function emptyBreakdown(): DamageBreakdown {
  return { total: 0, physical: 0, energy: 0, distortion: 0, thermal: 0 };
}

function addBreakdown(
  target: DamageBreakdown,
  damage: Partial<Record<string, number>> | undefined,
  multiplier: number,
) {
  if (!damage) return;

  for (const type of DAMAGE_TYPES) {
    const value = damage[type];
    if (typeof value === "number" && value > 0) {
      const scaled = value * multiplier;
      target[type] += scaled;
      target.total += scaled;
    }
  }
}

function collectWeaponHardpoints(
  hardpoints: Hardpoint[] | undefined,
  collected: Hardpoint[] = [],
): Hardpoint[] {
  for (const hardpoint of hardpoints || []) {
    if (
      hardpoint.category === HardpointCategoryEnum.WEAPONS &&
      hardpoint.component?.typeData
    ) {
      collected.push(hardpoint);
    }

    if (hardpoint.hardpoints?.length) {
      collectWeaponHardpoints(hardpoint.hardpoints, collected);
    }
  }

  return collected;
}

function isMissile(weapon: ComponentWeapon): boolean {
  return "trackingSignal" in (weapon as Record<string, unknown>);
}

// Fraction of burst DPS a weapon can sustain indefinitely, from its duty cycle.
// Energy weapons drain a shot pool then wait for cooldown + regen; ballistic
// weapons fire until they overheat then wait out the overheat lockout. Validated
// against erkul.games (energy: exact; ballistic: within ~1%).
function sustainedRatio(weapon: ComponentWeapon): number {
  const fireRate = weapon.fireRate ? weapon.fireRate / 60 : 0;
  if (fireRate <= 0) return 1;

  const regen = weapon.regen;
  if (regen?.maxAmmoLoad && regen.maxRegenPerSecond) {
    const pool = regen.maxAmmoLoad;
    const timeFiring = pool / fireRate;
    const timeRegen = pool / regen.maxRegenPerSecond;
    const cooldown = regen.regenerationCooldown || 0;
    return timeFiring / (timeFiring + cooldown + timeRegen);
  }

  const heat = weapon.heat;
  if (heat?.overheatTemperature && weapon.heatPerShot && heat.overheatFixTime) {
    const timeFiring =
      heat.overheatTemperature / (weapon.heatPerShot * fireRate);
    return timeFiring / (timeFiring + heat.overheatFixTime);
  }

  return 1;
}

export function computeLoadoutStats(
  hardpoints: Hardpoint[] | undefined,
): LoadoutStats {
  const weaponHardpoints = collectWeaponHardpoints(hardpoints);

  const dps = emptyBreakdown();
  const sustainedDps = emptyBreakdown();
  const alpha = emptyBreakdown();
  const weapons: WeaponStat[] = [];

  for (const hardpoint of weaponHardpoints) {
    const component = hardpoint.component!;
    const weapon = component.typeData as ComponentWeapon;
    const weaponDps = emptyBreakdown();
    const ratio = sustainedRatio(weapon);

    if (weapon.beam && weapon.damagePerSecond) {
      addBreakdown(dps, weapon.damagePerSecond, 1);
      addBreakdown(sustainedDps, weapon.damagePerSecond, ratio);
      addBreakdown(weaponDps, weapon.damagePerSecond, 1);
    } else if (!isMissile(weapon) && weapon.fireRate && weapon.damagePerShot) {
      const pellets = weapon.pelletsPerShot || 1;
      const shotsPerSecond = (pellets * weapon.fireRate) / 60;
      addBreakdown(alpha, weapon.damagePerShot, pellets);
      addBreakdown(dps, weapon.damagePerShot, shotsPerSecond);
      addBreakdown(sustainedDps, weapon.damagePerShot, shotsPerSecond * ratio);
      addBreakdown(weaponDps, weapon.damagePerShot, shotsPerSecond);
    } else {
      continue;
    }

    const type = DAMAGE_TYPES.reduce((best, current) =>
      weaponDps[current] > weaponDps[best] ? current : best,
    );

    weapons.push({
      id: hardpoint.id,
      name: component.name,
      size: component.size,
      dps: weaponDps.total,
      sustainedDps: weaponDps.total * ratio,
      type,
    });
  }

  weapons.sort((a, b) => b.dps - a.dps);

  return {
    dps,
    sustainedDps,
    alpha,
    weapons,
    weaponCount: weapons.length,
    hasData: weapons.length > 0,
  };
}

export function useLoadoutStats(
  hardpoints: MaybeRefOrGetter<Hardpoint[] | undefined>,
) {
  return computed(() => computeLoadoutStats(toValue(hardpoints)));
}
