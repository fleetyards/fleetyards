import {
  NO_REGEN_MODIFIER,
  type WeaponRegenModifier,
} from "@/frontend/composables/powerSim";
import {
  type ComponentTurret,
  type ComponentWeapon,
  type ComponentWeaponDamage,
  ComponentTurretControlEnum,
  type Hardpoint,
  HardpointCategoryEnum,
} from "@/services/fyApi";
import {
  type DamageType,
  dutyCycle,
  isMissile,
  shotsPerSecond,
} from "@/frontend/composables/useLoadoutStats";

export const SLOT_POSITIONS = [
  "front",
  "rear",
  "left",
  "right",
  "top",
  "bottom",
  "upper",
  "lower",
  "nose",
  "tail",
  "dorsal",
  "ventral",
  "interior",
  "center",
] as const;

export type SlotPosition = (typeof SLOT_POSITIONS)[number];

// Where a slot sits, as its name says: `hardpoint_turret_manned_front`,
// `hardpoint_remote_turret_left`. Two turrets of one model are told apart by
// nothing else.
export const slotPosition = (name?: string): SlotPosition | undefined =>
  (name || "")
    .toLowerCase()
    .split(/[^a-z]+/)
    .find((word): word is SlotPosition =>
      (SLOT_POSITIONS as readonly string[]).includes(word),
    );

// Who works a group of weapons: the pilot, a gunner in a manned turret, a
// remote seat, the point-defence system, or the pilot's racks. A turret that
// carries no damage at all (a tractor beam) is a tool rather than a weapon.
export type StationKind =
  "pilot" | ComponentTurretControlEnum | "missiles" | "utility";

export interface GunStack {
  key: string;
  name: string;
  size?: string;
  manufacturer?: string;
  // The mount the gun sits on, when it has one: a gimbal, a fixed mount.
  mount?: string;
  count: number;
  // Per gun.
  dps: number;
  sustainedDps: number;
  alpha: number;
  type?: DamageType;
  missile: boolean;
  // Whether the gun does damage at all, whatever the power: a gun the pilot
  // has switched off is still a gun, and a tractor beam never is one.
  armed: boolean;
  weapon: ComponentWeapon;
  // One of the stacked guns, for its full figures.
  hardpoint: Hardpoint;
  // Every gun in the stack.
  hardpoints: Hardpoint[];
}

export interface Station {
  key: string;
  kind: StationKind;
  // The slot's part: the turret or the rack. The pilot's guns have none.
  part?: Hardpoint;
  // Identical stations (two remote turrets with the same guns) collapse into
  // one entry with a count, and keep every position they sit at.
  count: number;
  positions: SlotPosition[];
  // Every turret or rack the collapsed station stands for.
  parts: Hardpoint[];
  guns: GunStack[];
  // Per station, so the total is `dps * count`.
  dps: number;
  sustainedDps: number;
  missileDamage: number;
}

const DAMAGE_TYPES: DamageType[] = [
  "physical",
  "energy",
  "distortion",
  "thermal",
];

const damageTotal = (damage?: ComponentWeaponDamage) =>
  DAMAGE_TYPES.reduce((sum, type) => sum + Math.max(damage?.[type] || 0, 0), 0);

const dominantType = (damage?: ComponentWeaponDamage): DamageType | undefined =>
  DAMAGE_TYPES.reduce<DamageType | undefined>((best, type) => {
    const value = damage?.[type] || 0;
    if (value <= 0) return best;
    return !best || value > (damage?.[best] || 0) ? type : best;
  }, undefined);

type GunFigures = Pick<
  GunStack,
  "dps" | "sustainedDps" | "alpha" | "type" | "missile" | "armed"
>;

// A missile's payload counts every damage type it carries, as the combat
// card's missile total does.
const payload = (damage?: ComponentWeaponDamage) =>
  Object.values(damage || {}).reduce<number>(
    (total, value) => total + (typeof value === "number" ? value : 0),
    0,
  );

