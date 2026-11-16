<script lang="ts">
export default {
  name: "HangarPlannerUpgradeFits",
};
</script>

<script lang="ts" setup>
import Alert from "@/shared/components/base/Alert/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import { usePlanMoney } from "@/frontend/components/Hangar/Planner/format";
import {
  type UpgradeFit,
  findUpgradeFits,
} from "@/frontend/components/Hangar/Planner/UpgradeFits/fits";
import { useI18n } from "@/shared/composables/useI18n";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { useHangarPlanCache } from "@/frontend/composables/useHangarPlanCache";
import {
  type HangarPlan,
  useHangarPlanResources,
  useUpdateHangarPlanAcquisition,
} from "@/services/fyApi";

type Props = {
  plan: HangarPlan;
};

const props = defineProps<Props>();

const { t } = useI18n();
const { money } = usePlanMoney();
const { displayAlert, displaySuccess } = useAppNotifications();
const { updatePlan } = useHangarPlanCache();

const { data: resources } = useHangarPlanResources(() => props.plan.id);

const fits = computed(() =>
  resources.value ? findUpgradeFits(props.plan, resources.value) : [],
);

const update = useUpdateHangarPlanAcquisition();
const applying = ref<string>();

const apply = async (fit: UpgradeFit) => {
  applying.value = fit.upgradeId;

  try {
    updatePlan(
      await update.mutateAsync({
        hangarPlanId: props.plan.id,
        id: fit.acquisition.id,
        data: { steps: fit.steps },
      }),
    );
    displaySuccess({
      text: t("hangarPlanner.upgradeFits.applied", {
        ship: fit.candidate.model.name,
      }),
    });
  } catch {
    displayAlert({ text: t("hangarPlanner.messages.saveFailed") });
  } finally {
    applying.value = undefined;
  }
};
</script>

<template>
  <Alert
    v-if="fits.length"
    variant="info"
    :title="t('hangarPlanner.upgradeFits.title')"
    data-test="hangar-plan-upgrade-fits"
  >
    <ul class="upgrade-fits">
      <li
        v-for="fit in fits"
        :key="fit.upgradeId"
        class="upgrade-fits__item"
        data-test="hangar-plan-upgrade-fit"
      >
        <span>
          {{
            t("hangarPlanner.upgradeFits.fit", {
              upgrade: `${fit.from.name} → ${fit.to.name}`,
              ship: fit.candidate.model.name,
            })
          }}
          ·
          <strong>
            {{
              t("hangarPlanner.upgradeFits.saves", {
                amount: money(fit.saving),
              })
            }}
          </strong>
        </span>
        <Btn
          :size="BtnSizesEnum.SM"
          :loading="applying === fit.upgradeId"
          :disabled="!!applying"
          data-test="hangar-plan-upgrade-fit-apply"
          @click="apply(fit)"
        >
          <i class="fa-light fa-route" />
          {{ t("hangarPlanner.upgradeFits.apply") }}
        </Btn>
      </li>
    </ul>
  </Alert>
</template>

<style lang="scss" scoped>
.upgrade-fits {
  display: flex;
  flex-direction: column;
  gap: 8px;
  margin: 0;
  padding: 0;
  list-style: none;
}

.upgrade-fits__item {
  display: flex;
  flex-wrap: wrap;
  gap: 8px 12px;
  align-items: center;
  justify-content: space-between;
}
</style>
