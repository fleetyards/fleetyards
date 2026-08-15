import type { CompareDirection } from "@/frontend/components/Compare/highlights";

export type CompareDeltaTone = "better" | "worse" | "even";

export interface CompareDelta {
  percent: number;
  tone: CompareDeltaTone;
}

const isComparable = (value: number | undefined): value is number =>
  typeof value === "number" && Number.isFinite(value);

// Distance from the chosen baseline, per cell. A row the baseline cannot anchor —
// textual values, no baseline picked, or a baseline of zero to divide by — yields no
// deltas at all, and that emptiness is what tells the table to keep rendering the values
// themselves rather than a column of em dashes.
export function deltasAgainst(
  values: (number | undefined)[],
  baselineIndex: number,
  direction?: CompareDirection,
): (CompareDelta | undefined)[] {
  const base = values[baselineIndex];

  if (baselineIndex < 0 || !isComparable(base) || base === 0) {
    return values.map(() => undefined);
  }

  return values.map((value) => {
    if (!isComparable(value)) {
      return undefined;
    }

    const percent = ((value - base) / Math.abs(base)) * 100;

    // Rounding hides anything under half a percent, and a metric without a direction —
    // mass, dimensions — has no better or worse to claim.
    if (Math.abs(percent) < 0.5 || !direction) {
      return { percent, tone: "even" };
    }

    const better = direction === "lower" ? percent < 0 : percent > 0;

    return { percent, tone: better ? "better" : "worse" };
  });
}
