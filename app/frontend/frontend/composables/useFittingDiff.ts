import { useI18n } from "@/shared/composables/useI18n";
import { UNINFORMATIVE } from "@/frontend/composables/useModuleContents";
import type { ModelModule } from "@/services/fyApi";

export type FittingChange = {
  key: string;
  label: string;
  delta: number;
};

type Effect = Map<string, number>;

const CARGO = "cargo";

// What a module brings to the ship: its cargo, and the hardpoints it adds,
// counted by category. The same reading `useModuleContents` summarises.
const moduleEffect = (mod: ModelModule): Effect => {
  const effect: Effect = new Map();

  if (mod.metrics?.cargo) {
    effect.set(CARGO, mod.metrics.cargo);
  }

  (mod.hardpoints || []).forEach((hardpoint) => {
    const category = hardpoint.category;
    if (!category || UNINFORMATIVE.includes(category)) {
      return;
    }

    effect.set(category, (effect.get(category) || 0) + 1);
  });

  return effect;
};

const combine = (modules: ModelModule[]): Effect =>
  modules.reduce<Effect>((total, mod) => {
    moduleEffect(mod).forEach((amount, key) => {
      total.set(key, (total.get(key) || 0) + amount);
    });
    return total;
  }, new Map());

/**
 * Every stat a change of fitting moves, as plus and minus values: what the
 * ship gains and loses going from one set of fitted items to another. The
 * editor reads it per option and for the whole loadout against the saved one.
 */
export const useFittingDiff = () => {
  const { t, toNumber } = useI18n();

  const label = (key: string, delta: number) => {
    const sign = delta > 0 ? "+" : "−";
    const amount = Math.abs(delta);

    if (key === CARGO) {
      return `${sign}${toNumber(amount, "cargo")}`;
    }

    return `${sign}${amount} × ${t(`labels.hardpoint.categories.${key}`)}`;
  };

  const diff = (from: ModelModule[], to: ModelModule[]): FittingChange[] => {
    const before = combine(from);
    const after = combine(to);
    const keys = [...new Set([...before.keys(), ...after.keys()])];

    return keys
      .map((key) => ({
        key,
        delta: (after.get(key) || 0) - (before.get(key) || 0),
      }))
      .filter((change) => change.delta !== 0)
      .sort((a, b) =>
        a.key === CARGO ? -1 : b.key === CARGO ? 1 : a.key.localeCompare(b.key),
      )
      .map((change) => ({ ...change, label: label(change.key, change.delta) }));
  };

  return { diff };
};
