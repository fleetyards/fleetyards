<script lang="ts">
export default {
  name: "ProductionStatusSelect",
};
</script>

<script lang="ts" setup>
import { useI18n } from "@/shared/composables/useI18n";
import BaseSelect, {
  type BaseSelectParams,
} from "@/shared/components/base/Select/index.vue";
import {
  modelProductionStatesFilters as fetchModelProductionStatesFilters,
  type FilterOption,
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

const fetch = async (_params: BaseSelectParams<FilterOption>) => {
  return fetchModelProductionStatesFilters();
};
</script>

<template>
  <BaseSelect
    v-model="internalValue"
    :label="t('labels.filters.models.productionStatus')"
    :query-fn="fetch"
    :name="name"
    :multiple="multiple"
    :no-label="noLabel"
  />
</template>
