import {
  type HangarPlanModel,
  type HangarPlanCandidate,
  HangarPlanCcuIntoEnum,
  HangarPlanCcuOutOfEnum,
} from "@/services/fyApi";

// Whether RSI sells upgrades out of or into a ship. A new ship nobody has
// seen one for yet is given the benefit of the doubt.
export const canLeave = (model: HangarPlanModel) =>
  model.ccuOutOf !== HangarPlanCcuOutOfEnum.NONE;

export const canEnter = (model: HangarPlanModel) =>
  model.ccuInto !== HangarPlanCcuIntoEnum.NONE;

// Some ships are reached only from a variant of their own hull, like the
// Kraken Privateer from the Kraken.
export const entersFrom = (from: HangarPlanModel, to: HangarPlanModel) =>
  !to.ccuIntoFrom || to.ccuIntoFrom.includes(from.id);

// Whether a route can lead from one ship to another: it is the same ship, or
// an upgrade towards a dearer one RSI sells upgrades out of and into. A ship
// without a known price is kept, as nothing rules it out.
export const reaches = (from: HangarPlanModel, to: HangarPlanModel) => {
  if (from.id === to.id) return true;
  if (!canLeave(from) || !canEnter(to) || !entersFrom(from, to)) return false;
  if (typeof from.pledgePrice !== "number") return true;
  if (typeof to.pledgePrice !== "number") return true;

  return from.pledgePrice < to.pledgePrice;
};

// A slot still choosing its ship keeps a start on the ship it comes closest to,
// and moves it to whichever ship the slot settles on later. A start none of them
// can be reached from stays on the cheapest, whose row then asks for another.
export const startHolder = (
  candidates: HangarPlanCandidate[],
  model?: HangarPlanModel,
) => {
  const reachable = candidates.filter(
    (candidate) => !model || reaches(model, candidate.model),
  );
  const cheapest = (list: HangarPlanCandidate[]) =>
    [...list].sort(
      (a, b) => (a.model.pledgePrice ?? 0) - (b.model.pledgePrice ?? 0),
    )[0];

  return (
    reachable.find((candidate) => candidate.model.id === model?.id) ??
    cheapest(reachable) ??
    cheapest(candidates)
  );
};

// The translation key for how sure an upgrade into a ship is, where it is not
// simply on sale.
export const ccuNote = (model: HangarPlanModel) => {
  switch (model.ccuInto) {
    case HangarPlanCcuIntoEnum.SALES_ONLY:
      return "hangarPlanner.pick.ccuSalesOnly";
    case HangarPlanCcuIntoEnum.UNKNOWN:
      return "hangarPlanner.pick.ccuUnknown";
    default:
      return undefined;
  }
};
