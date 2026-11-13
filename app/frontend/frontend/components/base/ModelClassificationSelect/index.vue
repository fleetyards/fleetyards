<script lang="ts">
export default {
  name: "ModelClassificationSelect",
};
</script>

<script lang="ts" setup>
import { useI18n } from "@/shared/composables/useI18n";
import BaseSelect, {
  type BaseSelectParams,
} from "@/shared/components/base/Select/index.vue";
import {
  modelClassificationsFilters as fetchModelClassifications,
  type FilterOption,
} from "@/services/fyApi";

type Props = {
  name: string;
  searchable?: boolean;
  multiple?: boolean;
  noLabel?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  searchable: true,
  multiple: true,
  noLabel: true,
});

const { t } = useI18n();

const internalValue = defineModel<string | string[] | undefined>();

const fetch = async (params: BaseSelectParams<FilterOption>) => {
  const response = await fetchModelClassifications();

  if (params.search && props.searchable) {
    return response.filter((item) => {
      const value = `${item.value}`.toLowerCase();
      return (
        item.label
          ?.toLowerCase()
          .includes(params.search?.toLowerCase() || "") ||
        value.includes(params.search?.toLowerCase() || "")
      );
    });
  }

  return response;
};
</script>

<template>
  <BaseSelect
    v-model="internalValue"
    :label="t('labels.filters.models.classification')"
    :query-fn="fetch"
    :name="name"
    :searchable="searchable"
    :multiple="multiple"
    :no-label="noLabel"
  />
</template>
