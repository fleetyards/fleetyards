import { computed, inject, toValue, type MaybeRefOrGetter } from "vue";
import {
  type ComponentWeaponDamage,
  HardpointCategoryEnum,
  type Hardpoint,
  type ComponentWeapon,
  type ComponentShield,
  type ComponentCooler,
  type ComponentPowerPlant,
  type ComponentQuantumDrive,
  type ComponentJumpDrive,
  type ComponentThruster,
  type ComponentArmor,
  type ComponentTractorBeam,
  type ComponentTurret,
  type ComponentMissile,
  type ComponentBomb,
  type ComponentMissileRack,
  ComponentTypeEnum,
  type ComponentMiningLaser,
  type ComponentMiningModifiers,
  type ComponentMiningModule,
  type ComponentSalvageModifier,
  type ComponentController,
  type ComponentEmp,
  type ComponentLifeSupport,
  type ComponentPowerRanges,
  type ComponentShieldController,
  type ComponentMissileController,
  ComponentShieldFaceTypeEnum,
} from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";
import { sustainedRatio } from "@/frontend/composables/useLoadoutStats";
import { criticalSize } from "@/frontend/composables/powerSim";
import {
  powerPlantContextKey,
  powerPlantPips,
} from "@/frontend/components/Models/Hardpoints/powerPlant";

// The contact groups a radar's sensitivity modifier can name that have a
// label; any other shows the game's own name.
const RADAR_CONTACT_GROUPS = ["GroundVehicle"];

interface PoweredTypeData {
  powerConsumption?: number;
  powerMinimumFraction?: number;
  powerRanges?: ComponentPowerRanges;
  signatureEm?: number;
  signatureIr?: number;
}

export type HardpointStat = {
  label: string;
  value: string;
  wide?: boolean;
  primary?: boolean;
  // Figures that describe one mode of the item rather than the item itself --
  // a quantum drive's spline jump -- which a detail page gives a card of their
  // own. A row lists them with the rest; their labels already name the mode.
  group?: string;
  // The `labels.hardpoint` key the label was translated from.
  key?: string;
  // Position on a ship page's hardpoint row; unset when only the stats card
  // shows the figure.
  row?: number;
};

const ROW_STATS = {
  gun: [
    "weapons.burstDps",
    "weapons.fireRate",
    "weapons.speed",
    "weapons.range",
    "weapons.fullDamageRange",
    "weapons.zeroDamageRange",
  ],
  miningLaser: ["mining.fracturePower", "mining.range", "mining.moduleSlots"],
  missile: [
    "missiles.lockTime",
    "missiles.trackingSignal",
    "missiles.speed",
    "missiles.range",
  ],
  bomb: ["missiles.blastRadius", "missiles.armTime"],
  shield: [
    "shields.regenTime",
    "shields.downedRegenDelay",
    "shields.damagedRegenDelay",
  ],
  cooler: ["powerConsumption", "signatureIr"],
  powerPlant: ["powerPlants.pips", "signatureEm"],
  flightController: [
    "flightControllers.boostSpeed",
    "flightControllers.navSpeed",
    "flightControllers.rotation",
  ],
  quantumDrive: [
    "quantumDrives.range",
    "quantumDrives.fuelConsumption",
    "quantumDrives.spoolUpTime",
    "quantumDrives.cooldownTime",
  ],
  jumpDrive: [
    "jumpDrives.exitSpeed",
    "jumpDrives.maxTunnelSpeed",
    "jumpDrives.respoolTime",
  ],
  radar: ["radar.ir", "radar.em", "radar.cs"],
  turret: ["turrets.yawRange", "turrets.pitchRange", "turrets.gunPorts"],
  countermeasure: ["countermeasureStats.duration", "weapons.fireRate"],
  armor: ["armor.physical", "armor.energy", "armor.distortion"],
  quantumEnforcement: [
    "quantumEnforcement.jammerRange",
    "quantumEnforcement.pulseRadius",
    "quantumEnforcement.chargeTime",
    "quantumEnforcement.cooldownTime",
  ],
  emp: ["emp.radius", "emp.chargeTime", "emp.cooldownTime"],
  tractorBeam: ["tractorBeams.range", "tractorBeams.towForce"],
} as const;

// Ordered, human-readable stats for a hardpoint's mounted component, most
// important first. Shared by the inline row summary (first couple) and the
// expandable details grid (all of them).
// Keeps hundredths (0.75/s) where the one-decimal stat format rounds, and
// groups thousands with a narrow no-break space as that format does.
export const formatBoostFigure = (
  value: number | undefined,
  separator: string,
): string => {
  const rounded = Math.round((value || 0) * 100) / 100;
  const [integer, decimal] = String(rounded).split(".");
  const grouped = integer.replace(/\B(?=(\d{3})+(?!\d))/g, "\u202F");

  return decimal ? `${grouped}${separator || ","}${decimal}` : grouped;
};

const THRUSTER_CATEGORIES: HardpointCategoryEnum[] = [
  HardpointCategoryEnum.MAIN_THRUSTERS,
  HardpointCategoryEnum.MANEUVERING_THRUSTERS,
  HardpointCategoryEnum.RETRO_THRUSTERS,
  HardpointCategoryEnum.VTOL_THRUSTERS,
];

