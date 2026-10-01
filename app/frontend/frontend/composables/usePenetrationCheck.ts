import { computed, toValue, type MaybeRefOrGetter } from "vue";
import {
  HardpointCategoryEnum,
  type ComponentWeapon,
  type Hardpoint,
  type ModelDefense,
  type WeaponIndexItem,
} from "@/services/fyApi";
import {
  armorStatsFrom,
  type ArmorStats,
} from "@/frontend/composables/useArmorStats";
import {
  shieldStatsFrom,
  type ShieldStats,
} from "@/frontend/composables/useShieldStats";
import {
  byMargin,
  DEFLECTION_DAMAGE_TYPES,
  evaluateWeapon,
  type DeflectionOutcome,
  type DeflectionResult,
} from "@/frontend/composables/useDeflectionCheck";
import {
  dutyCycle,
  shotsPerSecond,
  type DamageType,
  type DutyCycle,
} from "@/frontend/composables/useLoadoutStats";

export type LoadoutWeapon = WeaponIndexItem & {
  // Identical guns share one row; how many of them the loadout mounts.
  count: number;
  // One gun's sustained damage per second by type, the way the combat card
  // counts it.
  sustainedDps: Record<DamageType, number>;
  duty: DutyCycle;
};

export type PenetrationTarget = {
  model: ModelDefense;
  armor: ArmorStats;
  shield: ShieldStats;
};

export type PenetrationResult = {
  model: ModelDefense;
  // Every selected weapon against this ship, best first.
  weapons: DeflectionResult[];
  // The weapon that gets furthest past (or closest to) the threshold, among
  // those that reach the armor. Null when the shield soaks all of them.
  best: DeflectionResult | null;
  margin: number | null;
  outcome: DeflectionOutcome;
};

export type PenetrationSummary = {
  results: PenetrationResult[];
  absorbedCount: number;
  deflectedCount: number;
  pierceCount: number;
};

function isMissile(weapon: ComponentWeapon): boolean {
  return "trackingSignal" in (weapon as Record<string, unknown>);
}

// The guns a loadout mounts, in the shape the deflection pipeline reads. Nested
// slots count as well: most guns sit on a gimbal or turret, not on the hull.
// Beams are included for their damage over time; with no per-shot alpha they
// never enter the deflection margin.
export function collectLoadoutWeapons(
  hardpoints: Hardpoint[] | undefined,
  powerRatio = 1,
): LoadoutWeapon[] {
  const byComponent = new Map<string, LoadoutWeapon>();

  const walk = (slots: Hardpoint[] | undefined) => {
    for (const hardpoint of slots || []) {
      const component = hardpoint.component;
      const weapon = component?.typeData as ComponentWeapon | undefined;

      if (
        component &&
        weapon &&
        hardpoint.category === HardpointCategoryEnum.WEAPONS &&
        !isMissile(weapon) &&
        !weapon.mining &&
        DEFLECTION_DAMAGE_TYPES.some(
          ({ key }) =>
            ((weapon.beam ? weapon.damagePerSecond : weapon.damagePerShot)?.[
              key
            ] ?? 0) > 0,
        )
      ) {
        const existing = byComponent.get(component.id);

        if (existing) {
          existing.count += 1;
        } else {
          const duty = dutyCycle(weapon, powerRatio);
          // An unpowered weapon system fires nothing, heat-limited guns included.
          const powered = powerRatio > 0 ? 1 : 0;
          const sustained = (key: DamageType) =>
            (weapon.beam
              ? (weapon.damagePerSecond?.[key] ?? 0)
              : (weapon.damagePerShot?.[key] ?? 0) * shotsPerSecond(weapon)) *
            duty.ratio *
            powered;
          const perShot = (key: DamageType) =>
            weapon.beam ? 0 : (weapon.damagePerShot?.[key] ?? 0);

          byComponent.set(component.id, {
            id: component.id,
            name: component.name,
            slug: component.slug,
            size: component.size,
            manufacturerCode: component.manufacturer?.code,
            beam: !!weapon.beam,
            pelletsPerShot: weapon.pelletsPerShot,
            damagePerShot: {
              physical: perShot("physical"),
              energy: perShot("energy"),
              distortion: perShot("distortion"),
              thermal: perShot("thermal"),
            },
            count: 1,
            sustainedDps: {
              physical: sustained("physical"),
              energy: sustained("energy"),
              distortion: sustained("distortion"),
              thermal: sustained("thermal"),
            },
            duty,
          });
        }
      }

      walk(hardpoint.hardpoints);
    }
  };

  walk(hardpoints);

  return [...byComponent.values()].sort(
    (a, b) => Number(b.size ?? 0) - Number(a.size ?? 0),
  );
}

// Ships whose build installs no armor are left out: with no threshold there is
// nothing to pierce, and every weapon would read as getting through.
export function penetrationTargets(
  defenses: ModelDefense[] | undefined,
): PenetrationTarget[] {
  return (defenses || [])
    .map((model) => ({
      model,
      armor: armorStatsFrom(model.armor),
      shield: shieldStatsFrom(model.shields),
    }))
    .filter((target) => target.armor.hasData);
}

// The deflection check turned around: the weapons are fixed and the ships vary.
// A ship is pierced when any selected weapon pierces it, and ranked by the
// weapon that comes closest.
export function computePenetrationCheck(
  weapons: WeaponIndexItem[] | undefined,
  targets: PenetrationTarget[],
  shieldHealth: number,
  armorHealth: number,
): PenetrationSummary {
  const results: PenetrationResult[] = [];

  for (const target of targets) {
    const evaluated = (weapons || [])
      .map((weapon) =>
        evaluateWeapon(
          weapon,
          target.armor,
          target.shield,
          shieldHealth,
          armorHealth,
        ),
      )
      .filter((entry): entry is DeflectionResult => entry !== null)
      .sort((a, b) => byMargin(b, a));

    if (!evaluated.length) continue;

    const best = evaluated.find((entry) => entry.margin !== null) ?? null;

    let outcome: DeflectionOutcome = "absorbed";
    if (best) {
      outcome = evaluated.some((entry) => entry.outcome === "pierces")
        ? "pierces"
        : "deflected";
    }

    results.push({
      model: target.model,
      weapons: evaluated,
      best,
      margin: best?.margin ?? null,
      outcome,
    });
  }

  results.sort(byMargin);

  return {
    results,
    absorbedCount: results.filter((entry) => entry.outcome === "absorbed")
      .length,
    deflectedCount: results.filter((entry) => entry.outcome === "deflected")
      .length,
    pierceCount: results.filter((entry) => entry.outcome === "pierces").length,
  };
}

export function usePenetrationCheck(
  weapons: MaybeRefOrGetter<WeaponIndexItem[] | undefined>,
  targets: MaybeRefOrGetter<PenetrationTarget[]>,
  shieldHealth: MaybeRefOrGetter<number>,
  armorHealth: MaybeRefOrGetter<number>,
) {
  return computed(() =>
    computePenetrationCheck(
      toValue(weapons),
      toValue(targets),
      toValue(shieldHealth),
      toValue(armorHealth),
    ),
  );
}
