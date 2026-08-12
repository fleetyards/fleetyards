import { computed, toValue, type MaybeRefOrGetter } from "vue";
import {
  HardpointCategoryEnum,
  type Hardpoint,
  type ComponentWeapon,
} from "@/services/fyApi";
import { simulateLoadoutPower, type PortOverrides } from "./useLoadoutSim";

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
  missileDamage: number;
  weaponPowerRatio: number;
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

// Duty-cycle fraction of burst a weapon can sustain: fire until the energy pool
// drains (or heat forces an overheat lockout), then wait out cooldown + regen.
// This is erkul's `Io` model. `powerRatio` (< 1 when the ship's shared weapon
// power pool can't feed every gun at once) scales an energy weapon's effective
// pool and regen, shrinking its uptime — the shared-pool sustained throttle.
// Heat-limited (ballistic) weapons aren't power-fed, so they ignore powerRatio.
export function sustainedRatio(
  weapon: ComponentWeapon,
  powerRatio = 1,
): number {
  const fireRate = weapon.fireRate ? weapon.fireRate / 60 : 0;
  if (fireRate <= 0) return 1;

  const regen = weapon.regen;
  if (regen?.maxAmmoLoad && regen.maxRegenPerSecond) {
    const pool = Math.round(regen.maxAmmoLoad * powerRatio);
    const regenPerSecond = regen.maxRegenPerSecond * powerRatio;
    if (pool <= 0 || regenPerSecond <= 0) return 0;
    const timeFiring = pool / fireRate;
    const timeRegen = pool / regenPerSecond;
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
  weaponPoolSize?: number,
  overrides?: PortOverrides,
): LoadoutStats {
  const weaponHardpoints = collectWeaponHardpoints(hardpoints);
  const sim = simulateLoadoutPower(
    hardpoints,
    weaponPoolSize,
    "SCM",
    overrides,
  );
  // Weapon power follows the actual pip allocation shown in the power UI — the
  // default distribution until the user assigns pips, their choices afterwards.
  // Only when the ship has no parsed plant segments do we fall back to the
  // segment-independent max-power ratio, so those ships never regress to 0 DPS.
  const powerRatio =
    sim.totalSegments > 0 ? sim.weaponPoolRatio : sim.weaponMaxRatio;
  // Every weapon needs the weapon system powered (≥1 pip) to fire at all — zero
  // burst/alpha too when unpowered, not just sustained. The sustained *throttle*
  // from partial power is energy-only and handled by sustainedRatio's branch
  // (ballistics use the heat model and ignore powerRatio).
  const powered = powerRatio > 0 ? 1 : 0;

  const dps = emptyBreakdown();
  const sustainedDps = emptyBreakdown();
  const alpha = emptyBreakdown();
  const weapons: WeaponStat[] = [];
  let missileDamage = 0;

  for (const hardpoint of weaponHardpoints) {
    const component = hardpoint.component!;
    const weapon = component.typeData as ComponentWeapon;
    const weaponDps = emptyBreakdown();
    const ratio = sustainedRatio(weapon, powerRatio) * powered;

    if (weapon.beam && weapon.damagePerSecond) {
      addBreakdown(dps, weapon.damagePerSecond, powered);
      addBreakdown(sustainedDps, weapon.damagePerSecond, ratio);
      addBreakdown(weaponDps, weapon.damagePerSecond, powered);
    } else if (!isMissile(weapon) && weapon.fireRate && weapon.damagePerShot) {
      const pellets = weapon.pelletsPerShot || 1;
      const shotsPerSecond = (pellets * weapon.fireRate) / 60;
      addBreakdown(alpha, weapon.damagePerShot, pellets * powered);
      addBreakdown(dps, weapon.damagePerShot, shotsPerSecond * powered);
      addBreakdown(sustainedDps, weapon.damagePerShot, shotsPerSecond * ratio);
      addBreakdown(weaponDps, weapon.damagePerShot, shotsPerSecond * powered);
    } else {
      // Missiles (and other non-DPS munitions) don't contribute to DPS/alpha,
      // but their total payload damage is surfaced separately.
      if (isMissile(weapon) && weapon.damagePerShot) {
        for (const value of Object.values(weapon.damagePerShot)) {
          if (typeof value === "number") missileDamage += value;
        }
      }
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
    missileDamage,
    weaponPowerRatio: powerRatio,
    hasData: weapons.length > 0,
  };
}

export function useLoadoutStats(
  hardpoints: MaybeRefOrGetter<Hardpoint[] | undefined>,
  weaponPoolSize?: MaybeRefOrGetter<number | undefined>,
  overrides?: MaybeRefOrGetter<PortOverrides | undefined>,
) {
  return computed(() =>
    computeLoadoutStats(
      toValue(hardpoints),
      toValue(weaponPoolSize),
      toValue(overrides),
    ),
  );
}
