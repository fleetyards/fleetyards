import { computed, toValue, type MaybeRefOrGetter } from "vue";
import {
  type ComponentWeaponDamage,
  HardpointCategoryEnum,
  type Hardpoint,
  type ComponentWeapon,
  type ComponentTurret,
  ComponentTurretControlEnum,
} from "@/services/fyApi";
import { simulateLoadoutPower, type PortOverrides } from "./useLoadoutSim";
import { computeControllerStats } from "@/frontend/composables/useControllerStats";

export type DamageBreakdown = {
  total: number;
  physical: number;
  energy: number;
  distortion: number;
  thermal: number;
};

export type DamageType = "physical" | "energy" | "distortion" | "thermal";

// Who fires a weapon: the pilot, unless a turret it sits on is manned, aimed
// from a remote seat or run by the point-defence system.
export type ControlGroup = "pilot" | ComponentTurretControlEnum;

export type ControlBreakdown = Record<ControlGroup, number>;

export type WeaponStat = {
  id: string;
  name: string;
  size?: string;
  dps: number;
  sustainedDps: number;
  type: DamageType;
  control: ControlGroup;
};

export type LoadoutStats = {
  dps: DamageBreakdown;
  sustainedDps: DamageBreakdown;
  alpha: DamageBreakdown;
  dpsByControl: ControlBreakdown;
  weapons: WeaponStat[];
  weaponCount: number;
  missileDamage: number;
  // Fitted missiles, whether or not their payload is parsed.
  missileCount: number;
  // How many missiles the ship keeps armed at once, and the time between
  // launches -- only for a ship that carries missiles, since nearly every
  // ship has a missile controller whether or not it has a rack.
  maxArmedMissiles?: number;
  launchCooldown?: number;
  weaponPowerRatio: number;
  // Whether the card has a figure to show: guns, a missile payload, or the
  // capacity of the missiles it carries. Fitted missiles alone are not one.
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
  damage: ComponentWeaponDamage | undefined,
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

export const CONTROL_GROUPS: ControlGroup[] = [
  "pilot",
  ComponentTurretControlEnum.MANNED,
  ComponentTurretControlEnum.REMOTE,
  ComponentTurretControlEnum.PDS,
];

function emptyControlBreakdown(): ControlBreakdown {
  return { pilot: 0, manned: 0, remote: 0, pds: 0 };
}

type WeaponHardpoint = {
  hardpoint: Hardpoint;
  control: ControlGroup;
};

// The outermost mount that names its operator decides for everything inside
// it: a gimbal on a manned turret is aimed by the gunner, not by the pilot.
function collectWeaponHardpoints(
  hardpoints: Hardpoint[] | undefined,
  collected: WeaponHardpoint[] = [],
  inherited?: ControlGroup,
): WeaponHardpoint[] {
  for (const hardpoint of hardpoints || []) {
    const control =
      inherited ??
      (hardpoint.component?.typeData as ComponentTurret | undefined)?.control;

    // A mining laser's beam damage is what it does to a rock; counted here it
    // would read as a ship's firepower.
    if (
      hardpoint.category === HardpointCategoryEnum.WEAPONS &&
      hardpoint.component?.typeData &&
      !(hardpoint.component.typeData as ComponentWeapon).mining
    ) {
      collected.push({ hardpoint, control: control ?? "pilot" });
    }

    if (hardpoint.hardpoints?.length) {
      collectWeaponHardpoints(hardpoint.hardpoints, collected, control);
    }
  }

  return collected;
}

function isMissile(weapon: ComponentWeapon): boolean {
  return "trackingSignal" in (weapon as Record<string, unknown>);
}

// Duty-cycle fraction of burst a weapon can sustain: fire until the energy pool
// drains (or heat forces an overheat lockout), then wait out cooldown + regen.
// `powerRatio` (< 1 when the ship's shared weapon
// power pool can't feed every gun at once) scales an energy weapon's effective
// pool and regen, shrinking its uptime — the shared-pool sustained throttle.
// Heat-limited (ballistic) weapons aren't power-fed, so they ignore powerRatio.
export function shotsPerSecond(weapon: ComponentWeapon): number {
  return ((weapon.pelletsPerShot || 1) * (weapon.fireRate || 0)) / 60;
}

export function sustainedRatio(
  weapon: ComponentWeapon,
  powerRatio = 1,
): number {
  return dutyCycle(weapon, powerRatio).ratio;
}

export type DutyCycle = {
  ratio: number;
  // Seconds the weapon spends not firing in each cycle, and the cycle's length.
  // Zero off-time is a weapon that never has to stop.
  offTime: number;
  cycle: number;
};

const CONTINUOUS: DutyCycle = { ratio: 1, offTime: 0, cycle: 0 };
const SILENT: DutyCycle = { ratio: 0, offTime: Infinity, cycle: Infinity };

export function dutyCycle(weapon: ComponentWeapon, powerRatio = 1): DutyCycle {
  const fireRate = weapon.fireRate ? weapon.fireRate / 60 : 0;
  if (fireRate <= 0) return CONTINUOUS;

  const regen = weapon.regen;
  if (regen?.maxAmmoLoad && regen.maxRegenPerSecond) {
    const pool = Math.round(regen.maxAmmoLoad * powerRatio);
    const regenPerSecond = regen.maxRegenPerSecond * powerRatio;
    if (pool <= 0 || regenPerSecond <= 0) return SILENT;
    const timeFiring = pool / fireRate;
    const offTime = (regen.regenerationCooldown || 0) + pool / regenPerSecond;
    return cycleOf(timeFiring, offTime);
  }

  const heat = weapon.heat;
  if (heat?.overheatTemperature && weapon.heatPerShot && heat.overheatFixTime) {
    const timeFiring =
      heat.overheatTemperature / (weapon.heatPerShot * fireRate);
    return cycleOf(timeFiring, heat.overheatFixTime);
  }

  return CONTINUOUS;
}

function cycleOf(timeFiring: number, offTime: number): DutyCycle {
  const cycle = timeFiring + offTime;
  return { ratio: timeFiring / cycle, offTime, cycle };
}

export function computeLoadoutStats(
  hardpoints: Hardpoint[] | undefined,
  weaponPoolSize?: number,
  overrides?: PortOverrides,
): LoadoutStats {
  const weaponHardpoints = collectWeaponHardpoints(hardpoints);
  const controllers = computeControllerStats(hardpoints);
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
  const dpsByControl = emptyControlBreakdown();
  const weapons: WeaponStat[] = [];
  let missileDamage = 0;
  let missileCount = 0;

  for (const { hardpoint, control } of weaponHardpoints) {
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
      const rate = shotsPerSecond(weapon);
      addBreakdown(alpha, weapon.damagePerShot, pellets * powered);
      addBreakdown(dps, weapon.damagePerShot, rate * powered);
      addBreakdown(sustainedDps, weapon.damagePerShot, rate * ratio);
      addBreakdown(weaponDps, weapon.damagePerShot, rate * powered);
    } else {
      // Missiles (and other non-DPS munitions) don't contribute to DPS/alpha,
      // but their total payload damage is surfaced separately.
      if (isMissile(weapon)) {
        missileCount += 1;
        for (const value of Object.values(weapon.damagePerShot || {})) {
          if (typeof value === "number") missileDamage += value;
        }
      }
      continue;
    }

    const type = DAMAGE_TYPES.reduce((best, current) =>
      weaponDps[current] > weaponDps[best] ? current : best,
    );

    dpsByControl[control] += weaponDps.total;

    weapons.push({
      id: hardpoint.id,
      name: component.name,
      size: component.size,
      dps: weaponDps.total,
      sustainedDps: weaponDps.total * ratio,
      type,
      control,
    });
  }

  weapons.sort((a, b) => b.dps - a.dps);

  return {
    dps,
    sustainedDps,
    alpha,
    dpsByControl,
    weapons,
    weaponCount: weapons.length,
    missileDamage,
    missileCount,
    ...(missileCount > 0
      ? {
          maxArmedMissiles: controllers.maxArmedMissiles,
          launchCooldown: controllers.launchCooldown,
        }
      : {}),
    weaponPowerRatio: powerRatio,
    hasData:
      weapons.length > 0 ||
      missileDamage > 0 ||
      (missileCount > 0 && (controllers.maxArmedMissiles || 0) > 0),
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
