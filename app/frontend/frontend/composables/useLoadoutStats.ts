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

export type WeaponStat = {
  id: string;
  name: string;
  size?: string;
  dps: number;
};

export type LoadoutStats = {
  dps: DamageBreakdown;
  alpha: DamageBreakdown;
  weapons: WeaponStat[];
  weaponCount: number;
  hasData: boolean;
};

const DAMAGE_TYPES = ["physical", "energy", "distortion", "thermal"] as const;

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

export function computeLoadoutStats(
  hardpoints: Hardpoint[] | undefined,
): LoadoutStats {
  const weaponHardpoints = collectWeaponHardpoints(hardpoints);

  const dps = emptyBreakdown();
  const alpha = emptyBreakdown();
  const weapons: WeaponStat[] = [];

  for (const hardpoint of weaponHardpoints) {
    const component = hardpoint.component!;
    const weapon = component.typeData as ComponentWeapon;
    const weaponDps = emptyBreakdown();

    if (weapon.beam && weapon.damagePerSecond) {
      addBreakdown(dps, weapon.damagePerSecond, 1);
      addBreakdown(weaponDps, weapon.damagePerSecond, 1);
    } else if (!isMissile(weapon) && weapon.fireRate && weapon.damagePerShot) {
      const pellets = weapon.pelletsPerShot || 1;
      addBreakdown(alpha, weapon.damagePerShot, pellets);
      addBreakdown(dps, weapon.damagePerShot, (pellets * weapon.fireRate) / 60);
      addBreakdown(weaponDps, weapon.damagePerShot, (pellets * weapon.fireRate) / 60);
    } else {
      continue;
    }

    weapons.push({
      id: hardpoint.id,
      name: component.name,
      size: component.size,
      dps: weaponDps.total,
    });
  }

  weapons.sort((a, b) => b.dps - a.dps);

  return { dps, alpha, weapons, weaponCount: weapons.length, hasData: weapons.length > 0 };
}

export function useLoadoutStats(
  hardpoints: MaybeRefOrGetter<Hardpoint[] | undefined>,
) {
  return computed(() => computeLoadoutStats(toValue(hardpoints)));
}
