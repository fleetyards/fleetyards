<script lang="ts">
export default {
  name: "ComponentActionItems",
};
</script>

<script lang="ts" setup>
import {
  type Component,
  useDestroyComponent,
  getComponentsQueryKey,
} from "@/services/fyAdminApi";
import {
  BtnSizesEnum,
  BtnVariantsEnum,
} from "@/shared/components/base/Btn/types";
import { useI18n } from "@/shared/composables/useI18n";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { useQueryClient } from "@tanstack/vue-query";

type Props = {
  component: Component;
  withLabels?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  withLabels: false,
});

const { t } = useI18n();
const { displayConfirm } = useAppNotifications();
const queryClient = useQueryClient();

const invalidateComponents = async () => {
  await queryClient.invalidateQueries({
    queryKey: getComponentsQueryKey(),
  });
};

const destroyMutation = useDestroyComponent({
  mutation: {
    onSettled: invalidateComponents,
  },
});

const destroy = () => {
  if (!props.component.id) return;

  displayConfirm({
    text: t("messages.confirm.component.destroy"),
    onConfirm: async () => {
      await destroyMutation.mutateAsync({ id: props.component.id! });
    },
  });
};
</script>

<template>
  <Btn
    v-tooltip="!withLabels && t('actions.edit')"
    :size="BtnSizesEnum.SMALL"
    :to="{
      name: 'admin-component-edit',
      params: { id: props.component.id },
    }"
  >
    <i class="fad fa-pen-to-square" />
    <span v-if="withLabels">{{ t("actions.edit") }}</span>
  </Btn>
  <Btn
    v-tooltip="!withLabels && t('actions.delete')"
    :size="BtnSizesEnum.SMALL"
    :variant="BtnVariantsEnum.DANGER"
    @click="destroy"
  >
    <i class="fad fa-trash" />
    <span v-if="withLabels">{{ t("actions.delete") }}</span>
  </Btn>
</template>
