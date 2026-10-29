import type { MaybeRefOrGetter } from "vue";
import { usePlanMoney } from "@/frontend/components/Hangar/Planner/format";
import type { HangarPlanCandidate } from "@/services/fyApi";

// Side by side, the figure that wins its row is marked so the trade-off reads
// without comparing every number by eye. One candidate has nothing to beat.
export const useCandidateSpecs = (
  candidates: MaybeRefOrGetter<HangarPlanCandidate[]>,
) => {
  const { money } = usePlanMoney();

  const best = computed(() => {
    const models = toValue(candidates).map((candidate) => candidate.model);
    const prices = models
      .map((model) => model.pledgePrice)
      .filter((price): price is number => typeof price === "number");
    const cargos = models
      .map((model) => model.cargo)
      .filter(
        (cargo): cargo is number => typeof cargo === "number" && cargo > 0,
      );

    return {
      price: prices.length > 1 ? Math.min(...prices) : undefined,
      cargo: cargos.length > 1 ? Math.max(...cargos) : undefined,
    };
  });

  const specs = (candidate: HangarPlanCandidate) => {
    const model = candidate.model;

    return [
      {
        key: "price",
        value: money(model.pledgePrice),
        best:
          best.value.price !== undefined &&
          model.pledgePrice === best.value.price,
      },
      {
        key: "cargo",
        value: model.cargo ? `${model.cargo} SCU` : "–",
        best:
          best.value.cargo !== undefined && model.cargo === best.value.cargo,
      },
      { key: "crew", value: model.crew ?? "–", best: false },
      { key: "size", value: model.size ?? "–", best: false },
    ];
  };

  return { specs };
};
