<script lang="ts">
export default {
  name: "HardpointDetails",
};
</script>

<script lang="ts" setup>
import {
  HardpointCategoryEnum,
  type Hardpoint,
  type ComponentWeapon,
  type ComponentShield,
  type ComponentQuantumDrive,
  type ComponentThruster,
} from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";

type Props = {
  hardpoint: Hardpoint;
};

const props = defineProps<Props>();

const { t, toNumber } = useI18n();

type Stat = {
  label: string;
  value: string;
};

const stats = computed<Stat[]>(() => {
  const typeData = props.hardpoint.component?.typeData;
  if (!typeData) return [];

  const category = props.hardpoint.category;
  const result: Stat[] = [];

  if (category === HardpointCategoryEnum.WEAPONS) {
    const weapon = typeData as ComponentWeapon;

    if (weapon.beam) {
      if (weapon.damagePerSecond) {
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
      // Missile
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
      // Projectile weapon
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
      if (weapon.maxAmmo) {
        result.push(stat("weapons.ammo", weapon.maxAmmo, "integer"));
      }
      if (weapon.heatPerShot) {
        result.push(stat("weapons.heatPerShot", weapon.heatPerShot, "integer"));
      }
    }
  } else if (category === HardpointCategoryEnum.SHIELDGENERATOR) {
    const shield = typeData as ComponentShield;

    if (shield.maxHealth) {
      result.push(stat("shields.hp", shield.maxHealth, "shieldHp"));
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
        stat("shields.downedRegenDelay", shield.downedRegenDelay, "delayTime"),
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
        result.push(resistanceStat("shields.resistanceEnergy", res.energy.max));
      }
      if (res.distortion?.max) {
        result.push(
          resistanceStat("shields.resistanceDistortion", res.distortion.max),
        );
      }
    }
  } else if (category === HardpointCategoryEnum.QUANTUMDRIVE) {
    const qd = typeData as ComponentQuantumDrive;

    if (qd.driveSpeed) {
      result.push(stat("quantumDrives.speed", qd.driveSpeed, "driveSpeed"));
    }
    if (qd.quantumFuelRequirement) {
      result.push(
        stat(
          "quantumDrives.fuelConsumption",
          qd.quantumFuelRequirement,
          "fuelRate",
        ),
      );
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
  } else if (
    category === HardpointCategoryEnum.MAIN_THRUSTERS ||
    category === HardpointCategoryEnum.MANEUVERING_THRUSTERS ||
    category === HardpointCategoryEnum.RETRO_THRUSTERS ||
    category === HardpointCategoryEnum.VTOL_THRUSTERS
  ) {
    const thruster = typeData as ComponentThruster;

    if (thruster.thrustCapacity) {
      result.push(stat("thrusters.thrust", thruster.thrustCapacity, "thrust"));
    }
    if (thruster.fuelBurnRatePer10KNewton) {
      result.push({
        label: "Fuel Burn",
        value: String(toNumber(thruster.fuelBurnRatePer10KNewton, "fuelRate")),
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
    }
  }

  return result;
});

function stat(labelKey: string, value: number, format: string): Stat {
  return {
    label: t(`labels.hardpoint.${labelKey}`),
    value: String(toNumber(value, format)),
  };
}

function resistanceStat(labelKey: string, value: number): Stat {
  return {
    label: t(`labels.hardpoint.${labelKey}`),
    value: `${Math.round(value * 100)}%`,
  };
}

function addDamageBreakdown(result: Stat[], damage: Record<string, unknown>) {
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
}
</script>

<template>
  <div v-if="stats.length" class="hardpoint-details">
    <div v-for="(s, i) in stats" :key="i" class="hardpoint-details__stat">
      <span class="hardpoint-details__label">{{ s.label }}</span>
      <span class="hardpoint-details__value">{{ s.value }}</span>
    </div>
  </div>
</template>

<style lang="scss" scoped>
@import "index";
</style>