export const useHardpointStats = (
  hardpoint: MaybeRefOrGetter<Hardpoint | undefined>,
  count?: MaybeRefOrGetter<number>,
) => {
  const { t, toNumber } = useI18n();

  // Ship-level quantum fuel capacity (SCU), provided by the hardpoints page.
  // Used to derive the quantum-drive's max jump range.
  const quantumFuelTankSize = inject<MaybeRefOrGetter<number | undefined>>(
    "quantumFuelTankSize",
    undefined,
  );

  // Ship-wide weapon-power throttle (< 1 when the shared pool can't feed every
  // gun), provided by the hardpoints page so per-weapon sustained DPS matches
  // the Combat card's total.
  const weaponPowerRatio = inject<MaybeRefOrGetter<number | undefined>>(
    "weaponPowerRatio",
    undefined,
  );

  // Ship-level power-plant context (plant count + size sum), provided by the
  // power-plant Category, so each plant can show its own pip share.
  const powerPlantContext = inject(powerPlantContextKey, undefined);

  // `integer`, not a unit format, wherever the label already names the unit
  // ("Sustained DPS", "HP", "Cooling Rate", "Output", "Pips"): every consumer
  // renders `label` beside `value`, so a unit format there prints it twice.
  const stat = (
    labelKey: string,
    value: number,
    format: string,
    primary = false,
  ): HardpointStat => ({
    key: labelKey,
    label: t(`labels.hardpoint.${labelKey}`),
    value: String(toNumber(Math.round(value), format)),
    primary,
  });

  // One decimal, not rounded to a whole second: spool, cooldown and
  // interdiction times are tenths (7.3 s, 2.6 s).
  const secondsStat = (labelKey: string, value: number): HardpointStat => ({
    key: labelKey,
    label: t(`labels.hardpoint.${labelKey}`),
    value: String(toNumber(value, "seconds")),
  });

  // For figures the one-decimal stat format would misstate -- a 0.25 km/s²
  // first stage, a 0.05/s air output, a 4.55 s shield delay. Zero stays a zero
  // rather than "not available", and thousands are grouped the way `toNumber`
  // groups them.
  const precise = (value: number, digits = 3): string => {
    const rounded = Math.round(value * 10 ** digits) / 10 ** digits;
    const [integer, decimal] = String(Math.abs(rounded)).split(".");
    const grouped = integer.replace(/\B(?=(\d{3})+(?!\d))/g, "\u202F");
    const sign = rounded < 0 ? "-" : "";

    return decimal
      ? `${sign}${grouped}${t("number.format.separator") || ","}${decimal}`
      : `${sign}${grouped}`;
  };

  // Shield delays run to hundredths (4.55 s), which `secondsStat` rounds.
  const delayStat = (labelKey: string, value: number): HardpointStat => ({
    key: labelKey,
    label: t(`labels.hardpoint.${labelKey}`),
    value: `${precise(value, 2)} s`,
  });

  const splineAccel = (stageOne: number, stageTwo: number) =>
    `${precise(stageOne / 1000)} / ${precise(stageTwo / 1000)} km/s²`;

  const resistanceStat = (labelKey: string, value: number): HardpointStat => ({
    key: labelKey,
    label: t(`labels.hardpoint.${labelKey}`),
    value: `${Math.round(value * 100)}%`,
  });

  // A symmetric range reads as "±80°", a full turn as "360°", anything else
  // as its two ends.
  const turretRange = (
    min?: number,
    max?: number,
    vary?: boolean,
  ): string | null => {
    if (typeof min !== "number" || typeof max !== "number") return null;

    const low = Math.round(min);
    const high = Math.round(max);
    let range = `${low}° / ${high}°`;
    if (high - low >= 360) {
      range = "360°";
    } else if (low === -high) {
      range = `±${high}°`;
    }

    return vary
      ? `${range} (${t("labels.hardpoint.turrets.limitsVary")})`
      : range;
  };

  // Spread runs to thousandths of a degree, which the one-decimal stat
  // format would round away. Written with the app's own decimal separator,
  // as every other figure is.
  const degrees = (value: number): string => {
    const rounded = String(Math.round(value * 1000) / 1000);
    return `${rounded.replace(".", t("number.format.separator") || ",")}°`;
  };

  // What one magazine delivers before a reload: only for guns fed from a
  // magazine, since an energy weapon's pool refills while it fires.
  const magazineTotals = (
    weapon: ComponentWeapon,
  ): { damage: number; seconds: number } | null => {
    if (!weapon.maxAmmo || weapon.regen?.maxAmmoLoad || !weapon.fireRate) {
      return null;
    }

    const perShot = Object.values(weapon.damagePerShot || {}).reduce(
      (sum: number, val) => sum + (typeof val === "number" ? val : 0),
      0,
    );
    const shots = Math.floor(weapon.maxAmmo / (weapon.ammoCost || 1));
    if (!perShot || !shots) return null;

    return {
      damage: shots * perShot * (weapon.pelletsPerShot || 1),
      seconds: shots / (weapon.fireRate / 60),
    };
  };

  // A percent change, signed the way the game prints one: "+40%", "-35%".
  const signedPercent = (value: number): string =>
    `${value > 0 ? "+" : ""}${String(toNumber(value, "percent"))}`;

  const MINING_MODIFIER_KEYS: (keyof ComponentMiningModifiers)[] = [
    "instability",
    "resistance",
    "optimalChargeWindow",
    "optimalChargeRate",
    "catastrophicChargeRate",
    "shatterDamage",
    "inertMaterials",
  ];

  const pushMiningModifiers = (
    result: HardpointStat[],
    modifiers?: ComponentMiningModifiers,
  ) => {
    if (!modifiers) return;

    for (const key of MINING_MODIFIER_KEYS) {
      const value = modifiers[key];
      if (typeof value === "number" && value !== 0) {
        result.push({
          key: `mining.modifiers.${key}`,
          label: t(`labels.hardpoint.mining.modifiers.${key}`),
          value: signedPercent(value),
        });
      }
    }
  };

  // A mining laser's beam damage is what it does to a rock, not to a ship, so
  // it reads as the laser's power range rather than as DPS.
  const pushMiningLaser = (
    result: HardpointStat[],
    mining: ComponentMiningLaser,
  ) => {
    const { fracturePowerMin: min, fracturePowerMax: max } = mining;
    if (typeof max === "number") {
      result.push({
        key: "mining.fracturePower",
        label: t("labels.hardpoint.mining.fracturePower"),
        value:
          typeof min === "number" && min < max
            ? `${String(toNumber(Math.round(min), "integer"))} - ${String(toNumber(Math.round(max), "integer"))}`
            : String(toNumber(Math.round(max), "integer")),
        primary: true,
      });
    }
    if (mining.extractionPower) {
      result.push(
        stat("mining.extractionPower", mining.extractionPower, "integer", true),
      );
    }
    if (mining.maxRange) {
      result.push({
        key: "mining.range",
        label: t("labels.hardpoint.mining.range"),
        value: mining.optimalRange
          ? `${String(toNumber(mining.optimalRange))} - ${String(toNumber(mining.maxRange, "weaponRange"))}`
          : String(toNumber(mining.maxRange, "weaponRange")),
      });
    }
    if (mining.moduleSlots) {
      result.push(stat("mining.moduleSlots", mining.moduleSlots, "integer"));
    }
    if (mining.chargeUpTime || mining.chargeDownTime) {
      result.push({
        key: "mining.chargeTime",
        label: t("labels.hardpoint.mining.chargeTime"),
        // `toNumber` reads 0 as "not available", and an instant charge is 0 s.
        value: `${mining.chargeUpTime ? String(toNumber(mining.chargeUpTime)) : "0"} / ${mining.chargeDownTime ? String(toNumber(mining.chargeDownTime, "seconds")) : "0 s"}`,
      });
    }
    pushMiningModifiers(result, mining.modifiers);
  };

  const pushMiningModule = (
    result: HardpointStat[],
    miningModule: ComponentMiningModule,
  ) => {
    result.push({
      key: "mining.activation",
      label: t("labels.hardpoint.mining.activation"),
      value: t(`labels.hardpoint.mining.${miningModule.activation}`),
      primary: true,
    });
    if (typeof miningModule.fracturePower === "number") {
      result.push({
        key: "mining.fracturePower",
        label: t("labels.hardpoint.mining.fracturePower"),
        value: signedPercent(miningModule.fracturePower),
        primary: true,
      });
    }
    if (typeof miningModule.extractionPower === "number") {
      result.push({
        key: "mining.extractionPower",
        label: t("labels.hardpoint.mining.extractionPower"),
        value: signedPercent(miningModule.extractionPower),
      });
    }
    if (miningModule.charges) {
      result.push(stat("mining.charges", miningModule.charges, "integer"));
    }
    if (miningModule.duration) {
      result.push({
        key: "mining.duration",
        label: t("labels.hardpoint.mining.duration"),
        value: String(toNumber(miningModule.duration, "seconds")),
      });
    }
    pushMiningModifiers(result, miningModule.modifiers);
  };

  // Multipliers on the head's scraping beam; efficiency is the share of what
  // is scraped that ends up as material, so it reads as a percentage.
  const pushSalvageModifier = (
    result: HardpointStat[],
    salvage: ComponentSalvageModifier,
  ) => {
    const multiplier = (labelKey: string, value?: number) => {
      if (typeof value !== "number") return;

      result.push({
        key: `salvage.${labelKey}`,
        label: t(`labels.hardpoint.salvage.${labelKey}`),
        value: `${String(toNumber(value))}×`,
        primary: labelKey === "salvageSpeed",
      });
    };

    multiplier("salvageSpeed", salvage.salvageSpeed);
    multiplier("radius", salvage.radius);
    if (typeof salvage.extractionEfficiency === "number") {
      result.push({
        key: "salvage.extractionEfficiency",
        label: t("labels.hardpoint.salvage.extractionEfficiency"),
        value: `${Math.round(salvage.extractionEfficiency * 100)}%`,
      });
    }
  };

  // Boost regen runs to hundredths (0.75/s), which the one-decimal stat
  // format would round to 0.8.
  const boostFigure = (value?: number): string =>
    formatBoostFigure(value, t("number.format.separator"));

  // A mount's own gun slots, by size: "2 × S3". Only the slots a gun or a
  // gimbal plugs into count -- a turret's seat or camera does not.
  const gunPorts = (ports?: Hardpoint[]): string | null => {
    const bySize = new Map<number, number>();
    (ports ?? []).forEach((port) => {
      if (
        port.category !== HardpointCategoryEnum.WEAPONS &&
        port.category !== HardpointCategoryEnum.WEAPON_MOUNTS
      ) {
        return;
      }
      const size = port.maxSize ?? port.minSize;
      if (typeof size !== "number") return;

      bySize.set(size, (bySize.get(size) ?? 0) + 1);
    });
    if (!bySize.size) return null;

    return [...bySize.entries()]
      .sort(([a], [b]) => b - a)
      .map(([size, total]) => `${total} × S${size}`)
      .join(" + ");
  };

  // What every powered item draws and gives off, on the row as well as the
  // page. The draw reads as the range the power allocator can set it to:
  // from its minimum share up to the full draw.
  const poweredStats = (
    data: PoweredTypeData,
    category?: HardpointCategoryEnum,
  ): HardpointStat[] => {
    const powered: HardpointStat[] = [];

    // A thruster takes no pips: the ship's Engine group draws through the
    // flight controller, so a thruster's own figure is no allocatable segment.
    const allocatable = !category || !THRUSTER_CATEGORIES.includes(category);

    if (
      allocatable &&
      typeof data.powerConsumption === "number" &&
      data.powerConsumption
    ) {
      const full = data.powerConsumption;
      // The block the power allocator always keeps powered, as it sizes it.
      const minimum = criticalSize(full, data.powerMinimumFraction);
      powered.push({
        key: "powerConsumption",
        label: t("labels.hardpoint.powerConsumption"),
        value:
          minimum < full
            ? `${precise(minimum)} – ${String(toNumber(full))} ${t("labels.hardpoint.powerSegments")}`
            : `${String(toNumber(full))} ${t("labels.hardpoint.powerSegments")}`,
      });
    }
    if (typeof data.signatureEm === "number" && data.signatureEm) {
      powered.push({
        key: "signatureEm",
        label: t("labels.hardpoint.signatureEm"),
        value: String(toNumber(data.signatureEm, "integer")),
      });
    }
    if (typeof data.signatureIr === "number" && data.signatureIr) {
      powered.push({
        key: "signatureIr",
        label: t("labels.hardpoint.signatureIr"),
        value: String(toNumber(data.signatureIr, "integer")),
      });
    }

    return powered;
  };

  // Angles and multipliers run to hundredths, which the one-decimal stat
  // format would round away; written with the app's decimal separator.
  const preciseNumber = (value: number): string =>
    String(Math.round(value * 100) / 100).replace(
      ".",
      t("number.format.separator") || ",",
    );

  // A signature that fades from launch to burn-out reads as its two ends.
  const signatureRange = (range?: {
    start?: number;
    end?: number;
  }): string | null => {
    // A missing end is unknown, not zero: only the end the data gives is shown.
    const start = range?.start ?? range?.end;
    const end = range?.end ?? range?.start;
    if (!start && !end) return null;

    // A cloud that fades to nothing ends at a real 0, which `toNumber`
    // would print as not available.
    const format = (value?: number) => {
      const rounded = Math.round(value || 0);
      return rounded ? String(toNumber(rounded, "integer")) : "0";
    };

    return start === end ? format(start) : `${format(start)} → ${format(end)}`;
  };

  const projectileBurstDps = (weapon: ComponentWeapon): number | null => {
    if (!weapon.fireRate || !weapon.damagePerShot) return null;

    const damage = Object.values(weapon.damagePerShot).reduce(
      (sum: number, val) => sum + (typeof val === "number" ? val : 0),
      0,
    );
    if (!damage) return null;

    const pellets = weapon.pelletsPerShot || 1;
    return (damage * pellets * weapon.fireRate) / 60;
  };

  const addDamageBreakdown = (
    result: HardpointStat[],
    damage: ComponentWeaponDamage,
  ) => {
    const types: [keyof ComponentWeaponDamage, string][] = [
      ["physical", "weapons.damagePhysical"],
      ["energy", "weapons.damageEnergy"],
      ["distortion", "weapons.damageDistortion"],
      ["thermal", "weapons.damageThermal"],
    ];
    for (const [key, labelKey] of types) {
      const val = damage[key];
      if (typeof val === "number" && val > 0) {
        result.push(stat(labelKey, val, "damage"));
      }
    }
  };

  // `stat` rounds to a whole number, which turns a 1.5 s arm time into 2;
  // this keeps the one decimal `toNumber` itself allows.
  const decimalStat = (
    labelKey: string,
    value: number,
    format: string,
  ): HardpointStat => ({
    key: labelKey,
    label: t(`labels.hardpoint.${labelKey}`),
    value: String(toNumber(value, format)),
  });

  // One figure when both ends agree, which most blast radii do. Compared at
  // the one decimal `toNumber` shows, so two ends that print alike read as one.
  const span = (
    min: number | undefined,
    max: number | undefined,
    format: string,
  ) => {
    const low = Math.round((min ?? max ?? 0) * 10) / 10;
    const high = Math.round((max ?? min ?? 0) * 10) / 10;
    if (low === high) return String(toNumber(high, format));

    return `${String(toNumber(low, format))} - ${String(toNumber(high, format))}`;
  };

  return computed<HardpointStat[]>(() => {
    const hp = toValue(hardpoint);
    const typeData = hp?.component?.typeData;
    if (!hp || !typeData) return [];

    const category = hp.category;
    const result: HardpointStat[] = [];
    // The figures a ship page's row shows, in order; the stats card lists
    // the rest. A category without a list shows its own figures, but not the
    // power and signature figures every powered item carries.
    let rowKeys: readonly string[] | undefined;

    // Lead with total payload damage as the key metric; only spell out the
    // per-type split when the warhead actually mixes damage types.
    const pushOrdnanceDamage = (damage?: ComponentWeaponDamage) => {
      if (!damage) return;

      const entries = Object.entries(damage).filter(
        ([, value]) => typeof value === "number" && value > 0,
      );
      const total = entries.reduce(
        (sum, [, value]) => sum + (value as number),
        0,
      );
      if (total) {
        result.push(stat("missiles.damage", total, "damage", true));
      }
      if (entries.length > 1) {
        addDamageBreakdown(result, damage);
      }
    };

    const pushFuse = (ordnance: ComponentMissile | ComponentBomb) => {
      if (ordnance.blastRadiusMin || ordnance.blastRadiusMax) {
        result.push({
          key: "missiles.blastRadius",
          label: t("labels.hardpoint.missiles.blastRadius"),
          value: span(
            ordnance.blastRadiusMin,
            ordnance.blastRadiusMax,
            "distance",
          ),
        });
      }
      if (ordnance.armTime) {
        result.push(
          decimalStat("missiles.armTime", ordnance.armTime, "seconds"),
        );
      }
      if (ordnance.safetyDistance) {
        result.push(
          stat("missiles.safetyDistance", ordnance.safetyDistance, "distance"),
        );
      }
    };

    // Tractor and towing beams mount in the weapons category but share none of a
    // gun's stats, so the parsed `tractorBeam` flag is the signal to use — the
    // game files even type some of them as SalvageHead.
    if ("tractorBeam" in typeData) {
      rowKeys = ROW_STATS.tractorBeam;
      const tractor = typeData as ComponentTractorBeam;
      const towing = tractor.towing;
      // Beams pull together, so the force figures sum across a collapsed stack
      // (like weapon DPS does). Reach, cone, tether and handling are per-beam
      // ratings and stay as they are.
      const stackCount = Math.max(1, Math.round(Number(toValue(count) ?? 1)));

      // Reach reads as the falloff span erkul shows (its "75 → 150 m"): full
      // force out to `fullStrengthDistance`, then fading to nothing at
      // `maxDistance`. `minDistance` is not part of it — that is the 0.5 m every
      // beam grabs from. Beams with no falloff point just show their max.
      const rangeStat = (
        labelKey: string,
        fullStrength: number | undefined,
        max: number,
      ): HardpointStat => ({
        key: labelKey,
        label: t(`labels.hardpoint.${labelKey}`),
        value: fullStrength
          ? `${String(toNumber(fullStrength))} - ${String(toNumber(max, "weaponRange"))}`
          : String(toNumber(max, "weaponRange")),
      });

      // A towing beam's own maxForce is a 5e9 "unlimited" sentinel, so its tow
      // force is the figure that actually describes it (erkul does the same).
      if (towing?.towingForce) {
        result.push(
          stat(
            "tractorBeams.towForce",
            towing.towingForce * stackCount,
            "newton",
            true,
          ),
        );
      } else if (tractor.maxForce) {
        result.push(
          stat(
            "tractorBeams.maxForce",
            tractor.maxForce * stackCount,
            "newton",
            true,
          ),
        );
      }
      if (tractor.maxDistance) {
        result.push(
          rangeStat(
            "tractorBeams.range",
            tractor.fullStrengthDistance,
            tractor.maxDistance,
          ),
        );
      }
      if (tractor.maxAngle) {
        result.push(stat("tractorBeams.cone", tractor.maxAngle, "degrees"));
      }
      if (tractor.minForce) {
        result.push(stat("tractorBeams.minForce", tractor.minForce, "newton"));
      }
      // Cargo mode swaps in far stronger overrides for hauling boxes.
      if (tractor.cargoMode?.maxForce) {
        result.push(
          stat(
            "tractorBeams.cargoForce",
            tractor.cargoMode.maxForce * stackCount,
            "newton",
          ),
        );
      }
      if (tractor.cargoMode?.maxDistance) {
        result.push(
          rangeStat(
            "tractorBeams.cargoRange",
            tractor.cargoMode.fullStrengthDistance,
            tractor.cargoMode.maxDistance,
          ),
        );
      }
      if (towing?.towingMaxDistance) {
        result.push(
          stat(
            "tractorBeams.towDistance",
            towing.towingMaxDistance,
            "weaponRange",
          ),
        );
      }
      if (towing?.quantumTowMassLimit) {
        result.push(
          stat(
            "tractorBeams.quantumTowMass",
            towing.quantumTowMassLimit,
            "weight",
          ),
        );
      }
      if (tractor.tetherBreakTime) {
        result.push({
          key: "tractorBeams.tetherBreak",
          label: t("labels.hardpoint.tractorBeams.tetherBreak"),
          value: String(toNumber(tractor.tetherBreakTime, "seconds")),
        });
      }
      if (tractor.rotation?.maxAngularVelocity) {
        result.push(
          stat(
            "tractorBeams.rotationSpeed",
            tractor.rotation.maxAngularVelocity,
            "rotation",
          ),
        );
      }
      if (tractor.movement?.maxSpeed) {
        result.push(
          stat("tractorBeams.moveSpeed", tractor.movement.maxSpeed, "speed"),
        );
      }
    } else if ("empRadius" in typeData) {
      rowKeys = ROW_STATS.emp;
      // An EMP sits in a weapons slot but fires a charged burst, not rounds.
      const emp = typeData as ComponentEmp;

      if (emp.distortionDamage) {
        result.push(
          stat("emp.distortionDamage", emp.distortionDamage, "damage", true),
        );
      }
      if (emp.empRadius) {
        result.push({
          key: "emp.radius",
          label: t("labels.hardpoint.emp.radius"),
          value: emp.minEmpRadius
            ? `${String(toNumber(emp.minEmpRadius, "integer"))} – ${String(toNumber(emp.empRadius, "integer"))} m`
            : `${String(toNumber(emp.empRadius, "integer"))} m`,
        });
      }
      if (emp.chargeTime) {
        result.push(secondsStat("emp.chargeTime", emp.chargeTime));
      }
      if (emp.unleashTime) {
        result.push(secondsStat("emp.unleashTime", emp.unleashTime));
      }
      if (emp.cooldownTime) {
        result.push(secondsStat("emp.cooldownTime", emp.cooldownTime));
      }
    } else if (category === HardpointCategoryEnum.WEAPONS) {
      const weapon = typeData as ComponentWeapon;
      rowKeys = ROW_STATS.gun;
      // A missile or bomb is told apart by its type first; a field of its
      // own is the fallback for a payload that does not say.
      const componentType = hp.component?.type;
      // Sustainable-fire fraction (erkul's "efficiency"): the duty-cycle share
      // of burst the weapon can hold. Only meaningful when < 100%.
      const efficiency = sustainedRatio(
        weapon,
        Number(toValue(weaponPowerRatio) ?? 1),
      );
      // Stacked identical mounts collapse to one compact summary row, so the DPS
      // figures are summed across the stack (like erkul's `dps × count`). Other
      // stats (fire rate, range, …) stay per-weapon.
      const stackCount = Math.max(1, Math.round(Number(toValue(count) ?? 1)));
      // Lead with sustained DPS (like erkul), with burst and the efficiency
      // duty-cycle share alongside. A weapon with no throttle (efficiency 1)
      // sustains its full burst, so we just show the single burst figure.
      const pushDps = (burstValue: number) => {
        const burstTotal = burstValue * stackCount;
        if (efficiency < 1) {
          result.push(
            stat(
              "weapons.sustainedDps",
              burstTotal * efficiency,
              "integer",
              true,
            ),
          );
          // Key too, not a footnote. Sustained is what the gun does over a
          // fight and burst is what it does in the moment -- comparing two guns
          // means reading both, and a reader who only ever sees the derated
          // figure has no idea what they gave up for the duty cycle.
          result.push(stat("weapons.burstDps", burstTotal, "integer", true));
          result.push({
            key: "weapons.efficiency",
            label: t("labels.hardpoint.weapons.efficiency"),
            value: `${Math.round(efficiency * 100)}%`,
          });
        } else {
          result.push(stat("weapons.burstDps", burstTotal, "integer", true));
        }
      };

      if (weapon.mining) {
        rowKeys = ROW_STATS.miningLaser;
        pushMiningLaser(result, weapon.mining);
      } else if (weapon.beam) {
        if (weapon.damagePerSecond) {
          const dps = Object.values(weapon.damagePerSecond).reduce(
            (sum: number, val) => sum + (typeof val === "number" ? val : 0),
            0,
          );
          if (dps) {
            pushDps(dps);
          }
          addDamageBreakdown(result, weapon.damagePerSecond);
        }
        if (weapon.heatPerSecond) {
          result.push(
            stat("weapons.heatPerSecond", weapon.heatPerSecond, "integer"),
          );
        }
        if (weapon.fullDamageRange) {
          result.push(
            stat(
              "weapons.fullDamageRange",
              weapon.fullDamageRange,
              "weaponRange",
            ),
          );
        }
        if (weapon.zeroDamageRange) {
          result.push(
            stat(
              "weapons.zeroDamageRange",
              weapon.zeroDamageRange,
              "weaponRange",
            ),
          );
        }
      } else if (
        componentType === ComponentTypeEnum.MISSILE ||
        "trackingSignal" in typeData
      ) {
        const missile = typeData as ComponentMissile;
        rowKeys = ROW_STATS.missile;
        pushOrdnanceDamage(missile.damagePerShot);
        if (missile.speed) {
          result.push(stat("missiles.speed", missile.speed, "missileSpeed"));
        }
        if (missile.range) {
          result.push(stat("missiles.range", missile.range, "missileRange"));
        }
        if (missile.lockRangeMin || missile.lockRangeMax) {
          result.push({
            key: "missiles.lockRange",
            label: t("labels.hardpoint.missiles.lockRange"),
            value: `${String(toNumber(missile.lockRangeMin || 0, "missileRange"))} - ${String(toNumber(missile.lockRangeMax || 0, "missileRange"))}`,
          });
        }
        if (missile.lockTime) {
          result.push(stat("missiles.lockTime", missile.lockTime, "lockTime"));
        }
        if (missile.trackingSignal) {
          result.push({
            key: "missiles.trackingSignal",
            label: t("labels.hardpoint.missiles.trackingSignal"),
            value: String(missile.trackingSignal),
          });
        }
        if (missile.lockAngle) {
          result.push(stat("missiles.lockAngle", missile.lockAngle, "degrees"));
        }
        if (missile.signalResilienceMin || missile.signalResilienceMax) {
          result.push({
            key: "missiles.signalResilience",
            label: t("labels.hardpoint.missiles.signalResilience"),
            value: span(
              missile.signalResilienceMin,
              missile.signalResilienceMax,
              "integer",
            ),
          });
        }
        if (missile.boostPhaseDuration) {
          result.push(
            decimalStat(
              "missiles.boostPhase",
              missile.boostPhaseDuration,
              "seconds",
            ),
          );
        }
        if (missile.terminalPhaseTime) {
          result.push(
            decimalStat(
              "missiles.terminalPhase",
              missile.terminalPhaseTime,
              "seconds",
            ),
          );
        }
        if (missile.maxLifetime) {
          result.push(
            decimalStat("missiles.lifetime", missile.maxLifetime, "seconds"),
          );
        }
        if (missile.fuelTankSize) {
          result.push(stat("missiles.fuel", missile.fuelTankSize, "integer"));
        }
        if (typeof missile.dumbfire === "boolean") {
          result.push({
            key: "missiles.dumbfire",
            label: t("labels.hardpoint.missiles.dumbfire"),
            value: t(
              missile.dumbfire
                ? "labels.hardpoint.missiles.dumbfireAllowed"
                : "labels.hardpoint.missiles.dumbfireBlocked",
            ),
          });
        }
        pushFuse(missile);
      } else if (
        componentType === ComponentTypeEnum.BOMB ||
        "maxDropAngle" in typeData
      ) {
        const bomb = typeData as ComponentBomb;
        rowKeys = ROW_STATS.bomb;
        pushOrdnanceDamage(bomb.damagePerShot);
        if (bomb.maxDropAngle) {
          result.push(stat("bombs.maxDropAngle", bomb.maxDropAngle, "degrees"));
        }
        pushFuse(bomb);
      } else {
        const burstDps = projectileBurstDps(weapon);
        if (burstDps) {
          pushDps(burstDps);
        }
        if (weapon.penetration?.baseDistance) {
          result.push({
            key: "weapons.penetration",
            label: t("labels.hardpoint.weapons.penetration"),
            value: String(
              toNumber(weapon.penetration.baseDistance, "weaponRange"),
            ),
          });
        }
        if (weapon.maxAmmo) {
          result.push(stat("weapons.ammo", weapon.maxAmmo, "integer"));
        }
        const magazine = magazineTotals(weapon);
        if (magazine) {
          result.push(
            stat("weapons.magazineDamage", magazine.damage, "integer"),
            {
              key: "weapons.timeToEmpty",
              label: t("labels.hardpoint.weapons.timeToEmpty"),
              // Unrounded, and floored at the format's one decimal: a fast
              // gun with a small magazine empties in well under a second, and
              // a zero would read as "not available".
              value: String(
                toNumber(Math.max(magazine.seconds, 0.1), "seconds"),
              ),
            },
          );
        }
        if (weapon.fireRate) {
          result.push(stat("weapons.fireRate", weapon.fireRate, "rateOfFire"));
        }
        if (weapon.spread?.max) {
          const { min, max, firstAttack, attack, decay } = weapon.spread;
          result.push({
            key: "weapons.spread",
            label: t("labels.hardpoint.weapons.spread"),
            value:
              min != null && min !== max
                ? `${degrees(min)} / ${degrees(max)}`
                : degrees(max),
          });
          // A cone that is already at its widest has nothing left to grow into.
          const grows = min !== max;
          // The first shot opens the cone by its own amount; it is shown only
          // where it differs from what every shot after it adds.
          if (grows && firstAttack && firstAttack !== attack) {
            result.push({
              key: "weapons.spreadFirstShot",
              label: t("labels.hardpoint.weapons.spreadFirstShot"),
              value: degrees(firstAttack),
            });
          }
          if (grows && attack) {
            result.push({
              key: "weapons.spreadPerShot",
              label: t("labels.hardpoint.weapons.spreadPerShot"),
              value: degrees(attack),
            });
          }
          if (grows && decay) {
            result.push({
              key: "weapons.spreadRecovery",
              label: t("labels.hardpoint.weapons.spreadRecovery"),
              value: `${degrees(decay)}/s`,
            });
          }
        }
        const gimbalFireRate = weapon.gimbalMode?.fireRateMultiplier;
        if (weapon.fireRate && gimbalFireRate && gimbalFireRate !== 1) {
          result.push(
            stat(
              "weapons.gimbalFireRate",
              weapon.fireRate * gimbalFireRate,
              "rateOfFire",
            ),
          );
        }
        // A bound the record does not settle is unknown, not ×1, so only the
        // known ones are shown -- each marked with the end it applies to.
        const spreadMin = weapon.gimbalMode?.spreadMinMultiplier;
        const spreadMax = weapon.gimbalMode?.spreadMaxMultiplier;
        const spreadValue = (() => {
          if (spreadMin != null && spreadMax != null) {
            if (spreadMin === 1 && spreadMax === 1) return undefined;
            return spreadMin === spreadMax
              ? `×${preciseNumber(spreadMin)}`
              : `×${preciseNumber(spreadMin)} / ×${preciseNumber(spreadMax)}`;
          }
          if (spreadMin != null && spreadMin !== 1) {
            return `×${preciseNumber(spreadMin)} (${t("labels.hardpoint.weapons.spreadMin")})`;
          }
          if (spreadMax != null && spreadMax !== 1) {
            return `×${preciseNumber(spreadMax)} (${t("labels.hardpoint.weapons.spreadMax")})`;
          }
          return undefined;
        })();
        if (spreadValue) {
          result.push({
            key: "weapons.gimbalSpread",
            label: t("labels.hardpoint.weapons.gimbalSpread"),
            value: spreadValue,
          });
        }
        if (weapon.aimAssist?.nudgeAngle) {
          result.push({
            key: "weapons.aimAssist",
            label: t("labels.hardpoint.weapons.aimAssist"),
            value: `${preciseNumber(weapon.aimAssist.nudgeAngle)}°`,
          });
        }
        const assist = weapon.aimAssist;
        if (assist?.closeOuterAngle && assist.closeRangeMax) {
          const band =
            typeof assist.closeRangeMin === "number"
              ? `${preciseNumber(assist.closeRangeMin)}–${preciseNumber(assist.closeRangeMax)} m`
              : `≤ ${preciseNumber(assist.closeRangeMax)} m`;
          result.push({
            key: "weapons.closeAimAssist",
            label: t("labels.hardpoint.weapons.closeAimAssist"),
            value: `${preciseNumber(assist.closeOuterAngle)}° (${band})`,
          });
        }
        if (weapon.damagePerShot) {
          addDamageBreakdown(result, weapon.damagePerShot);
        }
        if (weapon.speed) {
          result.push(stat("weapons.speed", weapon.speed, "weaponSpeed"));
        }
        if (weapon.range) {
          result.push(stat("weapons.range", weapon.range, "weaponRange"));
        }
        if (weapon.heatPerShot) {
          result.push(
            stat("weapons.heatPerShot", weapon.heatPerShot, "integer"),
          );
        }
        if (weapon.regen?.maxAmmoLoad) {
          result.push(
            stat("weapons.pool", weapon.regen.maxAmmoLoad, "integer"),
          );
        }
        if (weapon.regen?.maxRegenPerSecond) {
          result.push(
            stat("weapons.maxRegen", weapon.regen.maxRegenPerSecond, "integer"),
          );
        }
        if (weapon.regen?.costPerBullet) {
          result.push(
            stat("weapons.costPerShot", weapon.regen.costPerBullet, "integer"),
          );
        }
      }
    } else if (
      category === HardpointCategoryEnum.MISSILE_RACKS ||
      category === HardpointCategoryEnum.BOMBCOMPARTMENTS
    ) {
      const rack = typeData as ComponentMissileRack;
      if (typeof rack.launchDelay === "number" && rack.launchDelay > 0) {
        result.push(
          stat(
            "missileRacks.launchDelay",
            rack.launchDelay * 1000,
            "milliseconds",
          ),
        );
      }
      if (typeof rack.igniteOnPylon === "boolean") {
        result.push({
          key: "missileRacks.ignition",
          label: t("labels.hardpoint.missileRacks.ignition"),
          value: t(
            rack.igniteOnPylon
              ? "labels.hardpoint.missileRacks.ignitesOnRack"
              : "labels.hardpoint.missileRacks.ignitesAfterRelease",
          ),
        });
      }
    } else if (category === HardpointCategoryEnum.SHIELDGENERATOR) {
      const shield = typeData as ComponentShield;
      rowKeys = ROW_STATS.shield;

      if (shield.maxHealth) {
        result.push(stat("shields.hp", shield.maxHealth, "integer", true));
      }
      if (shield.maxHealth && shield.maxRegen) {
        result.push(
          stat(
            "shields.regenTime",
            shield.maxHealth / shield.maxRegen,
            "regenTime",
          ),
        );
      }
      if (shield.downedRegenDelay) {
        result.push(
          delayStat("shields.downedRegenDelay", shield.downedRegenDelay),
        );
      }
      if (shield.damagedRegenDelay) {
        result.push(
          delayStat("shields.damagedRegenDelay", shield.damagedRegenDelay),
        );
      }
      if (shield.decayRatio) {
        result.push(resistanceStat("shields.decay", shield.decayRatio));
      }
      if (shield.resistance) {
        const res = shield.resistance as Record<
          string,
          { min?: number; max?: number }
        >;
        if (res.physical?.max) {
          result.push(
            resistanceStat("shields.resistancePhysical", res.physical.max),
          );
        }
        if (res.energy?.max) {
          result.push(
            resistanceStat("shields.resistanceEnergy", res.energy.max),
          );
        }
        if (res.distortion?.max) {
          result.push(
            resistanceStat("shields.resistanceDistortion", res.distortion.max),
          );
        }
      }
      // Absorption is how much of a hit the shield takes before it reaches
      // the hull, and it moves with the shield's health -- so a range.
      const absorption = shield.absorption as
        Record<string, { min?: number; max?: number }> | undefined;
      (["physical", "energy", "distortion"] as const).forEach((type) => {
        const range = absorption?.[type];
        if (typeof range?.max !== "number" || !range.max) return;

        const low = Math.round((range.min ?? range.max) * 100);
        const high = Math.round(range.max * 100);
        result.push({
          key: `shields.absorption.${type}`,
          label: t(`labels.hardpoint.shields.absorption.${type}`),
          value: low === high ? `${high}%` : `${low} – ${high}%`,
        });
      });
    } else if (category === HardpointCategoryEnum.COOLER) {
      const cooler = typeData as ComponentCooler;
      rowKeys = ROW_STATS.cooler;
      if (cooler.coolingRate) {
        result.push(
          stat("coolers.coolingRate", cooler.coolingRate, "integer", true),
        );
      }
    } else if (category === HardpointCategoryEnum.POWERPLANT) {
      const pp = typeData as ComponentPowerPlant;
      rowKeys = ROW_STATS.powerPlant;
      // Output is a per-plant rating, so it stays as-is even on a stacked row.
      // Pips are a ship-pool contribution, so they sum across the stack (the
      // total the category header used to show).
      const stackCount = Math.max(1, Math.round(Number(toValue(count) ?? 1)));
      if (pp.powerBase) {
        result.push(stat("powerPlants.output", pp.powerBase, "integer", true));
      }
      const context = toValue(powerPlantContext);
      const size = Number(hp.component?.size);
      if (pp.powerBase && context && size) {
        result.push(
          stat(
            "powerPlants.pips",
            powerPlantPips(pp.powerBase, size, context) * stackCount,
            "integer",
          ),
        );
      }
    } else if (
      category === HardpointCategoryEnum.CONTROLLER &&
      (typeData as ComponentController).scmSpeed
    ) {
      // Only a flight controller carries speeds; shield and missile
      // controllers share the category and have none of these.
      const flight = typeData as ComponentController;
      rowKeys = ROW_STATS.flightController;

      result.push(
        stat("flightControllers.scmSpeed", flight.scmSpeed!, "speed", true),
      );
      if (flight.scmSpeedBoosted) {
        result.push(
          stat("flightControllers.boostSpeed", flight.scmSpeedBoosted, "speed"),
        );
      }
      if (flight.maxSpeed) {
        result.push(
          stat("flightControllers.navSpeed", flight.maxSpeed, "speed"),
        );
      }

      // A fixed axis is a real 0 °/s, not a missing figure.
      const axes = (rotation?: typeof flight.angularVelocity) =>
        rotation && (rotation.pitch || rotation.yaw || rotation.roll)
          ? `${[rotation.pitch, rotation.yaw, rotation.roll]
              .map((value) =>
                Math.round(value || 0)
                  ? String(toNumber(Math.round(value || 0), "integer"))
                  : "0",
              )
              .join(" / ")} °/s`
          : null;
      const rotation = axes(flight.angularVelocity);
      if (rotation) {
        result.push({
          key: "flightControllers.rotation",
          label: t("labels.hardpoint.flightControllers.rotation"),
          value: rotation,
        });
      }
      const boostedRotation = axes(flight.boostedAngularVelocity);
      if (boostedRotation && boostedRotation !== rotation) {
        result.push({
          key: "flightControllers.boostedRotation",
          label: t("labels.hardpoint.flightControllers.boostedRotation"),
          value: boostedRotation,
        });
      }

      const capacitor = flight.boostCapacitor;
      if (capacitor?.capacity) {
        result.push({
          key: "flightControllers.boostCapacity",
          label: t("labels.hardpoint.flightControllers.boostCapacity"),
          value: boostFigure(capacitor.capacity),
        });
      }
      if (capacitor?.regenPerSecond) {
        result.push({
          key: "flightControllers.boostRegen",
          label: t("labels.hardpoint.flightControllers.boostRegen"),
          value: `${boostFigure(capacitor.regenPerSecond)}/s`,
        });
      }
      if (capacitor?.regenDelay) {
        result.push({
          key: "flightControllers.boostRegenDelay",
          label: t("labels.hardpoint.flightControllers.boostRegenDelay"),
          value: `${boostFigure(capacitor.regenDelay)} s`,
        });
      }
      if (capacitor?.rampUpTime || capacitor?.rampDownTime) {
        result.push({
          key: "flightControllers.boostRamp",
          label: t("labels.hardpoint.flightControllers.boostRamp"),
          value: `${boostFigure(capacitor.rampUpTime)} / ${boostFigure(capacitor.rampDownTime)} s`,
        });
      }
    } else if (category === HardpointCategoryEnum.QUANTUMDRIVE) {
      rowKeys = ROW_STATS.quantumDrive;
      const qd = typeData as ComponentQuantumDrive;

      if (qd.driveSpeed) {
        result.push(
          stat("quantumDrives.speed", qd.driveSpeed, "driveSpeed", true),
        );
      }
      // Max jump range on a full tank: quantum fuel (SCU) × 1000 / the drive's
      // per-Gm consumption. Matches erkul.games and spviewer.eu exactly.
      const quantumFuelTank = toValue(quantumFuelTankSize);
      if (qd.quantumFuelConsumption && quantumFuelTank) {
        result.push({
          key: "quantumDrives.range",
          label: t("labels.hardpoint.quantumDrives.range"),
          value: `${String(
            toNumber(
              (quantumFuelTank * 1000) / qd.quantumFuelConsumption,
              "integer",
            ),
          )} Gm`,
        });
      }
      if (qd.quantumFuelConsumption) {
        result.push({
          key: "quantumDrives.fuelConsumption",
          label: t("labels.hardpoint.quantumDrives.fuelConsumption"),
          value: `${String(toNumber(qd.quantumFuelConsumption, "integer"))} mSCU/Gm`,
        });
      }
      if (qd.spoolUpTime) {
        result.push(secondsStat("quantumDrives.spoolUpTime", qd.spoolUpTime));
      }
      if (qd.cooldownTime) {
        result.push(secondsStat("quantumDrives.cooldownTime", qd.cooldownTime));
      }
      // One figure when every phase of the jump puts out the same heat, as
      // every drive in the current build does; the five in order otherwise.
      const jumpHeat = qd.jumpHeat
        ? [
            qd.jumpHeat.preRampUp,
            qd.jumpHeat.rampUp,
            qd.jumpHeat.inFlight,
            qd.jumpHeat.rampDown,
            qd.jumpHeat.postRampDown,
          ].filter((heat): heat is number => typeof heat === "number")
        : [];
      if (jumpHeat.length) {
        result.push({
          key: "quantumDrives.jumpHeat",
          label: t("labels.hardpoint.quantumDrives.jumpHeat"),
          value: (new Set(jumpHeat).size === 1
            ? jumpHeat.slice(0, 1)
            : jumpHeat
          )
            .map((heat) =>
              Math.round(heat) === 0
                ? "0"
                : String(toNumber(Math.round(heat), "integer")),
            )
            .join(" / "),
        });
      }
      if (qd.stageOneAccelRate && qd.stageTwoAccelRate) {
        result.push({
          key: "quantumDrives.accel",
          label: t("labels.hardpoint.quantumDrives.accel"),
          value: `${String(
            toNumber(qd.stageOneAccelRate / 1000, "integer"),
          )} / ${String(toNumber(qd.stageTwoAccelRate / 1000, "integer"))} km/s²`,
        });
      }
      if (qd.engageSpeed) {
        result.push(
          stat("quantumDrives.engageSpeed", qd.engageSpeed, "driveSpeed"),
        );
      }
      if (qd.calibrationRate) {
        result.push({
          key: "quantumDrives.calibrationRate",
          label: t("labels.hardpoint.quantumDrives.calibrationRate"),
          value: `${String(toNumber(qd.calibrationRate, "integer"))}/s`,
        });
      }
      if (qd.disconnectRange) {
        result.push({
          key: "quantumDrives.disconnectRange",
          label: t("labels.hardpoint.quantumDrives.disconnectRange"),
          value: `${String(toNumber(qd.disconnectRange / 1000))} km`,
        });
      }
      if (qd.interdictionEffectTime) {
        result.push(
          secondsStat(
            "quantumDrives.interdictionTime",
            qd.interdictionEffectTime,
          ),
        );
      }

      const spline = qd.splineJumpParams;
      const splineStats: HardpointStat[] = [];
      if (spline?.driveSpeed) {
        splineStats.push(
          stat("quantumDrives.splineSpeed", spline.driveSpeed, "driveSpeed"),
        );
      }
      // Stage one of a spline jump is a crawl -- 250 m/s² on most drives -- so
      // both stages keep their decimal rather than rounding the first to 0.
      if (
        typeof spline?.stageOneAccelRate === "number" &&
        spline.stageTwoAccelRate
      ) {
        splineStats.push({
          key: "quantumDrives.splineAccel",
          label: t("labels.hardpoint.quantumDrives.splineAccel"),
          value: splineAccel(
            spline.stageOneAccelRate,
            spline.stageTwoAccelRate,
          ),
        });
      }
      if (spline?.spoolUpTime) {
        splineStats.push(
          secondsStat("quantumDrives.splineSpoolUpTime", spline.spoolUpTime),
        );
      }
      if (spline?.cooldownTime) {
        splineStats.push(
          secondsStat("quantumDrives.splineCooldownTime", spline.cooldownTime),
        );
      }
      if (spline?.interdictionEffectTime) {
        splineStats.push(
          secondsStat(
            "quantumDrives.splineInterdictionTime",
            spline.interdictionEffectTime,
          ),
        );
      }
      result.push(
        ...splineStats.map((entry) => ({ ...entry, group: "splineJump" })),
      );
    } else if (category === HardpointCategoryEnum.JUMPDRIVE) {
      const jump = typeData as ComponentJumpDrive;
      rowKeys = ROW_STATS.jumpDrive;
      // Alignment/tuning rates are small per-second fractions (0.2 vs 0.24) that
      // collapse under the default single-decimal rounding, so format them with
      // two decimals to keep them distinct.
      const rate = (value: number) =>
        `${(Math.round(value * 100) / 100).toString().replace(".", ",")}/s`;

      if (jump.fuelUsageEfficiencyMultiplier) {
        result.push({
          key: "jumpDrives.fuelEfficiency",
          label: t("labels.hardpoint.jumpDrives.fuelEfficiency"),
          value: `×${String(toNumber(jump.fuelUsageEfficiencyMultiplier))}`,
          primary: true,
        });
      }
      if (jump.exitSpeed) {
        result.push(stat("jumpDrives.exitSpeed", jump.exitSpeed, "speed"));
      }
      if (jump.maxTunnelSpeed) {
        result.push(
          stat("jumpDrives.maxTunnelSpeed", jump.maxTunnelSpeed, "speed"),
        );
      }
      if (jump.respoolTime) {
        result.push(secondsStat("jumpDrives.respoolTime", jump.respoolTime));
      }
      if (jump.alignmentRate) {
        result.push({
          key: "jumpDrives.alignRate",
          label: t("labels.hardpoint.jumpDrives.alignRate"),
          value: rate(jump.alignmentRate),
        });
      }
      if (jump.tuningRate) {
        result.push({
          key: "jumpDrives.tuneRate",
          label: t("labels.hardpoint.jumpDrives.tuneRate"),
          value: rate(jump.tuningRate),
        });
      }
      if (jump.alignmentDecayRate) {
        result.push({
          key: "jumpDrives.alignDecay",
          label: t("labels.hardpoint.jumpDrives.alignDecay"),
          value: rate(jump.alignmentDecayRate),
        });
      }
      if (jump.tuningDecayRate) {
        result.push({
          key: "jumpDrives.tuneDecay",
          label: t("labels.hardpoint.jumpDrives.tuneDecay"),
          value: rate(jump.tuningDecayRate),
        });
      }
    } else if (category && THRUSTER_CATEGORIES.includes(category)) {
      const thruster = typeData as ComponentThruster;

      if (thruster.thrustCapacity) {
        result.push(
          stat("thrusters.thrust", thruster.thrustCapacity, "thrust", true),
        );
      }
      if (thruster.fuelBurnRatePer10KNewton) {
        result.push({
          key: "thrusters.fuelBurn",
          label: "Fuel Burn",
          value: String(
            toNumber(thruster.fuelBurnRatePer10KNewton, "fuelRate"),
          ),
        });
      }
      if (thruster.vtolOnly) {
        result.push({
          key: "thrusters.mode",
          label: t("labels.hardpoint.thrusters.mode"),
          value: t("labels.hardpoint.thrusters.vtolOnly"),
        });
      }
      const gimbal = thruster.gimbal;
      if (gimbal) {
        const pitch = turretRange(gimbal.minPitch, gimbal.maxPitch);
        const yaw = turretRange(gimbal.minYaw, gimbal.maxYaw);
        if (pitch) {
          result.push({
            key: "thrusters.vectorPitch",
            label: t("labels.hardpoint.thrusters.vectorPitch"),
            value: pitch,
          });
        }
        if (yaw) {
          result.push({
            key: "thrusters.vectorYaw",
            label: t("labels.hardpoint.thrusters.vectorYaw"),
            value: yaw,
          });
        }
      }
    } else if (category === HardpointCategoryEnum.RADAR) {
      const radar = typeData as Record<string, unknown>;
      rowKeys = ROW_STATS.radar;

      if (radar.aimAssistRange) {
        result.push(
          stat(
            "radar.aimAssistRange",
            radar.aimAssistRange as number,
            "aimAssistRange",
            true,
          ),
        );
      }
      const sigs = radar.signatureDetection as
        Record<string, { sensitivity?: number }> | undefined;
      if (sigs) {
        if (sigs.ir?.sensitivity != null) {
          result.push(resistanceStat("radar.ir", sigs.ir.sensitivity));
        }
        if (sigs.em?.sensitivity != null) {
          result.push(resistanceStat("radar.em", sigs.em.sensitivity));
        }
        if (sigs.cs?.sensitivity != null) {
          result.push(resistanceStat("radar.cs", sigs.cs.sensitivity));
        }
        if (sigs.rs?.sensitivity != null) {
          result.push(resistanceStat("radar.rs", sigs.rs.sensitivity));
        }

        // Which signatures it sees while silent, and which only on a ping.
        const modes = (["ir", "em", "cs", "rs"] as const).map((type) => ({
          key: `radar.${type}`,
          label: t(`labels.hardpoint.radar.${type}`),
          ...(sigs[type] as { passive?: boolean; active?: boolean }),
        }));
        const passive = modes.filter((mode) => mode.passive);
        const active = modes.filter((mode) => mode.active);
        if (passive.length) {
          result.push({
            key: "radar.passive",
            label: t("labels.hardpoint.radar.passive"),
            value: passive.map((mode) => mode.label).join(" · "),
          });
        }
        if (active.length) {
          result.push({
            key: "radar.active",
            label: t("labels.hardpoint.radar.active"),
            value: active.map((mode) => mode.label).join(" · "),
          });
        }
      }
      if (typeof radar.aimAssistBuffer === "number" && radar.aimAssistBuffer) {
        result.push({
          key: "radar.aimAssistBuffer",
          label: t("labels.hardpoint.radar.aimAssistBuffer"),
          value: `${String(toNumber(radar.aimAssistBuffer, "integer"))} m`,
        });
      }
      // One row per modifier, labelled by the contact groups it applies to.
      // Radars last loaded before those were parsed carry only an addition in
      // `sensitivityModifiers`, with no group to name.
      const legacyModifier = radar.sensitivityModifiers as
        { sensitivityAddition?: number } | undefined;
      const contactSensitivity = (radar.contactSensitivity ??
        (legacyModifier?.sensitivityAddition
          ? [
              {
                sensitivityAddition: legacyModifier.sensitivityAddition,
                contactGroups: [
                  t("labels.hardpoint.radar.sensitivityModifier"),
                ],
              },
            ]
          : [])) as {
        sensitivityAddition: number;
        contactGroups: string[];
      }[];
      contactSensitivity.forEach((entry) => {
        if (!entry.sensitivityAddition || !entry.contactGroups?.length) return;

        result.push({
          label: entry.contactGroups
            .map((group) =>
              RADAR_CONTACT_GROUPS.includes(group)
                ? t(`labels.hardpoint.radar.contactGroups.${group}`)
                : group,
            )
            .join(" · "),
          value: `${Math.round(entry.sensitivityAddition * 100)}%`,
        });
      });
    } else if (
      category === HardpointCategoryEnum.TURRET ||
      category === HardpointCategoryEnum.WEAPON_MOUNTS
    ) {
      const turret = typeData as ComponentTurret;
      rowKeys = ROW_STATS.turret;
      const speeds = [turret.yawSpeed, turret.pitchSpeed].filter(
        (speed): speed is number => typeof speed === "number" && speed > 0,
      );

      if (speeds.length) {
        // One figure when both axes turn alike, which most mounts do; the
        // pair, yaw first, when they differ.
        const value = [...new Set(speeds.map(Math.round))]
          .map((speed) => String(toNumber(speed, "integer")))
          .join(" / ");
        result.push({
          key: "turrets.turnRate",
          label: t("labels.hardpoint.turrets.turnRate"),
          value: `${value} °/s`,
          primary: true,
        });
      }
      const yawRange = turretRange(
        turret.minYaw,
        turret.maxYaw,
        turret.yawLimitsVary,
      );
      if (yawRange) {
        result.push({
          key: "turrets.yawRange",
          label: t("labels.hardpoint.turrets.yawRange"),
          value: yawRange,
        });
      }
      const pitchRange = turretRange(
        turret.minPitch,
        turret.maxPitch,
        turret.pitchLimitsVary,
      );
      if (pitchRange) {
        result.push({
          key: "turrets.pitchRange",
          label: t("labels.hardpoint.turrets.pitchRange"),
          value: pitchRange,
        });
      }
      if (turret.control) {
        result.push({
          key: "turrets.control",
          label: t("labels.hardpoint.turrets.control"),
          value: t(`labels.combat.controlGroups.${turret.control}`),
        });
      }
      // A ship slot lists its children, empty or not, and the mount's own
      // ports are the fallback when none of them takes a gun -- a turret slot
      // can list only its seat or camera while the turret declares the guns.
      const ports =
        gunPorts(hp.hardpoints) ?? gunPorts(hp.component?.hardpoints);
      if (ports) {
        result.push({
          key: "turrets.gunPorts",
          label: t("labels.hardpoint.turrets.gunPorts"),
          value: ports,
        });
      }
    } else if (category === HardpointCategoryEnum.LIFESUPPORT) {
      const lifeSupport = typeData as ComponentLifeSupport;
      if (lifeSupport.lifeSupportGeneration) {
        result.push({
          key: "lifeSupport.output",
          label: t("labels.hardpoint.lifeSupport.output"),
          value: `${precise(lifeSupport.lifeSupportGeneration)}/s`,
          primary: true,
        });
      }
    } else if (category === HardpointCategoryEnum.CONTROLLER) {
      const controller = typeData as ComponentShieldController &
        ComponentMissileController;

      if (controller.faceType) {
        result.push({
          key: "controllers.faceType",
          label: t("labels.hardpoint.controllers.faceType"),
          value: t(`labels.hardpoint.controllers.faces.${controller.faceType}`),
          primary: true,
        });
      }
      if (
        controller.faceType === ComponentShieldFaceTypeEnum.QUADRANT &&
        typeof controller.reconfigurationCooldown === "number"
      ) {
        const cooldown = controller.reconfigurationCooldown;
        result.push({
          key: "controllers.reconfigurationCooldown",
          label: t("labels.hardpoint.controllers.reconfigurationCooldown"),
          value: `${cooldown ? toNumber(cooldown) : "0"} s`,
        });
      }
      if (controller.maxArmedMissiles) {
        result.push(
          stat(
            "controllers.armedMissiles",
            controller.maxArmedMissiles,
            "integer",
            true,
          ),
        );
      }
      // A zero cooldown is a real figure -- missiles can go back to back --
      // and `toNumber` would print it as not available.
      if (typeof controller.launchCooldown === "number") {
        const cooldown = controller.launchCooldown;
        result.push({
          key: "controllers.launchCooldown",
          label: t("labels.hardpoint.controllers.launchCooldown"),
          value: `${cooldown ? toNumber(cooldown) : "0"} s`,
        });
      }
      if (controller.lockAngle) {
        result.push({
          key: "controllers.lockAngle",
          label: t("labels.hardpoint.controllers.lockAngle"),
          value: `${toNumber(controller.lockAngle)}°`,
        });
      }
    } else if (category === HardpointCategoryEnum.COUNTERMEASURES) {
      rowKeys = ROW_STATS.countermeasure;
      const cm = typeData as Record<string, unknown>;
      if (cm.fireRate) {
        result.push(
          stat("weapons.fireRate", cm.fireRate as number, "rateOfFire"),
        );
      }
      if (cm.maxAmmo) {
        result.push(
          stat("weapons.ammo", cm.maxAmmo as number, "integer", true),
        );
      }
      if (cm.speed) {
        result.push(stat("weapons.speed", cm.speed as number, "weaponSpeed"));
      }
      if (cm.range) {
        result.push(stat("weapons.range", cm.range as number, "weaponRange"));
      }
      const launched = (typeData as ComponentWeapon).countermeasure;
      if (launched?.lifetime) {
        result.push({
          key: "countermeasureStats.duration",
          label: t("labels.hardpoint.countermeasureStats.duration"),
          value: `${toNumber(launched.lifetime)} s`,
        });
      }
      if (launched?.spawnDelay) {
        result.push({
          key: "countermeasureStats.spawnDelay",
          label: t("labels.hardpoint.countermeasureStats.spawnDelay"),
          value: `${toNumber(launched.spawnDelay)} s`,
        });
      }
      (
        [
          ["infrared", launched?.infrared],
          ["electromagnetic", launched?.electromagnetic],
          ["crossSection", launched?.crossSection],
        ] as const
      ).forEach(([key, signature]) => {
        const value = signatureRange(signature);
        if (value) {
          result.push({
            key: `countermeasureStats.${key}`,
            label: t(`labels.hardpoint.countermeasureStats.${key}`),
            value,
          });
        }
      });
    } else if (category === HardpointCategoryEnum.ARMOR) {
      rowKeys = ROW_STATS.armor;
      const armor = typeData as ComponentArmor;
      if (armor.health && armor.health > 0) {
        result.push(stat("armor.hp", armor.health, "integer", true));
      }
      // erkul-style damage reduction = 1 − the incoming-damage multiplier.
      const reductionTypes: [keyof ComponentArmor, string][] = [
        ["damagePhysical", "armor.physical"],
        ["damageEnergy", "armor.energy"],
        ["damageDistortion", "armor.distortion"],
        ["damageThermal", "armor.thermal"],
      ];
      for (const [key, labelKey] of reductionTypes) {
        const mult = armor[key];
        if (typeof mult === "number" && mult < 1) {
          result.push(resistanceStat(labelKey, 1 - mult));
        }
      }
      const deflectTypes: [keyof ComponentArmor, string][] = [
        ["deflectionPhysical", "armor.deflectPhysical"],
        ["deflectionEnergy", "armor.deflectEnergy"],
      ];
      for (const [key, labelKey] of deflectTypes) {
        const val = armor[key];
        if (typeof val === "number" && val > 0) {
          result.push(stat(labelKey, val, "integer"));
        }
      }
      // Self-resistance: how the armor resists damage to itself (1 − multiplier;
      // can be negative when a damage type is amplified, matching erkul).
      const selfResistTypes: [keyof ComponentArmor, string][] = [
        ["selfResistancePhysical", "armor.selfPhysical"],
        ["selfResistanceEnergy", "armor.selfEnergy"],
      ];
      for (const [key, labelKey] of selfResistTypes) {
        const mult = armor[key];
        if (typeof mult === "number" && mult !== 1) {
          result.push(resistanceStat(labelKey, 1 - mult));
        }
      }
    } else if (category === HardpointCategoryEnum.FUEL_INTAKES) {
      const fi = typeData as Record<string, unknown>;
      // Fuel rates are small fractions (e.g. 0.2, 2.5); format with toNumber
      // directly — the shared `stat` helper integer-rounds, collapsing them to 0.
      const fuelRate = (labelKey: string, value: number, primary = false) => ({
        key: labelKey,
        label: t(`labels.hardpoint.${labelKey}`),
        value: String(toNumber(value, "fuelRate")),
        primary,
      });
      if (typeof fi.fuelPushRate === "number" && fi.fuelPushRate > 0) {
        result.push(fuelRate("fuelIntakes.pushRate", fi.fuelPushRate, true));
      }
      if (typeof fi.minimumRate === "number" && fi.minimumRate > 0) {
        result.push(fuelRate("fuelIntakes.minRate", fi.minimumRate));
      }
    } else if (category === HardpointCategoryEnum.UTILITY) {
      // 39 of the 71 utility components with data carry nothing but a
      // capacity. The three that are tractor beams fall to the shape check
      // above, which runs before any category branch.
      const utility = typeData as Record<string, unknown>;
      if (utility.miningModule) {
        pushMiningModule(result, typeData as ComponentMiningModule);
      } else if (utility.salvageModifier) {
        pushSalvageModifier(result, typeData as ComponentSalvageModifier);
      } else if (typeof utility.capacity === "number" && utility.capacity > 0) {
        result.push(stat("utility.capacity", utility.capacity, "cargo", true));
      }
    } else if (category === HardpointCategoryEnum.SELFDESTRUCT) {
      // Stored as strings in the export, so coerced rather than type-checked.
      const sd = typeData as Record<string, unknown>;
      const num = (value: unknown) => {
        const parsed = Number(value);
        return Number.isFinite(parsed) && parsed > 0 ? parsed : undefined;
      };

      const damage = num(sd.damage);
      if (damage)
        result.push(stat("selfDestruct.damage", damage, "integer", true));

      const radius = num(sd.radius);
      if (radius) {
        result.push({
          key: "selfDestruct.radius",
          label: t("labels.hardpoint.selfDestruct.radius"),
          value: `${String(toNumber(radius, "integer"))} m`,
        });
      }

      const time = num(sd.time);
      if (time) {
        result.push({
          key: "selfDestruct.time",
          label: t("labels.hardpoint.selfDestruct.time"),
          value: String(toNumber(time, "seconds")),
        });
      }
    } else if (category === HardpointCategoryEnum.QUANTUMENFORCEMENTDEVICE) {
      // The two settings blocks carry 17 keys between them. These four are the
      // ones that say what the device does to somebody else's quantum drive;
      // the rest describe its own charge curve.
      const qed = typeData as Record<string, unknown>;
      rowKeys = ROW_STATS.quantumEnforcement;
      const jammer = (qed.jammerSettings ?? {}) as Record<string, unknown>;
      const pulse = (qed.quantumInterdictionPulseSettings ?? {}) as Record<
        string,
        unknown
      >;

      if (typeof jammer.jammerRange === "number") {
        result.push({
          key: "quantumEnforcement.jammerRange",
          label: t("labels.hardpoint.quantumEnforcement.jammerRange"),
          value: `${String(toNumber(jammer.jammerRange, "integer"))} m`,
        });
      }
      if (typeof pulse.radiusMeters === "number") {
        result.push({
          key: "quantumEnforcement.pulseRadius",
          label: t("labels.hardpoint.quantumEnforcement.pulseRadius"),
          value: `${String(toNumber(pulse.radiusMeters, "integer"))} m`,
        });
      }
      if (typeof pulse.chargeTimeSecs === "number") {
        result.push({
          key: "quantumEnforcement.chargeTime",
          label: t("labels.hardpoint.quantumEnforcement.chargeTime"),
          value: String(toNumber(pulse.chargeTimeSecs, "seconds")),
        });
      }
      if (typeof pulse.cooldownTimeSecs === "number") {
        result.push({
          key: "quantumEnforcement.cooldownTime",
          label: t("labels.hardpoint.quantumEnforcement.cooldownTime"),
          value: String(toNumber(pulse.cooldownTimeSecs, "seconds")),
        });
      }
    }

    const refuel = typeData as Record<string, unknown>;
    if (
      refuel.captureRadius != null ||
      refuel.fuelFlowRate != null ||
      refuel.quantumFuelFlowRate != null
    ) {
      if (refuel.captureRadius != null) {
        result.push({
          key: "refuelBoom.captureRadius",
          label: t("labels.hardpoint.refuelBoom.captureRadius"),
          value: `${String(toNumber(refuel.captureRadius as number, "integer"))} m`,
        });
      }
      if (refuel.fuelFlowRate != null) {
        result.push({
          key: "refuelBoom.fuelFlowRate",
          label: t("labels.hardpoint.refuelBoom.fuelFlowRate"),
          value: `${String(toNumber(refuel.fuelFlowRate as number, "cargo"))}/s`,
        });
      }
      if (refuel.quantumFuelFlowRate != null) {
        result.push({
          key: "refuelBoom.quantumFuelFlowRate",
          label: t("labels.hardpoint.refuelBoom.quantumFuelFlowRate"),
          value: `${String(toNumber(refuel.quantumFuelFlowRate as number, "cargo"))}/s`,
          wide: true,
        });
      }
    }

    const ownCount = result.length;
    result.push(...poweredStats(typeData as PoweredTypeData, category));

    return result.map((entry, index) => {
      const row = rowKeys
        ? rowKeys.indexOf(entry.key ?? "")
        : index < ownCount
          ? index
          : -1;

      return row >= 0 ? { ...entry, row } : entry;
    });
  });
};
