export type CompareDirection = "higher" | "lower";

export type CompareExtreme = "best" | "worst" | undefined;

const isComparable = (value: number | undefined): value is number =>
  typeof value === "number" && Number.isFinite(value);

// Marks the winning and losing cell of a compare row. Only metrics with an
// unambiguous direction get marked — "more mass" or "longer" is neither good nor
// bad, and a marker there would be an opinion the data does not support.
export function markExtremes(
  values: (number | undefined)[],
  direction?: CompareDirection,
): CompareExtreme[] {
  const unmarked: CompareExtreme[] = values.map(() => undefined);

  if (!direction) {
    return unmarked;
  }

  const comparable = values.filter(isComparable);

  // A single value has nothing to beat, and a row where everything ties has no
  // winner — marking one of them would be arbitrary.
  if (comparable.length < 2) {
    return unmarked;
  }

  const max = Math.max(...comparable);
  const min = Math.min(...comparable);

  if (max === min) {
    return unmarked;
  }

  const best = direction === "higher" ? max : min;
  const worst = direction === "higher" ? min : max;

  return values.map((value) => {
    if (!isComparable(value)) {
      return undefined;
    }

    if (value === best) {
      return "best";
    }

    if (value === worst) {
      return "worst";
    }

    return undefined;
  });
}