// The same sums the combat card makes, per gun. A missile does no damage per
// second; its payload is its figure.
export function gunFigures(
  weapon: ComponentWeapon,
  powerRatio = 1,
  modifier: WeaponRegenModifier = NO_REGEN_MODIFIER,
): GunFigures {
  const powered = powerRatio > 0 ? 1 : 0;

  if (isMissile(weapon)) {
    const damage = payload(weapon.damagePerShot);
    return {
      dps: 0,
      sustainedDps: 0,
      alpha: damage,
      type: dominantType(weapon.damagePerShot),
      missile: true,
      armed: damage > 0,
    };
  }

  const ratio = dutyCycle(weapon, powerRatio, modifier).ratio * powered;

  if (weapon.beam && weapon.damagePerSecond) {
    const dps = damageTotal(weapon.damagePerSecond) * powered;
    return {
      dps,
      sustainedDps: dps * ratio,
      alpha: 0,
      type: dominantType(weapon.damagePerSecond),
      missile: false,
      armed: damageTotal(weapon.damagePerSecond) > 0,
    };
  }

  const perShot = damageTotal(weapon.damagePerShot);
  const dps = weapon.fireRate ? perShot * shotsPerSecond(weapon) * powered : 0;

  return {
    dps,
    sustainedDps: dps * ratio,
    alpha: perShot * (weapon.pelletsPerShot || 1) * powered,
    type: dominantType(weapon.damagePerShot),
    missile: false,
    armed: perShot > 0 && !!weapon.fireRate,
  };
}

interface FoundGun {
  hardpoint: Hardpoint;
  mount?: Hardpoint;
}

// The same children the combat card walks, so the stations add up to its
// totals.
const children = (hardpoint: Hardpoint) => hardpoint.hardpoints || [];

// Every gun under a slot, with the mount it sits on. A mining laser's damage is
// what it does to a rock and is left out, as the combat card leaves it out.
function findGuns(hardpoints: Hardpoint[], mount?: Hardpoint): FoundGun[] {
  return hardpoints.flatMap((hardpoint) => {
    const weapon = hardpoint.component?.typeData as ComponentWeapon | undefined;

    if (hardpoint.category === HardpointCategoryEnum.WEAPONS && weapon) {
      return weapon.mining ? [] : [{ hardpoint, mount }];
    }

    const nextMount =
      hardpoint.category === HardpointCategoryEnum.WEAPON_MOUNTS
        ? hardpoint
        : mount;

    return findGuns(children(hardpoint), nextMount);
  });
}

function stackGuns(
  found: FoundGun[],
  powerRatio: number,
  modifier: WeaponRegenModifier,
): GunStack[] {
  const stacks = new Map<string, GunStack>();

  for (const { hardpoint, mount } of found) {
    const component = hardpoint.component!;
    // By name and size rather than id: the files carry one part under several
    // records, and two of the same rack would otherwise never stack.
    const key = [component.name, component.size, mount?.component?.name].join(
      "|",
    );
    const existing = stacks.get(key);

    if (existing) {
      existing.count += 1;
      existing.hardpoints.push(hardpoint);
      continue;
    }

    stacks.set(key, {
      key,
      name: component.name,
      size: component.size,
      manufacturer: component.manufacturer?.name,
      mount: mount?.component?.name,
      count: 1,
      weapon: component.typeData as ComponentWeapon,
      hardpoint,
      hardpoints: [hardpoint],
      ...gunFigures(
        component.typeData as ComponentWeapon,
        powerRatio,
        modifier,
      ),
    });
  }

  return [...stacks.values()].sort((a, b) => b.dps - a.dps);
}

const sum = (guns: GunStack[], pick: (gun: GunStack) => number) =>
  guns.reduce((total, gun) => total + pick(gun) * gun.count, 0);

// Two turrets of the same model can point different ways: one covers the
// belly, one the dorsal arc. Only turrets with the same aim limits collapse.
const partKey = (part?: Hardpoint) => {
  if (!part?.component) return "";

  const turret = part.component.typeData as ComponentTurret | undefined;

  return [
    part.component.name,
    part.component.size,
    turret?.minYaw,
    turret?.maxYaw,
    turret?.minPitch,
    turret?.maxPitch,
  ].join("|");
};

