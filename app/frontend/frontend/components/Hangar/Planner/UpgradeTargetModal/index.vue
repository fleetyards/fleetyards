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
import {
  type HangarPlanAcquisition,
  type HangarPlanModel,
  type ModelQuery,
  useHangarPlan,
} from "@/services/fyApi";

type Props = {
  planId: string;
  startName: string;
  startModel?: HangarPlanModel;
  vehicleId?: string;
  acquisition?: HangarPlanAcquisition;
};

const props = withDefaults(defineProps<Props>(), {
  startModel: undefined,
  vehicleId: undefined,
  acquisition: undefined,
});

const { t } = useI18n();
const comlink = useComlink();

const { data: plan } = useHangarPlan(() => props.planId);
const { pairing, pairEnd } = useHangarPlanPairing(() => props.planId, plan);

// Reached by upgrading, so only the ships RSI sells upgrades into, and only
// dearer than the start, since an upgrade never leads to a cheaper ship.
const query = computed<ModelQuery>(() => {
  const price = props.startModel?.pledgePrice;

  return {
    ccuTarget: true,
    ...(typeof price === "number" ? { pledgePriceGt: price } : {}),
  };
});

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
    :query="query"
    single
    @submit="submit"
  />
</template>
