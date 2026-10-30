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
import { useHangarPlanPairing } from "@/frontend/composables/useHangarPlanPairing";
import { type HangarPlanAcquisition, useHangarPlan } from "@/services/fyApi";

type Props = {
  planId: string;
  startName: string;
  vehicleId?: string;
  acquisition?: HangarPlanAcquisition;
};

const props = withDefaults(defineProps<Props>(), {
  vehicleId: undefined,
  acquisition: undefined,
});

const { t } = useI18n();
const comlink = useComlink();

const { data: plan } = useHangarPlan(() => props.planId);
const { pairing, pairEnd } = useHangarPlanPairing(() => props.planId, plan);

// The ship gets a slot of its own, and the route ends there; the upgrades in
// between are planned from the row.
const submit = async ([selection]: ModelPickerSelection[]) => {
  if (!selection) return;

  const paired = await pairEnd(
    {
      kind: "model",
      modelId: selection.option.id,
      name: selection.option.name,
    },
    { vehicleId: props.vehicleId, acquisition: props.acquisition },
  );
  if (paired) comlink.emit("close-modal", true);
};
</script>

<template>
  <PickerModal
    :title="t('hangarPlanner.decisions.upgradeTo', { name: startName })"
    :submit-label="t('hangarPlanner.pick.use')"
    :submitting="pairing"
    single
    @submit="submit"
  />
</template>
