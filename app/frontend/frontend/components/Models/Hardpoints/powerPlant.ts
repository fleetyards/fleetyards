import type { ComputedRef, InjectionKey } from "vue";

export type PowerPlantContext = {
  count: number;
  sizeSum: number;
};

// Provided by the power-plant Category so each plant item can resolve its own
// pip share (pips are a ship-level value derived from every plant together).
export const powerPlantContextKey: InjectionKey<
  ComputedRef<PowerPlantContext | null>
> = Symbol("powerPlantContext");

// A single plant's share of the ship's power pips. Sums across all plants to the
// category total shown in the header (Math.round(powerBase / n) summed, plus the
// (n - 1) * Σsize coupling term split evenly by size).
export function powerPlantPips(
  powerBase: number,
  size: number,
  context: PowerPlantContext,
): number {
  return Math.round(powerBase / context.count) + (context.count - 1) * size;
}
