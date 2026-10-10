// A table column whose key changed leaves the old key in every visitor's
// persisted choice, where it matches no column and the column silently drops out
// of their table. Each old key is swapped for its replacement, once.
export const renameTableCols = <T extends string>(
  cols: string[],
  renames: Record<string, T>,
): T[] => [...new Set(cols.map((col) => renames[col] ?? col))] as T[];
