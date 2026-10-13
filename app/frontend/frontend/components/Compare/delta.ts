import type { CompareDirection } from "@/frontend/components/Compare/highlights";

export type CompareDeltaTone = "better" | "worse" | "even";

export interface CompareDelta {
  percent?: number;
  difference: number;
  tone: CompareDeltaTone;
}

const isComparable = (value: number | undefined): value is number =>
  typeof value === "number" && Number.isFinite(value);

const toneFor = (
  change: number,
  even: boolean,
  direction?: CompareDirection,
): CompareDeltaTone => {
  // A metric without a direction — mass, dimensions, crew — has no better or worse to
  // claim.
  if (even || !direction) {
    return "even";
  }

  const better = direction === "lower" ? change < 0 : change > 0;

  return better ? "better" : "worse";
};

// Distance from the chosen baseline, per cell. A row the baseline cannot anchor —
// textual values, no baseline picked, or a baseline of zero to divide by — yields no
// deltas at all, and that emptiness is what tells the table to keep rendering the values
// themselves rather than a column of em dashes.
//
// A count — crew, SCU, weapons — reads as a plain difference instead: 4 SCU against 1 SCU
// is "+3", which "+300%" makes a reader stop and work out. With no ratio to take, a
// baseline of zero anchors such a row too.
export function deltasAgainst(
  values: (number | undefined)[],
  baselineIndex: number,
  direction?: CompareDirection,
  counts = false,
): (CompareDelta | undefined)[] {
  const base = values[baselineIndex];

  if (baselineIndex < 0 || !isComparable(base) || (!counts && base === 0)) {
    return values.map(() => undefined);
  }

  return values.map((value) => {
    if (!isComparable(value)) {
      return undefined;
    }

    const difference = value - base;

    if (counts) {
      return {
        difference,
        tone: toneFor(difference, difference === 0, direction),
      };
    }

    const percent = (difference / Math.abs(base)) * 100;

    // Rounding hides anything under half a percent.
    return {
      percent,
      difference,
      tone: toneFor(percent, Math.abs(percent) < 0.5, direction),
    };
  });
}
