import { useI18n } from "@/shared/composables/useI18n";
import { UNINFORMATIVE } from "@/frontend/composables/useModuleContents";
import {
  type CompareDelta,
  deltasAgainst,
} from "@/frontend/components/Compare/delta";
import type { CompareDirection } from "@/frontend/components/Compare/highlights";
import type { ModelModule } from "@/services/fyApi";

// What a fitting adds up to on the ship, by metric.
export type FittingMetrics = Map<string, number>;

export type FittingRow = {
  key: string;
  label: string;
  before: number;
  after: number;
  value: string;
  delta?: CompareDelta;
  deltaLabel?: string;
};

const CARGO = "cargo";

// Directions as the compare tool sets them: more cargo is better; how many
// hardpoints of a kind a module brings is neither better nor worse.
const DIRECTIONS: Record<string, CompareDirection | undefined> = {
  [CARGO]: "higher",
};

/**
 * The ship's figures under a fitting and the change from one fitting to
 * another, read the way the compare tool reads two ships: a value, a signed
 * difference and whether that is better or worse. Cargo is the hull's hold
 * plus what the modules carry; hardpoints are what the modules bring.
 */
export const useFittingDiff = () => {
  const { t, toNumber } = useI18n();

  const metrics = (hullCargo: number, modules: ModelModule[]) => {
    const totals: FittingMetrics = new Map([[CARGO, hullCargo]]);

    modules.forEach((mod) => {
      totals.set(CARGO, (totals.get(CARGO) || 0) + (mod.metrics?.cargo || 0));

      (mod.hardpoints || []).forEach((hardpoint) => {
        const category = hardpoint.category;
        if (!category || UNINFORMATIVE.includes(category)) {
          return;
        }

        totals.set(category, (totals.get(category) || 0) + 1);
      });
    });

    return totals;
  };

  const labelFor = (key: string) =>
    key === CARGO
      ? t("labels.model.cargo")
      : t(`labels.hardpoint.categories.${key}`);

  const format = (key: string, amount: number) =>
    key === CARGO ? String(toNumber(amount, "cargo")) : String(amount);

  const signed = (key: string, difference: number) =>
    `${difference > 0 ? "+" : "−"}${format(key, Math.abs(difference))}`;

  // Every metric either fitting has, cargo first; a metric neither touches
  // is left out rather than listed as "no change".
  const rows = (before: FittingMetrics, after: FittingMetrics): FittingRow[] =>
    [...new Set([...before.keys(), ...after.keys()])]
      .filter((key) =>
        key === CARGO ? before.get(key) || 0 || after.get(key) || 0 : true,
      )
      .sort((a, b) => (a === CARGO ? -1 : b === CARGO ? 1 : a.localeCompare(b)))
      .map((key) => {
        const from = before.get(key) || 0;
        const to = after.get(key) || 0;
        const [, delta] = deltasAgainst([from, to], 0, DIRECTIONS[key], true);

        return {
          key,
          label: labelFor(key),
          before: from,
          after: to,
          value: format(key, to),
          delta,
          deltaLabel: delta?.difference
            ? signed(key, delta.difference)
            : undefined,
        };
      });

  return { metrics, rows };
};
