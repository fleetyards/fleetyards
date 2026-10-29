<script lang="ts">
export default {
  name: "HangarPlannerUpgradeTargetModal",
};
</script>

<script lang="ts" setup>
import PickerModal from "@/frontend/components/Models/PickerModal/index.vue";
import { type ModelPickerSelection } from "@/frontend/components/Models/PickerModal/types";
import { useComlink } from "@/shared/composables/useComlink";
import { useI18n } from "@/shared/composables/useI18n";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { useHangarPlanCache } from "@/frontend/composables/useHangarPlanCache";
import {
  type HangarPlan,
  useCreateHangarPlanCandidate,
  useCreateHangarPlanSlot,
} from "@/services/fyApi";

type Props = {
  planId: string;
  vehicleId: string;
  vehicleName: string;
};

const props = defineProps<Props>();

const { t } = useI18n();
const comlink = useComlink();
const { displayAlert } = useAppNotifications();
const { updatePlan } = useHangarPlanCache();

const submitting = ref(false);
const createSlot = useCreateHangarPlanSlot();
const createCandidate = useCreateHangarPlanCandidate();

const slotIds = (plan: HangarPlan) => plan.slots.map((slot) => slot.id);

// The target gets a slot of its own, then the route from the ship to it is
// planned like any other.
const submit = async ([selection]: ModelPickerSelection[]) => {
  if (!selection) return;

  submitting.value = true;

  try {
    const before = await createSlot.mutateAsync({
      hangarPlanId: props.planId,
      data: { label: selection.option.name },
    });
    const slotId = slotIds(before).at(-1) as string;
    const plan = await createCandidate.mutateAsync({
      hangarPlanId: props.planId,
      data: { slotId, modelId: selection.option.id },
    });
    updatePlan(plan);

    const candidate = plan.slots.find((slot) => slot.id === slotId)
      ?.candidates[0];
    if (!candidate) return;

    comlink.emit("open-modal", {
      component: () =>
        import("@/frontend/components/Hangar/Planner/RouteModal/index.vue"),
      props: { planId: props.planId, candidate, vehicleId: props.vehicleId },
      wide: true,
    });
  } catch {
    displayAlert({ text: t("hangarPlanner.messages.saveFailed") });
  } finally {
    submitting.value = false;
  }
};
</script>

<template>
  <PickerModal
    :title="t('hangarPlanner.decisions.upgradeTo', { name: vehicleName })"
    :submit-label="t('hangarPlanner.decisions.upgrade')"
    :submitting="submitting"
    single
    @submit="submit"
  />
</template>
