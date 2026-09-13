<script lang="ts">
export default {
  name: "TransferFilterForm",
};
</script>

<script lang="ts" setup>
import BaseSelect from "@/shared/components/base/Select/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useTransferFilters } from "@/frontend/composables/useTransferFilters";
import type { FilterOption, InventoryTransferQuery } from "@/services/fyApi";

type Props = {
  updateCallback?: () => Promise<void>;
};

const props = withDefaults(defineProps<Props>(), { updateCallback: undefined });

const { t } = useI18n();
const route = useRoute();

const { filter, resetFilter, isFilterSelected } = useTransferFilters(
  props.updateCallback,
);

const STATES = ["pending", "completed", "declined", "cancelled", "expired"];

const stateOptions = computed<FilterOption[]>(() =>
  STATES.map((value) => ({
    value,
    label: t(`labels.logistics.transferStates.${value}`),
  })),
);

const form = ref<InventoryTransferQuery>({
  stateEq:
    (route.query.stateEq as InventoryTransferQuery["stateEq"]) || undefined,
});

watch(
  () => form.value,
  () => filter(form.value),
  { deep: true },
);

defineExpose({ isFilterSelected, resetFilter });
</script>

<template>
  <form @submit.prevent="filter(form)">
    <BaseSelect
      v-model="form.stateEq"
      name="state"
      :options="stateOptions"
      :searchable="false"
      :nullable="true"
      :label="t('labels.logistics.state')"
      data-test="transfer-filter-state"
    />
  </form>
</template>
