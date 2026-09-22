import type { RouteLocationRaw } from "vue-router";

// A tone rather than the tenant's own vocabulary: blueprints and missions both
// label a row with a side of the law, and both paint lawful in the primary and
// outlaw in the danger colour. Naming the colours here keeps the row ignorant of
// what a "side of the law" is, and leaves a third tenant free to use the same
// two tones for something else.
export enum RowListItemTonesEnum {
  DEFAULT = "default",
  PRIMARY = "primary",
  DANGER = "danger",
}

// A labelled figure. `label` is optional because a badge that only marks a state
// -- "no known source", "unreleased" -- has nothing to name, and `quiet` is what
// those two look like: a dashed frame and an unemphasised value.
export type RowListItemBadge = {
  key: string;
  label?: string;
  value: string;
  quiet?: boolean;
};

// What the record is made of, or pays out in. Capped by the row, which appends a
// `+N` for the rest rather than letting the set grow the row unboundedly.
export type RowListItemChip = {
  key: string;
  label: string;
  to?: RouteLocationRaw;
};

export type RowListItemTag = {
  key: string;
  label: string;
  to?: RouteLocationRaw;
  tone?: RowListItemTonesEnum;
};
