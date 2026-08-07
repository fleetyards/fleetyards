import { computed, inject, toValue, type MaybeRefOrGetter } from "vue";
import {
  HardpointCategoryEnum,
  type Hardpoint,
  type ComponentWeapon,
  type ComponentShield,
  type ComponentCooler,
  type ComponentPowerPlant,
  type ComponentQuantumDrive,
  type ComponentJumpDrive,
  type ComponentThruster,
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

  const resistanceStat = (labelKey: string, value: number): HardpointStat => ({
    label: t(`labels.hardpoint.${labelKey}`),
    value: `${Math.round(value * 100)}%`,
  });

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
    damage: Record<string, unknown>,
  ) => {
    const types: [string, string][] = [
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

  return computed<HardpointStat[]>(() => {
    const hp = toValue(hardpoint);
    const typeData = hp?.component?.typeData;
    if (!hp || !typeData) return [];

    const category = hp.category;
    const result: HardpointStat[] = [];

    if (category === HardpointCategoryEnum.WEAPONS) {
      const weapon = typeData as ComponentWeapon;
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
            stat("weapons.sustainedDps", burstTotal * efficiency, "dps", true),
          );
          result.push(stat("weapons.burstDps", burstTotal, "dps"));
          result.push({
            label: t("labels.hardpoint.weapons.efficiency"),
            value: `${Math.round(efficiency * 100)}%`,
          });
        } else {
          result.push(stat("weapons.burstDps", burstTotal, "dps", true));
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
      } else if ("trackingSignal" in typeData) {
        if (weapon.damagePerShot) {
          addDamageBreakdown(result, weapon.damagePerShot);
        }
        if (weapon.speed) {
          result.push(stat("missiles.speed", weapon.speed, "missileSpeed"));
        }
        if (weapon.range) {
          result.push(stat("missiles.range", weapon.range, "missileRange"));
        }
        {
          const td = typeData as Record<string, unknown>;
          const min = td.lockRangeMin as number | undefined;
          const max = td.lockRangeMax as number | undefined;
          if (min || max) {
            result.push({
              label: t("labels.hardpoint.missiles.lockRange"),
              value: `${String(toNumber(min || 0, "missileRange"))} - ${String(toNumber(max || 0, "missileRange"))}`,
            });
          }
        }
        if ((typeData as Record<string, unknown>).lockTime) {
          result.push(
            stat(
              "missiles.lockTime",
              (typeData as Record<string, unknown>).lockTime as number,
              "lockTime",
            ),
          );
        }
        if ((typeData as Record<string, unknown>).trackingSignal) {
          result.push({
            label: t("labels.hardpoint.missiles.trackingSignal"),
            value: String((typeData as Record<string, unknown>).trackingSignal),
          });
        }
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
        if (weapon.fireRate) {
          result.push(stat("weapons.fireRate", weapon.fireRate, "rateOfFire"));
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
    } else if (category === HardpointCategoryEnum.SHIELDGENERATOR) {
      const shield = typeData as ComponentShield;

      if (shield.maxHealth) {
        result.push(stat("shields.hp", shield.maxHealth, "shieldHp", true));
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
          stat("coolers.coolingRate", cooler.coolingRate, "coolingRate", true),
        );
      }
    } else if (category === HardpointCategoryEnum.POWERPLANT) {
      const pp = typeData as ComponentPowerPlant;
      // Output is a per-plant rating, so it stays as-is even on a stacked row.
      // Pips are a ship-pool contribution, so they sum across the stack (the
      // total the category header used to show).
      const stackCount = Math.max(1, Math.round(Number(toValue(count) ?? 1)));
      if (pp.powerBase) {
        result.push(
          stat("powerPlants.output", pp.powerBase, "powerOutput", true),
        );
      }
      const context = toValue(powerPlantContext);
      const size = Number(hp.component?.size);
      if (pp.powerBase && context && size) {
        result.push(
          stat(
            "powerPlants.pips",
            powerPlantPips(pp.powerBase, size, context) * stackCount,
            "powerPips",
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
        result.push(
          stat("quantumDrives.spoolUpTime", qd.spoolUpTime, "spoolTime"),
        );
      }
      if (qd.cooldownTime) {
        result.push(
          stat("quantumDrives.cooldownTime", qd.cooldownTime, "cooldownTime"),
        );
      }
      if (qd.splineJumpParams?.driveSpeed) {
        result.push(
          stat(
            "quantumDrives.splineSpeed",
            qd.splineJumpParams.driveSpeed,
            "driveSpeed",
          ),
        );
      }
      if (qd.stageOneAccelRate && qd.stageTwoAccelRate) {
        result.push({
          label: t("labels.hardpoint.quantumDrives.accel"),
          value: `${String(
            toNumber(qd.stageOneAccelRate / 1000, "integer"),
          )} / ${String(toNumber(qd.stageTwoAccelRate / 1000, "integer"))} km/s²`,
        });
      }
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
        | Record<string, { sensitivity?: number }>
        | undefined;
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
    } else if (category === HardpointCategoryEnum.COUNTERMEASURES) {
      const cm = typeData as Record<string, unknown>;
      if (cm.fireRate) {
        result.push(
          stat("weapons.fireRate", cm.fireRate as number, "rateOfFire"),
        );
      }
      if (cm.maxAmmo) {
        result.push(stat("weapons.ammo", cm.maxAmmo as number, "integer"));
      }
      if (cm.speed) {
        result.push(stat("weapons.speed", cm.speed as number, "weaponSpeed"));
      }
      if (cm.range) {
        result.push(stat("weapons.range", cm.range as number, "weaponRange"));
      }
    } else if (category === HardpointCategoryEnum.ARMOR) {
      const armor = typeData as Record<string, unknown>;
      const armorTypes: [string, string][] = [
        ["damagePhysical", "armor.physical"],
        ["damageEnergy", "armor.energy"],
        ["damageDistortion", "armor.distortion"],
        ["damageThermal", "armor.thermal"],
      ];
      for (const [key, labelKey] of armorTypes) {
        const val = armor[key];
        if (typeof val === "number" && val > 0) {
          result.push(resistanceStat(labelKey, val));
        }
      }
    } else if (category === HardpointCategoryEnum.FUEL_INTAKES) {
      const fi = typeData as Record<string, unknown>;
      if (fi.fuelPushRate) {
        result.push(
          stat("fuelIntakes.pushRate", fi.fuelPushRate as number, "fuelRate"),
        );
      }
      if (fi.minimumRate) {
        result.push(
          stat("fuelIntakes.minRate", fi.minimumRate as number, "fuelRate"),
        );
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
