<script lang="ts">
export default {
  name: "ModelDockSizeSelect",
};
</script>

<script lang="ts" setup>
import { modelDockSizesFilters as fetchModelDockSizeFilters } from "@/services/fyApi";
import { type FilterOption } from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";
import BaseSelect, {
  type BaseSelectParams,
} from "@/shared/components/base/Select/index.vue";

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
  return fetchModelDockSizeFilters();
};
</script>

<template>
  <BaseSelect
    v-model="internalValue"
    :label="t('labels.filters.models.dockSize')"
    :query-fn="fetch"
    :name="name"
    :multiple="multiple"
    :no-label="noLabel"
  />
</template>
