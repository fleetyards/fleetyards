import { type HardpointStat } from "@/frontend/composables/useHardpointStats";

/**
 * The stats of a record that differs from the catalogue's -- a crafted part --
 * each marked with the catalogue's figure where the two disagree, so the card
 * can say which ones crafting moved.
 */
export const markedAgainstStock = (
  stats: HardpointStat[],
  stock?: HardpointStat[],
) => {
  if (!stock) return stats;

  const byKey = new Map(stock.map((stat) => [stat.key ?? stat.label, stat]));

  return stats.map((stat) => {
    const original = byKey.get(stat.key ?? stat.label);

    return original && original.value !== stat.value
      ? { ...stat, stock: original.value }
      : stat;
  });
};
