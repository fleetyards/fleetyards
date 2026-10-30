import type { MaybeRefOrGetter } from "vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { useHangarPlanCache } from "@/frontend/composables/useHangarPlanCache";
import {
  type HangarPlan,
  type HangarPlanAcquisition,
  type HangarPlanCandidate,
  HangarPlanStartKindEnum,
  HangarPlanVehicleMarkEnum,
  useCreateHangarPlanAcquisition,
  useCreateHangarPlanCandidate,
  useCreateHangarPlanKeep,
  useCreateHangarPlanSlot,
  useCreateHangarPlanVehicleMark,
  useDestroyHangarPlanAcquisition,
  useUpdateHangarPlanAcquisition,
  useUpdateHangarPlanVehicleMark,
} from "@/services/fyApi";

export type HangarPlanStart =
  | { kind: "owned"; vehicleId: string }
  | { kind: "buyback"; pledgeId: string; modelId: string }
  | { kind: "store" };

export type HangarPlanEnd =
  | { kind: "same" }
  | { kind: "candidate"; candidate: HangarPlanCandidate }
  | { kind: "model"; modelId: string; name: string }
  | { kind: "remove" };

// Pairs a start with an end ship of the plan. Changing either end drops the
// upgrades planned between them, since they no longer lead from one to the
// other; the pairing then waits for its route, unless both ends are one ship.
export const useHangarPlanPairing = (
  planId: MaybeRefOrGetter<string>,
  plan: MaybeRefOrGetter<HangarPlan | undefined>,
) => {
  const { t } = useI18n();
  const { displayAlert } = useAppNotifications();
  const { updatePlan } = useHangarPlanCache();

  const createAcquisition = useCreateHangarPlanAcquisition();
  const updateAcquisition = useUpdateHangarPlanAcquisition();
  const destroyAcquisition = useDestroyHangarPlanAcquisition();
  const createSlot = useCreateHangarPlanSlot();
  const createCandidate = useCreateHangarPlanCandidate();
  const keepMutation = useCreateHangarPlanKeep();
  const createMark = useCreateHangarPlanVehicleMark();
  const updateMark = useUpdateHangarPlanVehicleMark();

  const pairing = ref(false);

  const run = async (work: () => Promise<void>) => {
    if (pairing.value) return false;

    pairing.value = true;
    try {
      await work();
      return true;
    } catch {
      displayAlert({ text: t("hangarPlanner.messages.saveFailed") });
      return false;
    } finally {
      pairing.value = false;
    }
  };

  const hangarPlanId = () => toValue(planId);

  const startData = (
    start: HangarPlanStart,
    candidate: HangarPlanCandidate,
  ) => {
    switch (start.kind) {
      case "owned":
        return {
          startKind: HangarPlanStartKindEnum.OWNED,
          sourceVehicleId: start.vehicleId,
          buybackPledgeId: null,
          startModelId: null,
        };
      case "buyback":
        return {
          startKind: HangarPlanStartKindEnum.BUYBACK,
          sourceVehicleId: null,
          buybackPledgeId: start.pledgeId,
          startModelId: start.modelId,
        };
      default:
        return {
          startKind: HangarPlanStartKindEnum.STORE,
          sourceVehicleId: null,
          buybackPledgeId: null,
          startModelId: candidate.model.id,
        };
    }
  };

  const pairStart = (
    candidate: HangarPlanCandidate,
    start: HangarPlanStart,
    acquisition?: HangarPlanAcquisition,
  ) =>
    run(async () => {
      updatePlan(
        acquisition
          ? await updateAcquisition.mutateAsync({
              hangarPlanId: hangarPlanId(),
              id: acquisition.id,
              data: { ...startData(start, candidate), steps: [] },
            })
          : await createAcquisition.mutateAsync({
              hangarPlanId: hangarPlanId(),
              data: {
                candidateId: candidate.id,
                ...startData(start, candidate),
              },
            }),
      );
    });

  const candidateFor = async (modelId: string, name: string) => {
    const withSlot = await createSlot.mutateAsync({
      hangarPlanId: hangarPlanId(),
      data: { label: name },
    });
    updatePlan(withSlot);
    const slotId = withSlot.slots.at(-1)?.id as string;

    const withCandidate = await createCandidate.mutateAsync({
      hangarPlanId: hangarPlanId(),
      data: { slotId, modelId },
    });
    updatePlan(withCandidate);

    return withCandidate.slots.find((slot) => slot.id === slotId)
      ?.candidates[0] as HangarPlanCandidate;
  };

  const mark = async (vehicleId: string, value: HangarPlanVehicleMarkEnum) => {
    const existing = toValue(plan)?.vehicleMarks.find(
      (entry) => entry.vehicleId === vehicleId,
    );

    updatePlan(
      existing
        ? await updateMark.mutateAsync({
            hangarPlanId: hangarPlanId(),
            id: existing.id,
            data: { mark: value },
          })
        : await createMark.mutateAsync({
            hangarPlanId: hangarPlanId(),
            data: { vehicleId, mark: value },
          }),
    );
  };

  const release = async (acquisition?: HangarPlanAcquisition) => {
    if (!acquisition) return;

    updatePlan(
      await destroyAcquisition.mutateAsync({
        hangarPlanId: hangarPlanId(),
        id: acquisition.id,
      }),
    );
  };

  // The end of a route: a hangar ship's own model when it is kept, a ship of
  // the plan, or a new ship that gets a slot of its own.
  const pairEnd = (
    end: HangarPlanEnd,
    {
      vehicleId,
      acquisition,
    }: { vehicleId?: string; acquisition?: HangarPlanAcquisition },
  ) =>
    run(async () => {
      if (end.kind === "same" || end.kind === "remove") {
        await release(acquisition);
        if (vehicleId) {
          if (end.kind === "same") {
            updatePlan(
              await keepMutation.mutateAsync({
                hangarPlanId: hangarPlanId(),
                data: { vehicleIds: [vehicleId] },
              }),
            );
          } else {
            await mark(vehicleId, HangarPlanVehicleMarkEnum.PENDING);
          }
        }
        return;
      }

      const candidate =
        end.kind === "candidate"
          ? end.candidate
          : await candidateFor(end.modelId, end.name);

      if (acquisition) {
        updatePlan(
          await updateAcquisition.mutateAsync({
            hangarPlanId: hangarPlanId(),
            id: acquisition.id,
            data: { candidateId: candidate.id, steps: [] },
          }),
        );
      } else if (vehicleId) {
        updatePlan(
          await createAcquisition.mutateAsync({
            hangarPlanId: hangarPlanId(),
            data: {
              candidateId: candidate.id,
              ...startData({ kind: "owned", vehicleId }, candidate),
            },
          }),
        );
      }
    });

  return { pairing, pairStart, pairEnd };
};
