import { computed, toValue, type MaybeRefOrGetter } from "vue";
import {
  HardpointCategoryEnum,
  type ComponentWeapon,
  type Hardpoint,
} from "@/services/fyApi";

export type CountermeasureKind = "decoy" | "noise";

export type CountermeasureValue = {
  key: CountermeasureKind;
  label: string;
  value: number;
};

export type CountermeasureDuration = {
  key: CountermeasureKind;
  label: string;
  min: number;
  max: number;
};

export type CountermeasureStats = {
  counts: CountermeasureValue[];
  durations: CountermeasureDuration[];
  hasData: boolean;
};

const KINDS: { key: CountermeasureKind; label: string; pattern: RegExp }[] = [
  {
    key: "decoy",
    label: "labels.defense.countermeasure.decoy",
    pattern: /flare|decoy/i,
  },
  {
    key: "noise",
    label: "labels.defense.countermeasure.noise",
    pattern: /chaff|noise/i,
  },
];

// The display name cannot tell the two apart — several decoy launchers are
// named "Noise Launcher" and some carry no name at all — but the item key
// always says flare/decoy or chaff/noise.
export function countermeasureKind(
  scKey: string | undefined,
): CountermeasureKind | undefined {
  if (!scKey) return undefined;

  return KINDS.find((kind) => kind.pattern.test(scKey))?.key;
}

type Durations = Record<CountermeasureKind, number[]>;

function collectAmmo(
  hardpoints: Hardpoint[] | undefined,
  totals: Record<CountermeasureKind, number>,
  durations: Durations,
) {
  for (const hardpoint of hardpoints || []) {
    const component = hardpoint.component;

    if (hardpoint.category === HardpointCategoryEnum.COUNTERMEASURES) {
      const typeData = component?.typeData as ComponentWeapon | undefined;
      // The parsed ammo says what the launcher fires; the key is the fallback
      // for a launcher loaded before the ammo was parsed.
      const kind =
        typeData?.countermeasure?.kind || countermeasureKind(component?.scKey);

      if (kind && typeData?.maxAmmo) {
        totals[kind] += typeData.maxAmmo;
      }
      if (kind && typeData?.countermeasure?.lifetime) {
        durations[kind].push(typeData.countermeasure.lifetime);
      }
    }

    collectAmmo(hardpoint.hardpoints, totals, durations);
  }
}

export function computeCountermeasureStats(
  hardpoints: Hardpoint[] | undefined,
): CountermeasureStats {
  const totals: Record<CountermeasureKind, number> = { decoy: 0, noise: 0 };
  const lifetimes: Durations = { decoy: [], noise: [] };

  collectAmmo(hardpoints, totals, lifetimes);

  const counts = KINDS.map(({ key, label }) => ({
    key,
    label,
    value: totals[key],
  })).filter((entry) => entry.value > 0);

  const durations = KINDS.filter(({ key }) => lifetimes[key].length).map(
    ({ key, label }) => ({
      key,
      label,
      min: Math.min(...lifetimes[key]),
      max: Math.max(...lifetimes[key]),
    }),
  );

  return {
    counts,
    durations,
    hasData: counts.length > 0 || durations.length > 0,
  };
}

export function useCountermeasureStats(
  hardpoints: MaybeRefOrGetter<Hardpoint[] | undefined>,
) {
  return computed(() => computeCountermeasureStats(toValue(hardpoints)));
}
