import type { ModelDefense } from "@/services/fyApi";
import type { ArmorStats } from "@/frontend/composables/useArmorStats";
import type { ShieldStats } from "@/frontend/composables/useShieldStats";
import type { DamageType } from "@/frontend/composables/useLoadoutStats";
import type { LoadoutWeapon } from "@/frontend/composables/usePenetrationCheck";
import {
  absorptionAtHealth,
  deflectionAtHealth,
  pelletDamage,
  resistanceAtHealth,
} from "@/frontend/composables/useDeflectionCheck";

const DAMAGE_TYPES: DamageType[] = [
  "physical",
  "energy",
  "distortion",
  "thermal",
];

const SELF_RESISTANCE = {
  physical: "selfResistancePhysical",
  energy: "selfResistanceEnergy",
  distortion: "selfResistanceDistortion",
  thermal: "selfResistanceThermal",
} as const;

// Absorption and resistance move with shield health, and deflection with
// armor health, so each layer is drained in slices with the rates held
// constant across a slice.
const SHIELD_SLICES = 50;
const ARMOR_SLICES = 25;
const MAX_STEPS = 1000;

export type KillProfile = {
  shield: ShieldStats;
  armor: ArmorStats;
  // Multiplier on the damage the armor plate takes itself.
  armorSelf: Record<DamageType, number>;
  hull: number;
  generators: ShieldGenerator[];
};

export type ShieldGenerator = {
  regen: number;
  // Seconds without a hit before the generator starts regenerating.
  delay: number;
};

export type KillSource = {
  type: DamageType;
  dps: number;
  // Raw damage of one pellet, which is what meets the deflection threshold.
  pellet: number;
};

export type KillStart = {
  shieldHealth: number;
  armorHealth: number;
};

export type EffectiveHp = Record<DamageType, number | null>;

export type TimeToKill = {
  // Seconds until the shields are down, and until the hull is destroyed.
  // Infinity when the loadout never gets there; null when the ship has no hull
  // health to measure against.
  shieldsDown: number;
  kill: number | null;
};

export function killProfile(
  model: ModelDefense,
  shield: ShieldStats,
  armor: ArmorStats,
): KillProfile {
  const armorSelf = {} as Record<DamageType, number>;
  for (const type of DAMAGE_TYPES) {
    armorSelf[type] = model.armor?.[SELF_RESISTANCE[type]] ?? 1;
  }

  const generators =
    shield.totalHp > 0
      ? model.shields
          .filter((generator) => (generator.maxRegen || 0) > 0)
          .map((generator) => ({
            regen: generator.maxRegen,
            delay: generator.damagedRegenDelay || 0,
          }))
      : [];

  return {
    shield,
    armor,
    armorSelf,
    hull: model.hullHealth || 0,
    generators,
  };
}

// The share of the time a generator regenerates under this loadout's fire. It
// only does once nothing has hit it for its delay, so a single gun that never
// has to stop keeps it down for good. Every gun, identical ones included, is
// assumed to cycle independently of the others.
export function regenUptime(
  weapons: LoadoutWeapon[],
  regenDelay: number,
): number {
  const firing = weapons.filter((weapon) =>
    Object.values(weapon.sustainedDps).some((dps) => dps > 0),
  );
  if (!firing.length) return 1;

  return firing.reduce((uptime, { duty, count }) => {
    if (duty.offTime <= regenDelay) return 0;
    return uptime * ((duty.offTime - regenDelay) / duty.cycle) ** count;
  }, 1);
}

// Shield HP per second regenerated on average under this loadout's fire.
export function regenUnderFire(
  profile: KillProfile,
  weapons: LoadoutWeapon[],
): number {
  return profile.generators.reduce(
    (sum, generator) =>
      sum + generator.regen * regenUptime(weapons, generator.delay),
    0,
  );
}

