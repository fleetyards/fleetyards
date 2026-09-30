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
} from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";
import { sustainedRatio } from "@/frontend/composables/useLoadoutStats";
import {
  powerPlantContextKey,
  powerPlantPips,
} from "@/frontend/components/Models/Hardpoints/powerPlant";

export type HardpointStat = {
  label: string;
  value: string;
  wide?: boolean;
  primary?: boolean;
  // Figures that describe one mode of the item rather than the item itself --
  // a quantum drive's spline jump -- which a detail page gives a card of their
  // own. A row lists them with the rest; their labels already name the mode.
  group?: string;
};

// Ordered, human-readable stats for a hardpoint's mounted component, most
// important first. Shared by the inline row summary (first couple) and the
// expandable details grid (all of them).
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
    label: t(`labels.hardpoint.${labelKey}`),
    value: String(toNumber(Math.round(value), format)),
    primary,
  });

  // One decimal, not rounded to a whole second: spool, cooldown and
  // interdiction times are tenths (7.3 s, 2.6 s).
  const secondsStat = (labelKey: string, value: number): HardpointStat => ({
    label: t(`labels.hardpoint.${labelKey}`),
    value: String(toNumber(value, "seconds")),
  });

  // For figures that live below the one-decimal stat format -- a 0.25 km/s²
  // first stage, a 0.05/s air output -- where rounding would misstate them.
  // Zero stays a zero rather than "not available". Thousands are grouped the
  // way `toNumber` groups them.
  const precise = (value: number, digits = 3): string => {
    if (Math.abs(value) >= 1) return String(toNumber(value));

    const rounded = String(Math.round(value * 10 ** digits) / 10 ** digits);

    return rounded.replace(".", t("number.format.separator") || ",");
  };

  const splineAccel = (stageOne: number, stageTwo: number) =>
    `${precise(stageOne / 1000)} / ${precise(stageTwo / 1000)} km/s²`;

  const resistanceStat = (labelKey: string, value: number): HardpointStat => ({
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
    } else if (category === HardpointCategoryEnum.WEAPONS) {
      const weapon = typeData as ComponentWeapon;
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
            label: t("labels.hardpoint.weapons.efficiency"),
            value: `${Math.round(efficiency * 100)}%`,
          });
        } else {
          result.push(stat("weapons.burstDps", burstTotal, "integer", true));
        }
      };

      if (weapon.beam) {
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
        pushOrdnanceDamage(missile.damagePerShot);
        if (missile.speed) {
          result.push(stat("missiles.speed", missile.speed, "missileSpeed"));
        }
        if (missile.range) {
          result.push(stat("missiles.range", missile.range, "missileRange"));
        }
        if (missile.lockRangeMin || missile.lockRangeMax) {
          result.push({
            label: t("labels.hardpoint.missiles.lockRange"),
            value: `${String(toNumber(missile.lockRangeMin || 0, "missileRange"))} - ${String(toNumber(missile.lockRangeMax || 0, "missileRange"))}`,
          });
        }
        if (missile.lockTime) {
          result.push(stat("missiles.lockTime", missile.lockTime, "lockTime"));
        }
        if (missile.trackingSignal) {
          result.push({
            label: t("labels.hardpoint.missiles.trackingSignal"),
            value: String(missile.trackingSignal),
          });
        }
        if (missile.lockAngle) {
          result.push(stat("missiles.lockAngle", missile.lockAngle, "degrees"));
        }
        if (missile.signalResilienceMin || missile.signalResilienceMax) {
          result.push({
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
              label: t("labels.hardpoint.weapons.spreadFirstShot"),
              value: degrees(firstAttack),
            });
          }
          if (grows && attack) {
            result.push({
              label: t("labels.hardpoint.weapons.spreadPerShot"),
              value: degrees(attack),
            });
          }
          if (grows && decay) {
            result.push({
              label: t("labels.hardpoint.weapons.spreadRecovery"),
              value: `${degrees(decay)}/s`,
            });
          }
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
          stat(
            "shields.downedRegenDelay",
            shield.downedRegenDelay,
            "delayTime",
          ),
        );
      }
      if (shield.damagedRegenDelay) {
        result.push(
          stat(
            "shields.damagedRegenDelay",
            shield.damagedRegenDelay,
            "delayTime",
          ),
        );
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
    } else if (category === HardpointCategoryEnum.COOLER) {
      const cooler = typeData as ComponentCooler;
      if (cooler.coolingRate) {
        result.push(
          stat("coolers.coolingRate", cooler.coolingRate, "integer", true),
        );
      }
    } else if (category === HardpointCategoryEnum.POWERPLANT) {
      const pp = typeData as ComponentPowerPlant;
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
    } else if (category === HardpointCategoryEnum.QUANTUMDRIVE) {
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
      if (qd.stageOneAccelRate && qd.stageTwoAccelRate) {
        result.push({
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
          label: t("labels.hardpoint.quantumDrives.calibrationRate"),
          value: `${String(toNumber(qd.calibrationRate, "integer"))}/s`,
        });
      }
      if (qd.disconnectRange) {
        result.push({
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
      // Alignment/tuning rates are small per-second fractions (0.2 vs 0.24) that
      // collapse under the default single-decimal rounding, so format them with
      // two decimals to keep them distinct.
      const rate = (value: number) =>
        `${(Math.round(value * 100) / 100).toString().replace(".", ",")}/s`;

      if (jump.fuelUsageEfficiencyMultiplier) {
        result.push({
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
          label: t("labels.hardpoint.jumpDrives.alignRate"),
          value: rate(jump.alignmentRate),
        });
      }
      if (jump.tuningRate) {
        result.push({
          label: t("labels.hardpoint.jumpDrives.tuneRate"),
          value: rate(jump.tuningRate),
        });
      }
      if (jump.alignmentDecayRate) {
        result.push({
          label: t("labels.hardpoint.jumpDrives.alignDecay"),
          value: rate(jump.alignmentDecayRate),
        });
      }
      if (jump.tuningDecayRate) {
        result.push({
          label: t("labels.hardpoint.jumpDrives.tuneDecay"),
          value: rate(jump.tuningDecayRate),
        });
      }
    } else if (
      category === HardpointCategoryEnum.MAIN_THRUSTERS ||
      category === HardpointCategoryEnum.MANEUVERING_THRUSTERS ||
      category === HardpointCategoryEnum.RETRO_THRUSTERS ||
      category === HardpointCategoryEnum.VTOL_THRUSTERS
    ) {
      const thruster = typeData as ComponentThruster;

      if (thruster.thrustCapacity) {
        result.push(
          stat("thrusters.thrust", thruster.thrustCapacity, "thrust", true),
        );
      }
      if (thruster.fuelBurnRatePer10KNewton) {
        result.push({
          label: "Fuel Burn",
          value: String(
            toNumber(thruster.fuelBurnRatePer10KNewton, "fuelRate"),
          ),
        });
      }
    } else if (category === HardpointCategoryEnum.RADAR) {
      const radar = typeData as Record<string, unknown>;

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
      }
    } else if (
      category === HardpointCategoryEnum.TURRET ||
      category === HardpointCategoryEnum.WEAPON_MOUNTS
    ) {
      const turret = typeData as ComponentTurret;
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
          label: t("labels.hardpoint.turrets.pitchRange"),
          value: pitchRange,
        });
      }
      if (turret.control) {
        result.push({
          label: t("labels.hardpoint.turrets.control"),
          value: t(`labels.combat.controlGroups.${turret.control}`),
        });
      }
    } else if (category === HardpointCategoryEnum.COUNTERMEASURES) {
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
    } else if (category === HardpointCategoryEnum.ARMOR) {
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
      if (typeof utility.capacity === "number" && utility.capacity > 0) {
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
          label: t("labels.hardpoint.selfDestruct.radius"),
          value: `${String(toNumber(radius, "integer"))} m`,
        });
      }

      const time = num(sd.time);
      if (time) {
        result.push({
          label: t("labels.hardpoint.selfDestruct.time"),
          value: String(toNumber(time, "seconds")),
        });
      }
    } else if (category === HardpointCategoryEnum.QUANTUMENFORCEMENTDEVICE) {
      // The two settings blocks carry 17 keys between them. These four are the
      // ones that say what the device does to somebody else's quantum drive;
      // the rest describe its own charge curve.
      const qed = typeData as Record<string, unknown>;
      const jammer = (qed.jammerSettings ?? {}) as Record<string, unknown>;
      const pulse = (qed.quantumInterdictionPulseSettings ?? {}) as Record<
        string,
        unknown
      >;

      if (typeof jammer.jammerRange === "number") {
        result.push({
          label: t("labels.hardpoint.quantumEnforcement.jammerRange"),
          value: `${String(toNumber(jammer.jammerRange, "integer"))} m`,
        });
      }
      if (typeof pulse.radiusMeters === "number") {
        result.push({
          label: t("labels.hardpoint.quantumEnforcement.pulseRadius"),
          value: `${String(toNumber(pulse.radiusMeters, "integer"))} m`,
        });
      }
      if (typeof pulse.chargeTimeSecs === "number") {
        result.push({
          label: t("labels.hardpoint.quantumEnforcement.chargeTime"),
          value: String(toNumber(pulse.chargeTimeSecs, "seconds")),
        });
      }
      if (typeof pulse.cooldownTimeSecs === "number") {
        result.push({
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
          label: t("labels.hardpoint.refuelBoom.captureRadius"),
          value: `${String(toNumber(refuel.captureRadius as number, "integer"))} m`,
        });
      }
      if (refuel.fuelFlowRate != null) {
        result.push({
          label: t("labels.hardpoint.refuelBoom.fuelFlowRate"),
          value: `${String(toNumber(refuel.fuelFlowRate as number, "cargo"))}/s`,
        });
      }
      if (refuel.quantumFuelFlowRate != null) {
        result.push({
          label: t("labels.hardpoint.refuelBoom.quantumFuelFlowRate"),
          value: `${String(toNumber(refuel.quantumFuelFlowRate as number, "cargo"))}/s`,
          wide: true,
        });
      }
    }

    return result;
  });
};
