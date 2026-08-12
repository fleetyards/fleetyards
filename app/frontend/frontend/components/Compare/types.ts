import type { CompareDirection } from "@/frontend/components/Compare/highlights";

// One metric row, declared against whatever subject the section compares —
// usually a `Model`, but Combat/Defense/Hull compare derived stat objects.
export type CompareMetric<T> = {
  key: string;
  label: string;
  unit?: string;
  // `toUEC` and friends return markup, so a few rows need v-html.
  html?: boolean;
  // Omitted ⇒ the row is never marked best/worst. See `markExtremes`.
  direction?: CompareDirection;
  // The numeric value the row is ranked by, when that differs from the display
  // value (formatted strings don't sort).
  raw?: (subject: T) => number | undefined;
  value: (subject: T) => string | undefined;
  // Drops the row entirely when no compared ship has anything to show for it,
  // e.g. ground speeds in a set of flight-ready ships.
  visible?: (subjects: T[]) => boolean;
};

export type CompareSubject<T> = {
  key: string;
  subject: T;
};

export type CompareCell = {
  key: string;
  value?: string;
  raw?: number;
};

export type CompareRow = {
  key: string;
  label: string;
  unit?: string;
  html?: boolean;
  direction?: CompareDirection;
  cells: CompareCell[];
};

export function buildCompareRows<T>(
  metrics: CompareMetric<T>[],
  subjects: CompareSubject<T>[],
): CompareRow[] {
  const values = subjects.map((entry) => entry.subject);

  return metrics
    .filter((metric) => !metric.visible || metric.visible(values))
    .map((metric) => ({
      key: metric.key,
      label: metric.label,
      unit: metric.unit,
      html: metric.html,
      direction: metric.direction,
      cells: subjects.map((entry) => ({
        key: entry.key,
        value: metric.value(entry.subject),
        raw: metric.raw?.(entry.subject),
      })),
    }));
}

// Multi-valued rows (shield resistances, armor deflection, …) can't be ranked,
// so they carry no direction — they render as chip lists per ship.
export type CompareChip = {
  key: string;
  label: string;
  value: string;
  // A type the shield fails to fully soak, or armor amplifies instead of
  // reducing — the same "weakness" flag DefenseMetrics paints red.
  negative?: boolean;
};

export type CompareChipsRow = {
  key: string;
  label: string;
  cells: {
    key: string;
    chips: CompareChip[];
  }[];
};

export function hasCompareChips(row: CompareChipsRow): boolean {
  return row.cells.some((cell) => cell.chips.length > 0);
}

export function hasCompareData(rows: CompareRow[]): boolean {
  return rows.some((row) =>
    row.cells.some((cell) => cell.value !== undefined && cell.value !== ""),
  );
}
