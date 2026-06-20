<script lang="ts">
export default {
  name: "SupporterContributionActionItems",
};
</script>

<script lang="ts" setup>
import {
  type SupporterContribution,
  useDestroySupporterContribution,
  getSupporterContributionsQueryKey,
} from "@/services/fyAdminApi";
import {
  BtnSizesEnum,
  BtnVariantsEnum,
} from "@/shared/components/base/Btn/types";
import { useI18n } from "@/shared/composables/useI18n";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { useQueryClient } from "@tanstack/vue-query";

type Props = {
  supporterContribution: SupporterContribution;
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
    queryKey: getSupporterContributionsQueryKey(),
  });

const destroyMutation = useDestroySupporterContribution({
  mutation: {
    onSettled: invalidate,
  },
});

const destroy = () => {
  if (!props.supporterContribution.id) return;

  displayConfirm({
    text: t("messages.confirm.supporterContribution.destroy"),
    onConfirm: async () => {
      await destroyMutation.mutateAsync({
        id: props.supporterContribution.id!,
      });
      displaySuccess({
        text: t("messages.supporterContribution.destroyed"),
      });
    },
  });
};
</script>

<template>
  <Btn
    v-tooltip="!withLabels && t('actions.edit')"
    :size="BtnSizesEnum.SMALL"
    :to="{
      name: 'admin-supporter-contribution-edit',
      params: { id: props.supporterContribution.id },
    }"
  >
    <i class="fa-duotone fa-pen-to-square" />
    <span v-if="withLabels">{{ t("actions.edit") }}</span>
  </Btn>
  <Btn
    v-tooltip="!withLabels && t('actions.delete')"
    :size="BtnSizesEnum.SMALL"
    :variant="BtnVariantsEnum.DANGER"
    @click="destroy"
  >
    <i class="fa-duotone fa-trash" />
    <span v-if="withLabels">{{ t("actions.delete") }}</span>
  </Btn>
</template>
