// The grades in slot order, the way the recipe lists its slots.
export const craftedGrades = (
  qualities: Record<string | number, number | undefined>,
  format: (position: string, grade?: number) => string = (_, grade) =>
    String(grade),
) =>
  Object.entries(qualities)
    .sort(([a], [b]) => Number(a) - Number(b))
    .map(([position, grade]) => format(position, grade));
