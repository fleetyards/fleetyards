export const calculateTravelTime = (
  a1: number,
  a2: number,
  vmax: number,
  distance: number,
) => {
  const dc = distance - (4 * vmax ** 2 * (2 * a1 + a2)) / (3 * (a1 + a2) ** 2);

  if (dc < 0) {
    // drive does not reach vmax

    const z =
      (3 * (a2 - a1) ** 2 * (a1 + a2) ** 2 * distance) /
        (8 * vmax ** 2 * a1 ** 3) -
      1;

    if (z > 1) {
      return (
        ((4 * a1 * vmax) / (a2 ** 2 - a1 ** 2)) *
        (2 * Math.cosh(-Math.log(z - Math.sqrt(z ** 2 - 1)) / 3) - 1)
      );
    }

    return (
      ((4 * a1 * vmax) / (a2 ** 2 - a1 ** 2)) *
      (2 * Math.cos((1 / 3) * Math.acos(z)) - 1)
    );
  }

  // drive reaches vmax
  return (
    (4 * vmax) / (a1 + a2) +
    distance / vmax -
    (4 * vmax * (2 * a1 + a2)) / (3 * (a1 + a2) ** 2)
  );
};
