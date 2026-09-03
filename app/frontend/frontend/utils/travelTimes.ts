import { type Component, type ComponentQuantumDrive } from "@/services/fyApi";

const KM_PER_MKM = 1000000;

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

// The drive's rates are stored in metres and metres per second, the formula
// works in kilometres, and the tool asks for a distance in millions of them.
// Both the table cell and the sort go through here, so the two cannot drift
// onto different units.
export const quantumDriveTravelTime = (
  quantumDrive: Component,
  distanceInMkm: number,
): number | undefined => {
  const typeData = quantumDrive.typeData as ComponentQuantumDrive | undefined;

  if (!typeData?.driveSpeed) {
    return undefined;
  }

  return calculateTravelTime(
    (typeData.stageOneAccelRate || 0) / 1000,
    (typeData.stageTwoAccelRate || 0) / 1000,
    typeData.driveSpeed / 1000,
    distanceInMkm * KM_PER_MKM,
  );
};
