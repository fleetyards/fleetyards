import type { MaybeRefOrGetter } from "vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useComlink } from "@/shared/composables/useComlink";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { useHangarPlanCache } from "@/frontend/composables/useHangarPlanCache";
import type { HangarFlowDecision } from "@/frontend/components/Hangar/Planner/HangarFlow/types";
import {
  type HangarPlan,
  type HangarPlanComparison,
  HangarPlanVehicleMarkEnum,
  HangarPlanVehicleStatusEnum,
  useCreateHangarPlanKeep,
  useCreateHangarPlanVehicleMark,
  useDestroyHangarPlanAcquisition,
  useDestroyHangarPlanMelt,
  useUpdateHangarPlanVehicleMark,
} from "@/services/fyApi";

// Settles the hangar ships a plan has not decided on, short of picking where
// they end up: keeps them as they are, opens the melt for one, or marks it to
// change.
export const useHangarPlanDecisions = (
  planId: MaybeRefOrGetter<string>,
  plan: MaybeRefOrGetter<HangarPlan | undefined>,
  comparison: MaybeRefOrGetter<HangarPlanComparison | undefined>,
) => {
  const { t } = useI18n();
  const comlink = useComlink();
  const { displayAlert } = useAppNotifications();
  const { updatePlan } = useHangarPlanCache();

  const keepMutation = useCreateHangarPlanKeep();
  const createMark = useCreateHangarPlanVehicleMark();
  const updateMark = useUpdateHangarPlanVehicleMark();
  const destroyMelt = useDestroyHangarPlanMelt();
  const destroyAcquisition = useDestroyHangarPlanAcquisition();

  const deciding = ref(false);

  const save = async (request: () => Promise<HangarPlan>) => {
    deciding.value = true;
    try {
      updatePlan(await request());
      return true;
    } catch {
      displayAlert({ text: t("hangarPlanner.messages.saveFailed") });
      return false;
    } finally {
      deciding.value = false;
    }
  };

  const keep = (vehicleIds: string[]) =>
    save(() =>
      keepMutation.mutateAsync({
        hangarPlanId: toValue(planId),
        data: { vehicleIds },
      }),
    );

  const mark = (vehicleId: string, value: HangarPlanVehicleMarkEnum) => {
    const existing = toValue(plan)?.vehicleMarks.find(
      (entry) => entry.vehicleId === vehicleId,
    );

    return save(() =>
      existing
        ? updateMark.mutateAsync({
            hangarPlanId: toValue(planId),
            id: existing.id,
            data: { mark: value },
          })
        : createMark.mutateAsync({
            hangarPlanId: toValue(planId),
            data: { vehicleId, mark: value },
          }),
    );
  };

  // Takes back whatever settled the ship, a melt or the route it starts, so
  // the plan asks about it again.
  const undecide = async (vehicleId: string) => {
    const current = toValue(plan);
    const melt = current?.melts.find((entry) => entry.vehicleId === vehicleId);
    const acquisition = current?.slots
      .flatMap((slot) => slot.candidates)
      .flatMap((candidate) => candidate.acquisitions)
      .find((entry) => entry.sourceVehicleId === vehicleId);

    if (
      melt &&
      !(await save(() =>
        destroyMelt.mutateAsync({ hangarPlanId: toValue(planId), id: melt.id }),
      ))
    ) {
      return;
    }

    if (
      acquisition &&
      !(await save(() =>
        destroyAcquisition.mutateAsync({
          hangarPlanId: toValue(planId),
          id: acquisition.id,
        }),
      ))
    ) {
      return;
    }

    await mark(vehicleId, HangarPlanVehicleMarkEnum.PENDING);
  };

  const decide = (vehicleId: string, decision: HangarFlowDecision) => {
    if (deciding.value) return;

    switch (decision) {
      case "keep":
        void keep([vehicleId]);
        break;
      case "change":
        void mark(vehicleId, HangarPlanVehicleMarkEnum.CHANGE);
        break;
      case "pending":
        void undecide(vehicleId);
        break;
      case "melt":
        comlink.emit("open-modal", {
          component: () =>
            import("@/frontend/components/Hangar/Planner/MeltModal/index.vue"),
          props: { planId: toValue(planId), vehicleId },
        });
        break;
    }
  };

  const pendingIds = computed(() =>
    (toValue(comparison)?.vehicles ?? [])
      .filter((entry) => entry.status === HangarPlanVehicleStatusEnum.PENDING)
      .map((entry) => entry.vehicleId),
  );

  return { deciding, decide, keep, pendingIds };
};
