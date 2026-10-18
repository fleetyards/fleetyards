import type { CompareDeltaTone } from "@/frontend/components/Compare/delta";

export interface FigureDelta {
  deltaLabel?: string;
  tone?: CompareDeltaTone;
}

/**
 * How far a figure moved, as the loadout editor labels it everywhere: a
 * percentage of where it was, or the plain difference from nothing. A move too
 * small to read as one -- "+0%" -- is no move.
 */
export const figureDelta = (
  before: number | undefined,
  after: number | undefined,
  lowerIsBetter: boolean,
  formatDifference: (value: number) => string,
): FigureDelta => {
  if (before === undefined || after === undefined) return {};

  const difference = after - before;
  const percent = before ? Math.round(Math.abs(difference / before) * 100) : 0;
  // From nothing, a move counts once it reads as one in the caller's format:
  // a whole-number figure going from 0 to 0.3 is no "+0".
  const shown = before
    ? percent !== 0
    : formatDifference(Math.abs(difference)) !== formatDifference(0);
  if (!shown) return {};

  const sign = difference > 0 ? "+" : "−";
  const better = lowerIsBetter ? difference < 0 : difference > 0;

  return {
    deltaLabel: before
      ? `${sign}${percent}%`
      : `${sign}${formatDifference(Math.abs(difference))}`,
    tone: better ? "better" : "worse",
  };
};
