import { useQueryClient } from "@tanstack/vue-query";
import { type HangarPlan, getHangarPlanQueryKey } from "@/services/fyApi";

// Every edit answers with the whole plan, so the editor takes it as the new
// state and only refetches what is derived from it: summary, comparison, drift
// and the resources the plan uses up. The list is matched exactly, since its
// key prefixes every plan's own.
export const useHangarPlanCache = () => {
  const queryClient = useQueryClient();

  const refreshDerived = (planId: string) => {
    void queryClient.invalidateQueries({
      predicate: (query) =>
        query.queryKey[0] === "hangar" &&
        query.queryKey[1] === "plans" &&
        query.queryKey[2] === planId &&
        query.queryKey.length > 3,
    });
    void queryClient.invalidateQueries({
      queryKey: ["hangar", "plans"],
      exact: true,
    });
  };

  const updatePlan = (plan: HangarPlan) => {
    queryClient.setQueryData(getHangarPlanQueryKey(plan.id), plan);
    refreshDerived(plan.id);
  };

  return { updatePlan, refreshDerived };
};
