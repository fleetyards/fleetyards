import { computed, toValue, type MaybeRefOrGetter } from "vue";
import { HardpointCategoryEnum, type Hardpoint } from "@/services/fyApi";

export type CountermeasureKind = "decoy" | "noise";

export type CountermeasureValue = {
  key: CountermeasureKind;
  label: string;
  value: number;
};

export type CountermeasureStats = {
  counts: CountermeasureValue[];
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

function collectAmmo(
  hardpoints: Hardpoint[] | undefined,
  totals: Record<CountermeasureKind, number>,
) {
  for (const hardpoint of hardpoints || []) {
    const component = hardpoint.component;

    if (hardpoint.category === HardpointCategoryEnum.COUNTERMEASURES) {
      const kind = countermeasureKind(component?.scKey);
      const maxAmmo = (component?.typeData as { maxAmmo?: number } | undefined)
        ?.maxAmmo;

      if (kind && maxAmmo) {
        totals[kind] += maxAmmo;
      }
    }

    collectAmmo(hardpoint.hardpoints, totals);
  }
}

export function computeCountermeasureStats(
  hardpoints: Hardpoint[] | undefined,
): CountermeasureStats {
  const totals: Record<CountermeasureKind, number> = { decoy: 0, noise: 0 };

  collectAmmo(hardpoints, totals);

  const counts = KINDS.map(({ key, label }) => ({
    key,
    label,
    value: totals[key],
  })).filter((entry) => entry.value > 0);

  return { counts, hasData: counts.length > 0 };
}

export function useCountermeasureStats(
  hardpoints: MaybeRefOrGetter<Hardpoint[] | undefined>,
) {
  return computed(() => computeCountermeasureStats(toValue(hardpoints)));
}
