import type { HangarPlanModel } from "@/services/fyApi";

// Whether a route can lead from one ship to another: it is the same ship, or
// an upgrade towards a dearer one where both take upgrades, since RSI sells
// none into or out of some ships. A ship without a known price is kept, as
// nothing rules it out.
export const reaches = (from: HangarPlanModel, to: HangarPlanModel) => {
  if (from.id === to.id) return true;
  if (!from.upgradable || !to.upgradable) return false;
  if (typeof from.pledgePrice !== "number") return true;
  if (typeof to.pledgePrice !== "number") return true;

  return from.pledgePrice < to.pledgePrice;
};
