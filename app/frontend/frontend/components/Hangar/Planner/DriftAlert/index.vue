<script lang="ts">
export default {
  name: "HangarPlannerDriftAlert",
};
</script>

<script lang="ts" setup>
import Alert from "@/shared/components/base/Alert/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import { usePlanMoney } from "@/frontend/components/Hangar/Planner/format";
import { useI18n } from "@/shared/composables/useI18n";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { useHangarPlanCache } from "@/frontend/composables/useHangarPlanCache";
import { type HangarPlanDrift, useRebaseHangarPlan } from "@/services/fyApi";

type Props = {
  planId: string;
  drift: HangarPlanDrift;
  readonly?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  readonly: false,
});

const { t } = useI18n();
const { amount } = usePlanMoney();
const { displayAlert, displaySuccess } = useAppNotifications();
const { updatePlan } = useHangarPlanCache();

const rebase = useRebaseHangarPlan();

const priceChanged = computed(
  () => props.drift.previousTotal !== props.drift.currentTotal,
);

const onRebase = async () => {
  try {
    updatePlan(await rebase.mutateAsync({ id: props.planId }));
    displaySuccess({ text: t("hangarPlanner.messages.rebased") });
  } catch {
    displayAlert({ text: t("hangarPlanner.messages.saveFailed") });
  }
};
</script>

<template>
  <Alert
    variant="warning"
    :title="t('hangarPlanner.drift.title')"
    data-test="hangar-plan-drift"
  >
    <ul class="plan-drift">
      <li v-if="drift.missingSources.length">
        {{
          t("hangarPlanner.drift.missing", {
            count: drift.missingSources.length,
          })
        }}
      </li>
      <li v-if="drift.changedSources.length">
        {{
          t("hangarPlanner.drift.changed", {
            count: drift.changedSources.length,
          })
        }}
      </li>
      <li v-if="drift.newVehicles.length">
        {{
          t("hangarPlanner.drift.added", {
            ships: drift.newVehicles
              .map((vehicle) => vehicle.name || vehicle.model.name)
              .join(", "),
          })
        }}
      </li>
      <li v-if="priceChanged">
        {{
          t("hangarPlanner.drift.prices", {
            before: amount(drift.previousTotal),
            now: amount(drift.currentTotal),
          })
        }}
      </li>
    </ul>
    <Btn
      v-if="!readonly"
      :size="BtnSizesEnum.SM"
      :loading="rebase.isPending.value"
      data-test="hangar-plan-rebase"
      @click="onRebase"
    >
      <i class="fa-light fa-arrows-rotate" />
      {{ t("hangarPlanner.drift.rebase") }}
    </Btn>
  </Alert>
</template>

<style lang="scss" scoped>
.plan-drift {
  margin: 0 0 8px;
  padding-left: 16px;
}
</style>
