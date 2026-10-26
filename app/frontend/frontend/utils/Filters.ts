import { type FilterOption } from "@/services/fyApi";

export function getFilters(formData: Record<string, unknown>) {
  const filters = JSON.parse(JSON.stringify(formData));

  Object.keys(filters)
    .filter((key) => !filters[key] || filters[key].length === 0)
    .forEach((key) => delete filters[key]);

  return filters;
}

export function isFilterSelected(routeFilters: Record<string, unknown>) {
  const filters = JSON.parse(JSON.stringify(routeFilters || {}));

  Object.keys(filters)
    .filter((key) => !filters[key] || filters[key].length === 0)
    .forEach((key) => delete filters[key]);

  return Object.keys(filters).length > 0;
}

// What survives of a selection once its options narrow, or undefined when all
// of it does. Without an answer yet there is nothing to narrow to.
export function keptOptions(
  chosen: string[] | undefined,
  options: Pick<FilterOption, "value">[] | undefined,
) {
  if (!options) return undefined;

  const available = new Set(options.map((option) => option.value));
  const selected = chosen || [];
  const kept = selected.filter((value) => available.has(value));

  return kept.length === selected.length ? undefined : kept;
}
