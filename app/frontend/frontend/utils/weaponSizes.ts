import type { WeaponSizeCount } from "@/services/fyApi";

// The guns a ship carries as one line, largest first: `2×S3 · 4×S2`.
export const formatWeaponSizes = (sizes: WeaponSizeCount[] | undefined) =>
  [...(sizes ?? [])]
    .sort((a, b) => b.size - a.size)
    .map(({ size, count }) => `${count}×S${size}`)
    .join(" · ");