// Seconds for `sources` to bring the target from `start` to shields down, and
// to a destroyed hull. Shields take what they absorb, less their resistance;
// what they let through meets the armor, whose plate takes it at its own
// resistance until it breaks and then hands it on to the hull. The armor's
// multiplier on hull damage is left out, as in the deflection check.
// Distortion stops at the shields: it never damages armor or hull. A ship with
// no hull health has no kill time.
export function simulateKill(
  profile: KillProfile,
  sources: KillSource[],
  start: KillStart,
  regen = 0,
): TimeToKill {
  const { shield, armor, armorSelf } = profile;
  const shieldMax = shield.totalHp;
  const armorMax = armor.health;
  const measuresKill = profile.hull > 0;

  let shieldHp = shieldMax * clamp(start.shieldHealth);
  let armorHp = armorMax * clamp(start.armorHealth);
  let hullHp = profile.hull;
  let elapsed = 0;
  let shieldsDown = Infinity;
  let kill = Infinity;

  const result = () => ({ shieldsDown, kill: measuresKill ? kill : null });

  // Fire continues past a kill: bleed-through can destroy the hull while the
  // shields still stand, and the shields-down time is still worth knowing.
  for (let step = 0; step < MAX_STEPS; step++) {
    if (shieldHp <= 0 && !Number.isFinite(shieldsDown)) shieldsDown = elapsed;
    if (measuresKill && hullHp <= 0 && !Number.isFinite(kill)) kill = elapsed;
    if (
      Number.isFinite(shieldsDown) &&
      (!measuresKill || Number.isFinite(kill))
    ) {
      return result();
    }

    const shieldRatio = shieldMax > 0 ? shieldHp / shieldMax : 0;
    const armorRatio = armorMax > 0 ? armorHp / armorMax : 0;

    let shieldRate = 0;
    let armorRate = 0;
    let hullRate = 0;

    for (const { type, dps, pellet } of sources) {
      const absorption = absorptionAtHealth(shield, type, shieldRatio);
      const resistance = resistanceAtHealth(shield, type, shieldRatio);

      // The same split the deflection check uses for what reaches the armor.
      shieldRate += dps * absorption * (1 - resistance);
      if (type === "distortion") continue;

      const through = (1 - absorption) * (1 - resistance);
      if (
        armorHp > 0 &&
        pellet * through <= deflectionAtHealth(armor, type, armorRatio)
      ) {
        continue;
      }

      if (armorHp > 0) {
        armorRate += dps * through * armorSelf[type];
      } else {
        hullRate += dps * through;
      }
    }

    // Shields that are down stay down: under fire they never sit out the
    // downed-regen delay.
    if (shieldHp > 0) shieldRate -= regen;

    const dt = Math.min(
      timeToNextSlice(shieldHp, shieldRate, shieldMax / SHIELD_SLICES),
      timeToNextSlice(armorHp, armorRate, armorMax / ARMOR_SLICES),
      measuresKill && hullHp > 0 && hullRate > 0 ? hullHp / hullRate : Infinity,
    );

    if (!Number.isFinite(dt)) return result();

    shieldHp = settle(shieldHp - Math.max(shieldRate, 0) * dt, shieldMax);
    armorHp = settle(armorHp - armorRate * dt, armorMax);
    hullHp = settle(hullHp - hullRate * dt, profile.hull);
    elapsed += dt;
  }

  return result();
}

// Raw damage of one type it takes to destroy the ship, from the given state.
// Deflection is left out: that belongs to a gun, not to the ship. Distortion
// never destroys a ship, so its figure is the damage that drops the shields.
export function effectiveHp(
  profile: KillProfile,
  start: KillStart,
): EffectiveHp {
  const result = {} as EffectiveHp;

  for (const type of DAMAGE_TYPES) {
    const distortion = type === "distortion";

    if (distortion ? profile.shield.totalHp <= 0 : profile.hull <= 0) {
      result[type] = null;
      continue;
    }

    const { shieldsDown, kill } = simulateKill(
      profile,
      [{ type, dps: 1, pellet: Infinity }],
      start,
    );
    const value = distortion ? shieldsDown : kill;

    result[type] = value !== null && Number.isFinite(value) ? value : null;
  }

  return result;
}

export function loadoutSources(weapons: LoadoutWeapon[]): KillSource[] {
  return weapons.flatMap((weapon) =>
    DAMAGE_TYPES.filter((type) => weapon.sustainedDps[type] > 0).map(
      (type) => ({
        type,
        dps: weapon.sustainedDps[type] * weapon.count,
        pellet: pelletDamage(weapon, type),
      }),
    ),
  );
}

export function timeToKill(
  profile: KillProfile,
  weapons: LoadoutWeapon[],
  start: KillStart,
): TimeToKill {
  return simulateKill(
    profile,
    loadoutSources(weapons),
    start,
    regenUnderFire(profile, weapons),
  );
}

function clamp(ratio: number): number {
  return Math.min(Math.max(ratio, 0), 1);
}

// Time until `hp` falls to the slice boundary below it.
function timeToNextSlice(hp: number, rate: number, slice: number): number {
  if (hp <= 0 || rate <= 0) return Infinity;
  if (slice <= 0) return hp / rate;

  const boundary = Math.max(Math.ceil(hp / slice - 1e-9) - 1, 0) * slice;
  return (hp - boundary) / rate;
}

// Floating-point drift would otherwise leave a sliver of HP that takes a step
// of its own.
function settle(hp: number, max: number): number {
  return hp <= max * 1e-9 ? 0 : hp;
}
