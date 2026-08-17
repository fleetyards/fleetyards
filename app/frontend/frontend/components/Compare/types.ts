import type { CompareDirection } from "@/frontend/components/Compare/highlights";
import type { Hardpoint, HardpointCategoryEnum } from "@/services/fyApi";

// Every section resolves to rows of already-computed cells, one per compared ship, so a
// single table component can render all of them. The alternative — a component per
// section — is what forced a card frame per section, and that frame is the box the frozen
// label rail kept sliding out from under.

export type CompareChip = {
  key: string;
  label: string;
  value: string;
  // A type the shield fails to fully soak, or armor amplifies instead of reducing.
  negative?: boolean;
};

export type CompareSegment = {
  key: string;
  label: string;
  value: number;
  color: string;
};

export type CompareLegendEntry = {
  key: string;
  label: string;
  color: string;
};

export type CompareValueCell = {
  key: string;
  value?: string;
  // What the row ranks by, when that differs from the display value.
  raw?: number;
};

export type CompareTableRow =
  | {
      kind: "value";
      key: string;
      label: string;
      unit?: string;
      html?: boolean;
      direction?: CompareDirection;
      cells: CompareValueCell[];
    }
  | {
      kind: "chips";
      key: string;
      label: string;
      cells: { key: string; chips: CompareChip[] }[];
    }
  | {
      kind: "composition";
      key: string;
      label: string;
      legend: CompareLegendEntry[];
      cells: { key: string; segments: CompareSegment[] }[];
    }
  | {
      kind: "view";
      key: string;
      label: string;
      cells: { key: string; src?: string; alt: string; widthPercent: number }[];
    }
  // Carries the hardpoints themselves so the cell can render the ship page's own
  // `HardpointItems`, which groups by stack and dispatches the per-category item
  // variants. Re-describing components here would drift from that within a release.
  | {
      kind: "fit";
      key: string;
      label: string;
      category: HardpointCategoryEnum;
      cells: { key: string; hardpoints: Hardpoint[] }[];
    };

export type CompareSection = {
  id: string;
  title: string;
  rows: CompareTableRow[];
};

// One metric declared against whatever subject a section compares — usually a `Model`,
// but Combat/Defense/Hull compare derived stat objects.
export type CompareMetric<T> = {
  key: string;
  label: string;
  unit?: string;
  // `toUEC` and friends return markup, so a few rows need v-html.
  html?: boolean;
  // Omitted ⇒ the row is never marked best/worst. See `markExtremes`.
  direction?: CompareDirection;
  raw?: (subject: T) => number | undefined;
  value: (subject: T) => string | undefined;
  // Drops the row when no compared ship has anything to show for it, e.g. ground
  // speeds in a set of flight-ready ships.
  visible?: (subjects: T[]) => boolean;
};

export type CompareSubject<T> = {
  key: string;
  subject: T;
};

export function valueRows<T>(
  metrics: CompareMetric<T>[],
  subjects: CompareSubject<T>[],
): CompareTableRow[] {
  const values = subjects.map((entry) => entry.subject);

  return metrics
    .filter((metric) => !metric.visible || metric.visible(values))
    .map((metric) => ({
      kind: "value" as const,
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

export function hasRowData(rows: CompareTableRow[]): boolean {
  return rows.some((row) => {
    switch (row.kind) {
      case "value":
        return row.cells.some((cell) => !!cell.value);
      case "chips":
        return row.cells.some((cell) => cell.chips.length > 0);
      case "composition":
        return row.cells.some((cell) => cell.segments.length > 0);
      case "view":
        return row.cells.some((cell) => !!cell.src);
      case "fit":
        return row.cells.some((cell) => cell.hardpoints.length > 0);
    }
  });
}

// Backs the "differences only" filter: with eight ships most rows are the interesting
// ones and the rest are filler. Silhouettes and composition bars never count as uniform —
// comparing those by eye is the whole point of the row.
export function rowIsUniform(row: CompareTableRow): boolean {
  if (row.kind === "view" || row.kind === "composition") {
    return false;
  }

  // Switch on the row's kind rather than duck-typing the cell: `value` is optional, so
  // an `in` check never narrows `CompareValueCell` out of the union.
  const fingerprints =
    row.kind === "value"
      ? row.cells.map((cell) => cell.value ?? "")
      : row.kind === "chips"
        ? row.cells.map((cell) =>
            cell.chips.map((chip) => `${chip.key}:${chip.value}`).join("|"),
          )
        : row.cells.map((cell) =>
            cell.hardpoints
              .map(
                (hardpoint) =>
                  `${hardpoint.component?.size ?? ""}:${hardpoint.component?.name ?? ""}`,
              )
              .sort()
              .join("|"),
          );

  return new Set(fingerprints).size === 1;
}
