export const hasFilterValue = (value: unknown) =>
  value != null && value !== "" && (!Array.isArray(value) || value.length > 0);

export const hasActiveFilters = (filters: object, keys: string[]) =>
  keys.some((key) => hasFilterValue((filters as Record<string, unknown>)[key]));
