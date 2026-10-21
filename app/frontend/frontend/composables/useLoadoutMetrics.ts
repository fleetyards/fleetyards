import type { CompareDeltaTone } from "@/frontend/components/Compare/delta";
import type { WeaponRegenModifier } from "@/frontend/composables/powerSim";
import { figureDelta } from "@/frontend/composables/figureDelta";
import {
  type LoadoutStats,
  computeLoadoutStats,
} from "@/frontend/composables/useLoadoutStats";
import {
  type ShieldStats,
  computeShieldStats,
} from "@/frontend/composables/useShieldStats";
import {
  type LoadoutSimResult,
  simulateLoadoutPower,
} from "@/frontend/composables/useLoadoutSim";
import { useI18n } from "@/shared/composables/useI18n";
import type { ComponentController, Hardpoint } from "@/services/fyApi";

export type LoadoutMetricsCard = "power" | "defense" | "combat" | "flight";

// One figure of a metrics card, as it stands under the fitting and how far it
// moved from the saved loadout.
export interface LoadoutMetric {
  key: string;
  label: string;
  value: string;
  unit?: string;
  deltaLabel?: string;
  tone?: CompareDeltaTone;
  // How full a figure that has a ceiling is, 0 to 1 and past it when over.
  ratio?: number;
}

// The card each tab's parts move; the modules tab has none.
export const TAB_METRICS: Record<string, LoadoutMetricsCard> = {
  radar: "power",
  coolers: "power",
  lifeSupport: "power",
  powerPlants: "power",
  quantumDrives: "power",
  shields: "defense",
  missiles: "combat",
  weapons: "combat",
  flightBlades: "flight",
};

interface Fitting {
  hardpoints: Hardpoint[];
  blade?: ComponentController;
}

// What the cards read off one fitting, worked out once for all of them.
export interface FittingMeasure {
  power: LoadoutSimResult;
  shields: ShieldStats;
  combat: LoadoutStats;
  blade?: ComponentController;
}

/**
 * The figures the ship page's metrics cards lead with -- power and heat,
 * shields, damage, speed -- worked out by the same code the cards use. A
 * fitting is measured once, so the saved one need not be measured again on
 * every pick, and two measures compared card by card.
 */
export const useLoadoutMetrics = () => {
  const { t, toNumber } = useI18n();

  const number = (value: number) => String(toNumber(Math.round(value)));

  const compact = (value: number) =>
    value >= 1000
      ? `${String(toNumber(Math.round(value / 100) / 10))}k`
      : number(value);

  const delta = (before: number, after: number, lowerIsBetter = false) =>
    figureDelta(before, after, lowerIsBetter, number);

  const measure = (
    fitting: Fitting,
    poolSize?: number,
    regenModifier?: WeaponRegenModifier,
  ): FittingMeasure => {
    const power = simulateLoadoutPower(
      fitting.hardpoints,
      poolSize,
      "SCM",
      undefined,
      undefined,
      regenModifier,
    );

    return {
      power,
      shields: computeShieldStats(fitting.hardpoints, power.shieldPoolRatio),
      combat: computeLoadoutStats(
        fitting.hardpoints,
        poolSize,
        undefined,
        regenModifier,
      ),
      blade: fitting.blade,
    };
  };

  const power = (now: FittingMeasure, saved: FittingMeasure) => {
    const after = now.power;
    const before = saved.power;
    const used = (sim: LoadoutSimResult) => sim.totalSegments - sim.remaining;

    return [
      {
        key: "power",
        label: t("labels.hardpoint.powerConsumption"),
        value: `${used(after)} / ${after.totalSegments}`,
        ratio: after.totalSegments ? used(after) / after.totalSegments : 0,
        ...delta(used(before), used(after), true),
      },
      {
        key: "pips",
        label: t("labels.hardpoint.powerPlants.pips"),
        value: String(after.totalSegments),
        ...delta(before.totalSegments, after.totalSegments),
      },
      ...(after.coolingMaxPerSec > 0
        ? [
            {
              key: "cooling",
              label: t("labels.power.cooling"),
              value: `${Math.round(after.coolingRatio * 100)}%`,
              ratio: after.coolingRatio,
              ...delta(before.coolingRatio, after.coolingRatio, true),
            },
          ]
        : []),
      {
        key: "em",
        label: t("labels.power.em"),
        value: compact(after.emittedEm),
        ...delta(before.emittedEm, after.emittedEm, true),
      },
      {
        key: "ir",
        label: t("labels.power.ir"),
        value: compact(after.emittedIr),
        ...delta(before.emittedIr, after.emittedIr, true),
      },
    ];
  };

  const defense = (now: FittingMeasure, saved: FittingMeasure) => {
    const after = now.shields;
    const before = saved.shields;

    return [
      {
        key: "shieldHp",
        label: t("labels.defense.shieldHp"),
        value: number(after.totalHp),
        unit: "HP",
        ...delta(before.totalHp, after.totalHp),
      },
      {
        key: "shieldRegen",
        label: t("labels.defense.shieldRegen"),
        value: number(after.totalRegen),
        unit: "HP/s",
        ...delta(before.totalRegen, after.totalRegen),
      },
    ];
  };

  const combat = (now: FittingMeasure, saved: FittingMeasure) => {
    const after = now.combat;
    const before = saved.combat;

    return [
      {
        key: "dps",
        label: t("labels.combat.dps"),
        value: number(after.dps.total),
        ...delta(before.dps.total, after.dps.total),
      },
      {
        key: "sustainedDps",
        label: t("labels.combat.sustained"),
        value: number(after.sustainedDps.total),
        ...delta(before.sustainedDps.total, after.sustainedDps.total),
      },
      {
        key: "alpha",
        label: t("labels.combat.alpha"),
        value: number(after.alpha.total),
        ...delta(before.alpha.total, after.alpha.total),
      },
      ...(after.missileDamage || before.missileDamage
        ? [
            {
              key: "missileDamage",
              label: t("labels.combat.missileDamage"),
              value: number(after.missileDamage),
              ...delta(before.missileDamage, after.missileDamage),
            },
          ]
        : []),
    ];
  };

  const flight = (now: FittingMeasure, saved: FittingMeasure) => {
    const speeds: [string, string, keyof ComponentController][] = [
      ["scmSpeed", t("model.scmSpeed"), "scmSpeed"],
      ["boostSpeed", t("labels.flight.boost"), "scmSpeedBoosted"],
      ["maxSpeed", t("model.maxSpeed"), "maxSpeed"],
    ];

    return speeds
      .filter(([, , field]) => typeof now.blade?.[field] === "number")
      .map(([key, label, field]) => {
        const after = now.blade?.[field] as number;
        const before = (saved.blade?.[field] as number | undefined) ?? after;

        return {
          key,
          label,
          value: number(after),
          unit: "m/s",
          ...delta(before, after),
        };
      });
  };

  const metrics = (
    card: LoadoutMetricsCard,
    now: FittingMeasure,
    saved: FittingMeasure,
  ): LoadoutMetric[] => {
    switch (card) {
      case "power":
        return power(now, saved);
      case "defense":
        return defense(now, saved);
      case "combat":
        return combat(now, saved);
      case "flight":
        return flight(now, saved);
    }
  };

  return { measure, metrics };
};
