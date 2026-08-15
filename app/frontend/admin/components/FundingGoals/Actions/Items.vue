<script lang="ts">
export default {
  name: "FundingGoalActionItems",
};
</script>

<script lang="ts" setup>
import {
  type FundingGoal,
  useDestroyFundingGoal,
  getFundingGoalsQueryKey,
} from "@/services/fyAdminApi";
import { BtnTonesEnum } from "@/shared/components/base/Btn/types";
import { useI18n } from "@/shared/composables/useI18n";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { useQueryClient } from "@tanstack/vue-query";

type Props = {
  fundingGoal: FundingGoal;
  withLabels?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  withLabels: false,
});

const { t } = useI18n();
const { displayConfirm, displaySuccess } = useAppNotifications();
const queryClient = useQueryClient();

const invalidate = () =>
  queryClient.invalidateQueries({
    queryKey: getFundingGoalsQueryKey(),
  });

const destroyMutation = useDestroyFundingGoal({
  mutation: {
    onSettled: invalidate,
  },
});

const destroy = () => {
  if (!props.fundingGoal.id) return;

  displayConfirm({
    text: t("messages.confirm.fundingGoal.destroy"),
    onConfirm: async () => {
      await destroyMutation.mutateAsync({ id: props.fundingGoal.id! });
      displaySuccess({
        text: t("messages.fundingGoal.destroyed"),
      });
    },
  });
};
</script>

<template>
  <Btn
    v-tooltip="!withLabels && t('actions.edit')"
    :to="{
      name: 'admin-funding-goal-edit',
      params: { id: props.fundingGoal.id },
    }"
  >
    <i class="fa-duotone fa-pen-to-square" />
    <span v-if="withLabels">{{ t("actions.edit") }}</span>
  </Btn>
  <Btn
    v-tooltip="!withLabels && t('actions.delete')"
    @click="destroy"
    :tone="BtnTonesEnum.DANGER"
  >
    <i class="fa-duotone fa-trash" />
    <span v-if="withLabels">{{ t("actions.delete") }}</span>
  </Btn>
</template>
