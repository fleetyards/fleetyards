import {
  type ComponentWeapon,
  type ComponentWeaponDamage,
  type Hardpoint,
  HardpointCategoryEnum,
} from "@/services/fyApi";
import {
  NO_REGEN_MODIFIER,
  type WeaponRegenModifier,
} from "@/frontend/composables/powerSim";
import {
  dutyCycle,
  isMissile,
  shotsPerSecond,
} from "@/frontend/composables/useLoadoutStats";

export interface PoweredGun {
  key: string;
  name: string;
  count: number;
  weapon: ComponentWeapon;
  // Per gun, at the weapon power the guns are given.
  sustainedDps: number;
}

const damageTotal = (damage?: ComponentWeaponDamage) =>
  (["physical", "energy", "distortion", "thermal"] as const).reduce(
    (sum, type) => sum + Math.max(damage?.[type] || 0, 0),
    0,
  );

// The same sum the combat card makes for one gun: damage per second, cut to
// the share of time its capacitor or its heat lets it fire.
const sustainedDps = (
  weapon: ComponentWeapon,
  powerRatio: number,
  modifier: WeaponRegenModifier,
) => {
  if (powerRatio <= 0) return 0;

  const dps =
    weapon.beam && weapon.damagePerSecond
      ? damageTotal(weapon.damagePerSecond)
      : damageTotal(weapon.damagePerShot) * shotsPerSecond(weapon);

  return dps * dutyCycle(weapon, powerRatio, modifier).ratio;
};

// A gun does damage: a missile is a payload, a mining laser works on rock, and
// a tractor beam in a gun slot does none.
const isGun = (weapon: ComponentWeapon) =>
  !weapon.mining &&
  !isMissile(weapon) &&
  (weapon.beam
    ? damageTotal(weapon.damagePerSecond) > 0
    : damageTotal(weapon.damagePerShot) > 0 && !!weapon.fireRate);

// Every gun on the ship, turrets' included, since the weapon pips feed them
// all; stacked by part, as the planner shows one card per kind of gun.
export function poweredGuns(
  hardpoints: Hardpoint[] | undefined,
  powerRatio = 1,
  modifier: WeaponRegenModifier = NO_REGEN_MODIFIER,
): PoweredGun[] {
  const stacks = new Map<string, PoweredGun>();

  const walk = (list: Hardpoint[]) => {
    for (const hardpoint of list) {
      const weapon = hardpoint.component?.typeData as
        ComponentWeapon | undefined;

      if (hardpoint.category === HardpointCategoryEnum.WEAPONS && weapon) {
        if (!isGun(weapon)) continue;

        const name = hardpoint.component?.name || "";
        const existing = stacks.get(name);
        if (existing) {
          existing.count += 1;
        } else {
          stacks.set(name, {
            key: hardpoint.id,
            name,
            count: 1,
            weapon,
            sustainedDps: sustainedDps(weapon, powerRatio, modifier),
          });
        }
        continue;
      }

      walk(hardpoint.hardpoints || []);
    }
  };

  walk(hardpoints || []);

  return [...stacks.values()];
}
