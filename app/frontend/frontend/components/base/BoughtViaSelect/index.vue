<script lang="ts">
export default {
  name: "BoughtViaSelect",
};
</script>

<script lang="ts" setup>
import { useI18n } from "@/shared/composables/useI18n";
import BaseSelect, {
  type BaseSelectParams,
} from "@/shared/components/base/Select/index.vue";
import {
  vehicleBoughtViaFilters as fetchBoughtViaFilters,
  FilterOption,
} from "@/services/fyApi";

type Props = {
  name: string;
  multiple?: boolean;
  noLabel?: boolean;
};

withDefaults(defineProps<Props>(), {
  multiple: true,
  noLabel: true,
});

const { t } = useI18n();

const internalValue = defineModel<string | string[] | undefined>();

const fetch = (_params: BaseSelectParams<FilterOption>) => {
  return fetchBoughtViaFilters();
};
</script>

<template>
  <BaseSelect
    v-model="internalValue"
    :label="t('labels.filters.vehicles.boughtVia')"
    :query-fn="fetch"
    :name="name"
    :paginated="false"
    :searchable="false"
    :multiple="multiple"
    :no-label="noLabel"
  />
</template>
