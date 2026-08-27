import { computed, toValue, type MaybeRefOrGetter } from "vue";
import type { ModelHullPart } from "@/services/fyApi";

export const HULL_CATEGORY_ORDER = [
  "vital",
  "secondary",
  "breakable",
  "subpart",
  "cosmetic",
] as const;

export const HULL_CATEGORY_COLORS: Record<string, string> = {
  vital: "#d76a6a",
  secondary: "#c67c7a",
  breakable: "#b18e8d",
  subpart: "#96898a",
  cosmetic: "#5f6467",
};

export type HullPartGroup = {
  category: string;
  label: string;
  parts: ModelHullPart[];
  total: number;
};

export function humanizeHullPart(name: string) {
  return name
    .replace(/^(dbr|lg)_/, "")
    .replace(/_/g, " ")
    .replace(/\b\w/g, (char) => char.toUpperCase());
}

export function computeHullPartGroups(
  parts: ModelHullPart[] | undefined,
): HullPartGroup[] {
  return HULL_CATEGORY_ORDER.map((category) => {
    const grouped = (parts || [])
      .filter((part) => part.category === category)
      .sort((a, b) => b.health - a.health);

    return {
      category,
      label: `labels.hull.category.${category}`,
      parts: grouped,
      total: grouped.reduce((sum, part) => sum + part.health, 0),
    };
  }).filter((group) => group.parts.length > 0);
}

export function useHullParts(
  parts: MaybeRefOrGetter<ModelHullPart[] | undefined>,
) {
  const groups = computed(() => computeHullPartGroups(toValue(parts)));

  // Cosmetic parts carry no health, so they would contribute a zero-width
  // segment — keep them in `groups` for the tally but out of the bar.
  const composition = computed(() =>
    groups.value
      .filter((group) => group.total > 0)
      .map((group) => ({
        key: group.category,
        label: group.label,
        value: group.total,
        color: HULL_CATEGORY_COLORS[group.category],
      })),
  );

  // Flat, heaviest first. The game files give us no parent/child links, so a
  // ranked list is the closest we can get to erkul's structural tree.
  const rankedParts = computed(() =>
    [...(toValue(parts) || [])].sort((a, b) => b.health - a.health),
  );

  const totalHealth = computed(() =>
    rankedParts.value.reduce((sum, part) => sum + part.health, 0),
  );

  const maxPartHealth = computed(() => rankedParts.value[0]?.health ?? 0);

  return { groups, composition, rankedParts, totalHealth, maxPartHealth };
}
