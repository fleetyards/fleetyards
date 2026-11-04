import type { Vector3 } from "three";

// Scales a holo so its grid cells read in metres. A holo's length lies on z, its
// nose towards -Z; neither x nor the longest side will do, as a Corsair is wider
// than it is long.
export const gridScale = (size: Vector3, length: number) => length / size.z;
