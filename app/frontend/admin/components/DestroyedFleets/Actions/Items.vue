<script lang="ts">
export default {
  name: "DestroyedFleetActionItems",
};
</script>

<script lang="ts" setup>
import {
  type DestroyedFleet,
  useRestoreDestroyedFleet,
  getDestroyedFleetsQueryKey,
} from "@/services/fyAdminApi";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import { useI18n } from "@/shared/composables/useI18n";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { useQueryClient } from "@tanstack/vue-query";

type Props = {
  destroyedFleet: DestroyedFleet;
  withLabels?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  withLabels: false,
});

const { t } = useI18n();
const { displayConfirm } = useAppNotifications();
const queryClient = useQueryClient();

const invalidateDestroyedFleets = () =>
  queryClient.invalidateQueries({
    queryKey: getDestroyedFleetsQueryKey(),
  });

const restoreMutation = useRestoreDestroyedFleet({
  mutation: {
    onSettled: invalidateDestroyedFleets,
  },
});

const isPurged = computed(() => props.destroyedFleet.source === "purged");

const restore = () => {
  if (!props.destroyedFleet.id) return;

  displayConfirm({
    text: isPurged.value
      ? t("messages.confirm.adminDestroyedFleet.restorePurged")
      : t("messages.confirm.adminDestroyedFleet.restore"),
    onConfirm: async () => {
      await restoreMutation.mutateAsync({
        id: props.destroyedFleet.id,
        params: { source: props.destroyedFleet.source },
      });
    },
  });
};
</script>

<template>
  <Btn
    v-tooltip="!withLabels && t('actions.restore')"
    :size="BtnSizesEnum.SMALL"
    :disabled="!destroyedFleet.restorable"
    @click="restore"
  >
    <i class="fa-duotone fa-trash-can-arrow-up" />
    <span v-if="withLabels">{{ t("actions.restore") }}</span>
  </Btn>
</template>
