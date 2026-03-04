<script lang="ts">
export default {
  name: "ManufacturerActionItems",
};
</script>

<script lang="ts" setup>
import {
  type Manufacturer,
  useDestroyManufacturer,
  getManufacturersQueryKey,
} from "@/services/fyAdminApi";
import {
  BtnSizesEnum,
  BtnVariantsEnum,
} from "@/shared/components/base/Btn/types";
import { useI18n } from "@/shared/composables/useI18n";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { useQueryClient } from "@tanstack/vue-query";

type Props = {
  manufacturer: Manufacturer;
  withLabels?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  withLabels: false,
});

const { t } = useI18n();
const { displayConfirm } = useAppNotifications();
const queryClient = useQueryClient();

const invalidateManufacturers = async () => {
  await queryClient.invalidateQueries({
    queryKey: getManufacturersQueryKey(),
  });
};

const destroyMutation = useDestroyManufacturer({
  mutation: {
    onSettled: invalidateManufacturers,
  },
});

const destroy = () => {
  if (!props.manufacturer.id) return;

  displayConfirm({
    text: t("messages.confirm.manufacturer.destroy"),
    onConfirm: async () => {
      await destroyMutation.mutateAsync({ id: props.manufacturer.id! });
    },
  });
};
</script>

<template>
  <Btn
    v-tooltip="!withLabels && t('actions.edit')"
    :size="BtnSizesEnum.SMALL"
    :to="{
      name: 'admin-manufacturer-edit',
      params: { id: props.manufacturer.id },
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