function buildStation(
  kind: StationKind,
  guns: GunStack[],
  part?: Hardpoint,
): Station {
  const signature = guns.map((gun) => `${gun.key}x${gun.count}`).join(",");

  return {
    key: [kind, partKey(part), signature].join("|"),
    kind,
    part,
    count: 1,
    parts: part ? [part] : [],
    positions: [slotPosition(part?.name)].filter(
      (position): position is SlotPosition => !!position,
    ),
    guns,
    dps: sum(guns, (gun) => gun.dps),
    sustainedDps: sum(guns, (gun) => gun.sustainedDps),
    missileDamage: sum(guns, (gun) => (gun.missile ? gun.alpha : 0)),
  };
}

const turretKind = (turret: Hardpoint, guns: GunStack[]): StationKind => {
  if (!guns.some((gun) => gun.armed)) return "utility";

  return (
    (turret.component?.typeData as ComponentTurret | undefined)?.control ??
    ComponentTurretControlEnum.REMOTE
  );
};

const KIND_ORDER: StationKind[] = [
  "pilot",
  ComponentTurretControlEnum.MANNED,
  ComponentTurretControlEnum.REMOTE,
  ComponentTurretControlEnum.PDS,
  "missiles",
  "utility",
];

// The ship's weapons grouped by who fires them. A turret's tree (turret, mount,
// gun) becomes one station whose guns name their mount, instead of three rows
// nested in one another. The pilot's guns, however many slots they sit in, are
// one station; identical turrets and racks collapse into one with a count.
export function weaponStations(
  hardpoints: Hardpoint[] | undefined,
  powerRatio = 1,
  modifier: WeaponRegenModifier = NO_REGEN_MODIFIER,
): Station[] {
  const pilotGuns: FoundGun[] = [];
  const stations: Station[] = [];

  // Turrets and racks can sit inside other parts (a module, a nose section),
  // so everything that is neither is searched for them.
  const visit = (list: Hardpoint[]) => {
    for (const hardpoint of list) {
      // A remote turret can sit in a weapon-mount slot; naming its operator is
      // what makes it a turret rather than the pilot's gimbal.
      const turret =
        hardpoint.category === HardpointCategoryEnum.TURRET ||
        (hardpoint.category === HardpointCategoryEnum.WEAPON_MOUNTS &&
          !!(hardpoint.component?.typeData as ComponentTurret | undefined)
            ?.control);

      if (turret) {
        const guns = stackGuns(
          findGuns(children(hardpoint)),
          powerRatio,
          modifier,
        );
        if (guns.length) {
          stations.push(
            buildStation(turretKind(hardpoint, guns), guns, hardpoint),
          );
        }
        continue;
      }

      switch (hardpoint.category) {
        case HardpointCategoryEnum.MISSILE_RACKS:
        case HardpointCategoryEnum.BOMBCOMPARTMENTS: {
          const guns = stackGuns(
            findGuns(children(hardpoint)),
            powerRatio,
            modifier,
          );
          if (guns.length) {
            stations.push(buildStation("missiles", guns, hardpoint));
          }
          break;
        }
        case HardpointCategoryEnum.WEAPONS:
        case HardpointCategoryEnum.WEAPON_MOUNTS:
          pilotGuns.push(...findGuns([hardpoint]));
          break;
        default:
          visit(children(hardpoint));
      }
    }
  };

  visit(hardpoints || []);

  // A tractor beam or a scanner in a gun slot does no damage: it belongs with
  // the tools, not in the pilot's firepower.
  const pilotStack = stackGuns(pilotGuns, powerRatio, modifier).filter(
    (gun) => gun.armed || gun.missile,
  );
  if (pilotStack.length) {
    stations.unshift(buildStation("pilot", pilotStack));
  }

  const collapsed = new Map<string, Station>();
  for (const station of stations) {
    const existing = collapsed.get(station.key);
    if (existing) {
      existing.count += 1;
      existing.positions = [...existing.positions, ...station.positions];
      existing.parts = [...existing.parts, ...station.parts];
      existing.guns = existing.guns.map((gun, index) => ({
        ...gun,
        hardpoints: [...gun.hardpoints, ...station.guns[index].hardpoints],
      }));
    } else {
      collapsed.set(station.key, { ...station });
    }
  }

  return [...collapsed.values()].sort(
    (a, b) =>
      KIND_ORDER.indexOf(a.kind) - KIND_ORDER.indexOf(b.kind) || b.dps - a.dps,
  );
}
