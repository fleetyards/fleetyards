import type { CompareDeltaTone } from "@/frontend/components/Compare/delta";

// One candidate for a socket, as plain data: the caller turns its own records
// (modules, weapons, ...) into these, so the picker never learns what it holds.
export interface LoadoutPickerOption {
  id: string;
  name: string;
  image?: string;
  manufacturer?: string;
  description?: string;
  owned?: boolean;
  stock?: boolean;
  // What the option brings, already formatted.
  figure?: string;
  // What fitting it changes against what the socket holds now.
  delta?: { label: string; tone: CompareDeltaTone };
  // A value per sort key the caller offers; options without one sort last.
  sortValues?: Record<string, number>;
}

export interface LoadoutPickerSort {
  key: string;
  label: string;
  // Highest first unless the caller says otherwise: most of what a ship is
  // fitted for reads better larger.
  ascending?: boolean;
}
